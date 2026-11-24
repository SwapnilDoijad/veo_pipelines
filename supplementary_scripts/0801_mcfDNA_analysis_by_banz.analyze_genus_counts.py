#!/usr/bin/env python3
"""
Analyze genus counts from a species summary TSV file.
Groups species by genus and sums their counts.

Usage:
    python3 analyze_genus_counts.py -s species.tsv -g genus.tsv -k bracken.bracken -o output.tsv --detailed --top-only
"""

import argparse
from collections import defaultdict


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Analyze genus counts from species summary TSV file"
    )
    parser.add_argument(
        "-s", "--species",
        required=True,
        help="Species-level TSV file with columns: sample, genus_species, count (header optional)"
    )
    parser.add_argument(
        "-g", "--genus",
        help="Genus-level summary TSV file (optional, with columns: sample, genus, count; header optional)"
    )
    parser.add_argument(
        "-k", "--kraken",
        help="Bracken output file (optional, with kraken_assigned_reads column)"
    )
    parser.add_argument(
        "-o", "--output",
        required=True,
        help="Output TSV file with genus-level aggregated counts"
    )
    parser.add_argument(
        "--detailed",
        action="store_true",
        help="Include species-level details in output (Genus, Species, Count)"
    )
    parser.add_argument(
        "--top-only",
        action="store_true",
        help="Show only the top species for each genus (requires --detailed)"
    )
    return parser.parse_args()


def read_summary(input_file, taxon_column):
    with open(input_file, 'r') as f:
        for line_number, line in enumerate(f, 1):
            parts = line.strip().split('\t')
            if line_number == 1 and parts[:3] == [
                'Sample', taxon_column, 'Primary_mapped_reads'
            ]:
                continue
            if len(parts) >= 3:
                yield parts[1], int(parts[2])


def aggregate_by_genus(input_file, genus_file=None, kraken_file=None):
    """
    Read TSV file and aggregate counts by genus.
    
    Args:
        input_file: Path to input TSV file (species level)
        genus_file: Path to genus-level summary file (optional)
        kraken_file: Path to Bracken output file (optional)
    
    Returns:
        Tuple of (genus_counts, genus_species_data, genus_level_counts, kraken_assigned_reads)
        Returns None for missing/empty optional files
    """
    genus_counts = defaultdict(int)
    genus_species_data = defaultdict(list)
    genus_level_counts = None
    kraken_assigned_reads = None
    
    for genus_species, count in read_summary(input_file, 'Species'):
        genus = genus_species.split('_')[0]  # Extract genus
        genus_counts[genus] += count
        genus_species_data[genus].append((genus_species, count))
    
    # Read genus-level counts if provided
    if genus_file:
        try:
            temp_genus_counts = {}
            for genus, count in read_summary(genus_file, 'Genus'):
                temp_genus_counts[genus] = count
            if temp_genus_counts:
                genus_level_counts = temp_genus_counts
        except (FileNotFoundError, IOError):
            pass  # File not found, skip
    
    # Read Bracken file if provided
    if kraken_file:
        try:
            temp_kraken_reads = {}
            with open(kraken_file, 'r') as f:
                header = f.readline().strip().split('\t')
                kraken_idx = header.index('kraken_assigned_reads') if 'kraken_assigned_reads' in header else -1
                name_idx = header.index('name') if 'name' in header else 0
                
                for line in f:
                    parts = line.strip().split('\t')
                    if len(parts) > max(kraken_idx, name_idx) and kraken_idx != -1:
                        genus = parts[name_idx]
                        kraken_count = int(parts[kraken_idx])
                        temp_kraken_reads[genus] = kraken_count
            if temp_kraken_reads:
                kraken_assigned_reads = temp_kraken_reads
        except (FileNotFoundError, IOError):
            pass  # File not found, skip
    
    return genus_counts, genus_species_data, genus_level_counts, kraken_assigned_reads


