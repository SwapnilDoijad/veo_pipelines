#!/usr/bin/env bash
# Utility functions used across scripts

number_of_sequences_in_fasta() {
	# Count number of sequences (headers starting with '>') in FASTA.
	# Usage: number_of_sequences_in_fasta file.fa[.gz]
	#        cat file.fa | number_of_sequences_in_fasta
	local infile
	if [ $# -ge 1 ] && [ -n "$1" ]; then
		infile="$1"
		if [[ "$infile" == *.gz ]]; then
			gzip -dc -- "$infile" 2>/dev/null | awk '/^>/{c++} END{print c+0}'
		else
			awk '/^>/{c++} END{print c+0}' "$infile"
		fi
	else
		awk '/^>/{c++} END{print c+0}' -
	fi
}

total_nt_of_the_fasta() {
	# Count total nucleotides (letters) in a FASTA/multi-FASTA file.
	# Usage: total_nt_of_the_fasta file.fa[.gz]
	#        cat file.fa | total_nt_of_the_fasta
	local infile
	if [ $# -ge 1 ] && [ -n "$1" ]; then
		infile="$1"
		if [[ "$infile" == *.gz ]]; then
			gzip -dc -- "$infile" 2>/dev/null | awk '/^>/{next} {gsub(/[^A-Za-z]/,""); s+=length($0)} END{print s+0}'
		else
			awk '/^>/{next} {gsub(/[^A-Za-z]/,""); s+=length($0)} END{print s+0}' "$infile"
		fi
	else
		awk '/^>/{next} {gsub(/[^A-Za-z]/,""); s+=length($0)} END{print s+0}' -
	fi
}


nt_in_fasta() {
	# Report per-sequence nucleotide counts with header.
	# Usage: nt_in_fasta file.fa[.gz]
	#        cat file.fa | nt_in_fasta
	local infile
	if [ $# -ge 1 ] && [ -n "$1" ]; then
		infile="$1"
		if [[ "$infile" == *.gz ]]; then
			gzip -dc -- "$infile" 2>/dev/null | awk 'BEGIN{hdr="";s=0} /^>/{ if(hdr!=""){print hdr"\t"s} hdr=substr($0,2); s=0; next} {gsub(/[^A-Za-z]/,""); s+=length($0)} END{ if(hdr!="") print hdr"\t"s }'
		else
			awk 'BEGIN{hdr="";s=0} /^>/{ if(hdr!=""){print hdr"\t"s} hdr=substr($0,2); s=0; next} {gsub(/[^A-Za-z]/,""); s+=length($0)} END{ if(hdr!="") print hdr"\t"s }' "$infile"
		fi
	else
		awk 'BEGIN{hdr="";s=0} /^>/{ if(hdr!=""){print hdr"\t"s} hdr=substr($0,2); s=0; next} {gsub(/[^A-Za-z]/,""); s+=length($0)} END{ if(hdr!="") print hdr"\t"s }' -
	fi
}


get_GC_count() {
	# Count G and C nucleotides in FASTA or FASTQ (plain or gzipped).
	# Usage: get_GC_count file.[fa|fasta|fq|fastq][.gz]
	#        cat file | get_GC_count
	local infile head_line format tmp

	# Helper to compute GC% from stdin (reads sequence lines only)
	_gc_percent_stream() { awk 'BEGIN{A=T=G=C=0} {A+=gsub(/[Aa]/,"{}"); T+=gsub(/[Tt]/,"{}"); G+=gsub(/[Gg]/,"{}"); C+=gsub(/[Cc]/,"{}")} END{tot=A+T+G+C; if(tot==0) print "0.00"; else printf("%.2f\n", (G+C)/tot*100)}' ; }

	if [ $# -ge 1 ] && [ -n "$1" ]; then
		infile="$1"
		if [[ "$infile" == *.gz ]]; then
			head_line=$(gzip -dc -- "$infile" 2>/dev/null | awk 'NF{print; exit}') || head_line=""
			if [[ "$head_line" == @* ]]; then
				format=fastq
			elif [[ "$head_line" == '>'* ]]; then
				format=fasta
			else
				format=fasta
			fi

			if [[ "$format" == fastq ]]; then
				gzip -dc -- "$infile" 2>/dev/null | awk 'NR%4==2' | _gc_percent_stream
			else
				gzip -dc -- "$infile" 2>/dev/null | grep -v '^>' | _gc_percent_stream
			fi
		else
			head_line=$(awk 'NF{print; exit}' "$infile" 2>/dev/null) || head_line=""
			if [[ "$head_line" == @* ]]; then
				format=fastq
			elif [[ "$head_line" == '>'* ]]; then
				format=fasta
			else
				format=fasta
			fi

			if [[ "$format" == fastq ]]; then
				awk 'NR%4==2' "$infile" | _gc_percent_stream
			else
				grep -v '^>' "$infile" | _gc_percent_stream
			fi
		fi
	else
		# Read stdin to temp file to detect format reliably
		tmp=$(mktemp) || return 1
		cat - > "$tmp"
		head_line=$(awk 'NF{print; exit}' "$tmp" 2>/dev/null) || head_line=""
		if [[ "$head_line" == @* ]]; then
			awk 'NR%4==2' "$tmp" | _gc_percent_stream
		else
			grep -v '^>' "$tmp" | _gc_percent_stream
		fi
		rm -f "$tmp"
	fi
}


