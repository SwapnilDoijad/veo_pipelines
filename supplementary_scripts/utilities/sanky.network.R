
# source /vast/groups/VEO/tools/anaconda3/etc/profile.d/conda.sh && conda activate R_v4.4.2

# source	target	value
# by_nanopore_machine	basecalled_by_guppy_(100%)	1996714
# basecalled_by_guppy_(100%)	failed_(20%)	396458
# basecalled_by_guppy_(100%)	passed_(80%)	1600256
# passed_(80%)	not_binned_(4%)	87169
# passed_(80%)	binned_(76%)	1513087
# binned_(76%)	QC10_(30%)	595876
# binned_(76%)	QC<10_(46%)	917211
# QC10_(30%)	to_assembly_(30%)	595876


Sys.setenv(CHROMOTE_CHROME = "/home/xa73pav/chromium/opt/google/chrome/google-chrome")

library(networkD3)
library(readr)
library(optparse)
library(htmlwidgets)
library(webshot2)  # For converting HTML to image formats
library(rsvg)  # To process SVG format

# Define command-line options
option_list <- list(
  make_option(c("-i", "--input"), type = "character", default = NULL,
              help = "Path to input TSV file", metavar = "FILE")
)

# Parse arguments
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check if input file is provided
if (is.null(opt$input)) {
  stop("Error: No input file provided. Use -i your_file.tsv")
}

# Read the TSV file
df <- read_tsv(opt$input, col_names = c("source", "target", "value"))

# Create a list of unique nodes
nodes <- data.frame(name = unique(c(df$source, df$target)))

# Modify node labels: Wrap at "_" and prepare for multi-line SVG text
nodes$display_name <- gsub("_", "\n", nodes$name)  # Replace "_" with newline

# Map source and target names to indices
df$source_id <- match(df$source, nodes$name) - 1
df$target_id <- match(df$target, nodes$name) - 1

# Create the Sankey Diagram
sankey <- sankeyNetwork(Links = df, Nodes = nodes,
                        Source = "source_id", Target = "target_id",
                        Value = "value", NodeID = "display_name",
                        fontSize = 28, nodeWidth = 50,
                        nodePadding = 50,
                        width = 1200, height = 800)  # Increased width

# Custom JavaScript for label adjustment
sankey <- onRender(sankey, "
  function(el) {
    // Hide the 'Source' and 'Target' labels
    d3.select(el).selectAll('text').filter(function() {
      return this.textContent.trim().toLowerCase() === 'source' || this.textContent.trim().toLowerCase() === 'target';
    }).remove();

    // Adjust node text alignment
    d3.select(el).selectAll('.node text')
      .attr('text-anchor', function(d) {
        return d.x > 900 ? 'end' : 'start';
      })
      .each(function(d) {
        var self = d3.select(this),
            text = self.text(),
            words = text.split('\\n');

        self.text(null);
        
        for (var i = 0; i < words.length; i++) {
          self.append('tspan')
            .attr('x', d.x > 900 ? -10 : 60)  // Adjust text positioning
            .attr('dy', i === 0 ? '0em' : '1.2em')
            .text(words[i]);
        }
      });

    // Adjust the SVG width to avoid label clipping
    d3.select(el).select('svg').attr('width', 1400);
  }
")



# Generate output filename based on input
output_html <- paste0(tools::file_path_sans_ext(opt$input), "_sankey.html")

# Save the Sankey plot as an HTML file
saveWidget(sankey, output_html, selfcontained = TRUE)
print(paste("Sankey diagram saved as", output_html))

# Convert HTML to SVG
output_svg <- paste0(tools::file_path_sans_ext(opt$input), "_sankey.svg")

# Capture the SVG from the HTML file
webshot2::webshot(output_html, file = output_svg, selector = "svg")

print(paste("Sankey diagram saved as", output_svg))