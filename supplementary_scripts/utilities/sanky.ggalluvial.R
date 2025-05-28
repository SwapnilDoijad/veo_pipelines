# Load required libraries
	# install.packages("ggplot2", dependencies = TRUE)
	# install.packages("ggalluvial", dependencies = TRUE)
	# install.packages("readr", dependencies = TRUE)
	# install.packages("optparse", dependencies = TRUE)  # Allows command-line arguments

library(ggplot2)
library(ggalluvial)
library(readr)
library(optparse)

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

# Convert 'value' column to numeric (if necessary)
df$value <- as.numeric(df$value)

# Create Sankey diagram using ggalluvial
ggplot(df, aes(axis1 = source, axis2 = target, y = value)) +
  geom_alluvium(aes(fill = source), knot.pos = 0.4) +  # Adjusts spacing
  geom_stratum() +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)), size = 5) + 
  theme_minimal() +
  ggtitle("Sankey Diagram in R") +
  theme(axis.text.x = element_blank())  # Remove axis labels

# Save the plot as a PNG with a filename based on the input
output_file <- paste0(tools::file_path_sans_ext(opt$input), "_sankey.png")
ggsave(output_file, width = 10, height = 7, dpi = 300)

print(paste("Sankey diagram saved as", output_file))