def write_output(output_file, genus_counts, genus_species_data, genus_level_counts=None, kraken_assigned_reads=None, detailed=False, top_only=False):
    """
    Write results to TSV file.
    
    Args:
        output_file: Path to output TSV file
        genus_counts: Dictionary of genus to total count (from species)
        genus_species_data: Dictionary of genus to list of species and counts
        genus_level_counts: Dictionary of genus to count from genus-level file (optional)
        kraken_assigned_reads: Dictionary of genus to kraken_assigned_reads (optional)
        detailed: If True, include detailed breakdown; if False, only genus summary
        top_only: If True, show only top species for each genus
    """
    with open(output_file, 'w') as f:
        if detailed:
            # Build header based on what data is available
            if kraken_assigned_reads and genus_level_counts:
                header = "Genus\tKraken_Assigned_Reads\treads_mapped_to_genus\tSpecies\treads_mapped_to_species\n"
            elif kraken_assigned_reads:
                header = "Genus\tKraken_Assigned_Reads\tSpecies\treads_mapped_to_species\n"
            elif genus_level_counts:
                header = "Genus\treads_mapped_to_genus\tSpecies\treads_mapped_to_species\n"
            else:
                header = "Genus\tSpecies\treads_mapped_to_species\n"
            
            f.write(header)
            
            for genus in sorted(genus_counts.keys()):
                genus_count = genus_level_counts.get(genus) if genus_level_counts else None
                kraken_count = kraken_assigned_reads.get(genus) if kraken_assigned_reads else None
                
                if top_only:
                    top_species = max(genus_species_data[genus], key=lambda x: x[1])
                    if kraken_assigned_reads is not None and genus_level_counts is not None:
                        # Both files provided
                        kraken_val = kraken_count if kraken_count is not None else "NA"
                        genus_val = genus_count if genus_count is not None else "NA"
                        f.write(f"{genus}\t{kraken_val}\t{genus_val}\t{top_species[0]}\t{top_species[1]}\n")
                    elif kraken_assigned_reads is not None:
                        # Only kraken file provided
                        kraken_val = kraken_count if kraken_count is not None else "NA"
                        f.write(f"{genus}\t{kraken_val}\t{top_species[0]}\t{top_species[1]}\n")
                    elif genus_level_counts is not None:
                        # Only genus file provided
                        genus_val = genus_count if genus_count is not None else "NA"
                        f.write(f"{genus}\t{genus_val}\t{top_species[0]}\t{top_species[1]}\n")
                    else:
                        # No optional files provided
                        f.write(f"{genus}\t{top_species[0]}\t{top_species[1]}\n")
                else:
                    for species, count in sorted(genus_species_data[genus], key=lambda x: x[1], reverse=True):
                        if kraken_assigned_reads is not None and genus_level_counts is not None:
                            # Both files provided
                            kraken_val = kraken_count if kraken_count is not None else "NA"
                            genus_val = genus_count if genus_count is not None else "NA"
                            f.write(f"{genus}\t{kraken_val}\t{genus_val}\t{species}\t{count}\n")
                        elif kraken_assigned_reads is not None:
                            # Only kraken file provided
                            kraken_val = kraken_count if kraken_count is not None else "NA"
                            f.write(f"{genus}\t{kraken_val}\t{species}\t{count}\n")
                        elif genus_level_counts is not None:
                            # Only genus file provided
                            genus_val = genus_count if genus_count is not None else "NA"
                            f.write(f"{genus}\t{genus_val}\t{species}\t{count}\n")
                        else:
                            # No optional files provided
                            f.write(f"{genus}\t{species}\t{count}\n")
        else:
            # Summary format
            if kraken_assigned_reads is not None and genus_level_counts is not None:
                f.write("Genus\tKraken_Assigned_Reads\treads_mapped_to_genus\n")
            elif kraken_assigned_reads is not None:
                f.write("Genus\tKraken_Assigned_Reads\n")
            elif genus_level_counts is not None:
                f.write("Genus\treads_mapped_to_genus\n")
            else:
                f.write("Genus\treads_mapped_to_genus\n")
            
            for genus in sorted(genus_counts.keys()):
                genus_count = genus_level_counts.get(genus) if genus_level_counts else None
                kraken_count = kraken_assigned_reads.get(genus) if kraken_assigned_reads else None
                
                if kraken_assigned_reads is not None and genus_level_counts is not None:
                    kraken_val = kraken_count if kraken_count is not None else "NA"
                    genus_val = genus_count if genus_count is not None else "NA"
                    f.write(f"{genus}\t{kraken_val}\t{genus_val}\n")
                elif kraken_assigned_reads is not None:
                    kraken_val = kraken_count if kraken_count is not None else "NA"
                    f.write(f"{genus}\t{kraken_val}\n")
                elif genus_level_counts is not None:
                    genus_val = genus_count if genus_count is not None else "NA"
                    f.write(f"{genus}\t{genus_val}\n")
                else:
                    f.write(f"{genus}\tNA\n")


def main():
    args = parse_arguments()
    
    # Aggregate counts by genus
    genus_counts, genus_species_data, genus_level_counts, kraken_assigned_reads = aggregate_by_genus(
        args.species, args.genus, args.kraken
    )
    
    # Write output
    write_output(args.output, genus_counts, genus_species_data, 
                 genus_level_counts=genus_level_counts, 
                 kraken_assigned_reads=kraken_assigned_reads,
                 detailed=args.detailed, top_only=args.top_only)
    
    # Print summary to console
    print(f"✓ Analysis complete!")
    print(f"  Species file: {args.species}")
    if args.genus:
        print(f"  Genus file: {args.genus}")
    if args.kraken:
        print(f"  Kraken file: {args.kraken}")
    print(f"  Output file: {args.output}")
    if args.top_only:
        print(f"  Output format: Top species per genus")
    elif args.detailed:
        print(f"  Output format: Detailed (Genus, Species, Count)")
    else:
        print(f"  Output format: Summary (Genus, Total_Count)")
    print(f"  Total genera found: {len(genus_counts)}")
    print(f"\nGenus Summary (sorted by count):")
    for genus, count in sorted(genus_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"  {genus:20s} : {count:6d}")


if __name__ == "__main__":
    main()
