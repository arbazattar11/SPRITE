# Directories
RAW_DATA_DIR="raw_data"
TRIMMED_DATA_DIR="trimmed_data"
ALIGNMENT_DIR="alignments"
FILTERED_DIR="filtered"
CONTACT_MATRIX_DIR="contact_matrix"
NORMALIZED_MATRIX_DIR="normalized_matrix"
VISUALIZATION_DIR="visualization"

# Tools and Resources
FASTQC="fastqc"
TRIMMOMATIC="trimmomatic"
BWA="bwa"
SAMTOOLS="samtools"
PICARD="picard"
SPRITE_TOOLS="sprite-tools"
PYTHON="python3"

# Reference Genome
REFERENCE_GENOME="reference_genome.fa"

# Step 1: Quality Control
mkdir -p $RAW_DATA_DIR/QC
$FASTQC $RAW_DATA_DIR/*.fastq -o $RAW_DATA_DIR/QC

# Step 2: Read Trimming
mkdir -p $TRIMMED_DATA_DIR
for file in $RAW_DATA_DIR/*.fastq; do
  base=$(basename $file .fastq)
  $TRIMMOMATIC SE -phred33 $file $TRIMMED_DATA_DIR/${base}_trimmed.fastq ILLUMINACLIP:adapter.fasta:2:30:10 SLIDINGWINDOW:4:20 MINLEN:50
done

# Step 3: Alignment
mkdir -p $ALIGNMENT_DIR
for file in $TRIMMED_DATA_DIR/*.fastq; do
  base=$(basename $file _trimmed.fastq)
  $BWA mem $REFERENCE_GENOME $file | $SAMTOOLS view -Sb - > $ALIGNMENT_DIR/${base}.bam
done

# Step 4: Filtering
mkdir -p $FILTERED_DIR
for file in $ALIGNMENT_DIR/*.bam; do
  base=$(basename $file .bam)
  $SAMTOOLS view -q 30 -b $file | $SAMTOOLS sort - | $PICARD MarkDuplicates I=/dev/stdin O=$FILTERED_DIR/${base}_filtered.bam M=${base}_metrics.txt REMOVE_DUPLICATES=true
  $SAMTOOLS index $FILTERED_DIR/${base}_filtered.bam
done

# Step 5: Matrix Construction
mkdir -p $CONTACT_MATRIX_DIR
$SPRITE_TOOLS create-matrix -i $FILTERED_DIR -o $CONTACT_MATRIX_DIR/matrix.txt

# Step 6: Normalization
mkdir -p $NORMALIZED_MATRIX_DIR
$SPRITE_TOOLS normalize-matrix -i $CONTACT_MATRIX_DIR/matrix.txt -o $NORMALIZED_MATRIX_DIR/normalized_matrix.txt

# Step 7: Visualization
mkdir -p $VISUALIZATION_DIR
$SPRITE_TOOLS visualize-matrix -i $NORMALIZED_MATRIX_DIR/normalized_matrix.txt -o $VISUALIZATION_DIR/visualization.png

# Step 8: Interaction Analysis
$SPRITE_TOOLS find-interactions -i $NORMALIZED_MATRIX_DIR/normalized_matrix.txt -o $VISUALIZATION_DIR/interactions.txt

echo "SPRITE analysis pipeline complete!"
```
