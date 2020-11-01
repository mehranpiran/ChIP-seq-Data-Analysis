
##### Quality control of the reads #####

$ wget (fastqc software download link)
$ gunzip fastqc_v0.11.7.zip
$ cd FastQC
$ chmod u+x fastqc
$ ~/apps/FastQC/fastqc ~/Data/*.fastq




##### Trim reads #####

$ wget (Trimmomatic software download link)
$ gunzip Trimmomatic-0.36.zip

For paired-end
$ java -jar ~/bin/trimmomatic-0.36.jar PE treatment_1.fastq treatment_2.fastq treatment_1_paired_trimmed.fq.gz treatment_1_unpaired.fq.gz treatment_2_paired_trimmed.fq.gz treatment_2_unpaired.fq.gz LEADING:10 TRAILING:10 MINLEN:25 HEADCROP:5 TAILCROP:5 SLIDINGWINDOW:4:20
or
$ for f in *_1.fastq; do java -jar ~/apps/Trimmomatic-0.36/trimmomatic-0.36.jar PE $f ${f/_1/_2} -baseout ${f/_treatment*/.fastq} HEADCROP:5 LEADING:10 TRAILING:10 MINLEN:25; done

For Single-end
$ java -jar ~/apps/Trimmomatic-0.36/trimmomatic-0.36.jar SE treatment.fastq treatment_paired_trimmed.fq.gz treatment_unpaired.fq.gz LEADING:10 TRAILING:10 MINLEN:25 HEADCROP:5 TAILCROP:5 SLIDINGWINDOW:4:20
or
for f in *.fastq; do java -jar ~/apps/Trimmomatic-0.36/trimmomatic-0.36.jar SE $f HEADCROP:5 LEADING:10 TRAILING:10 MINLEN:25; done




##### Alignment #####
Download human genome fasta indexes version 38
$ wget ftp://ftp.ccb.jhu.edu/pub/data/bowtie2_indexes/hg38.zip
$ gunzip hg38.zip

$ bowtie2 -q treatment1_paired_trimmed.fq -k 1 --local --no-unal -x hg38 > treatment1.sam
$ bowtie2 -q input1_paired_trimmed.fq -k 1 --local --no-unal -x hg38 > input1.sam




##### Normalization #####

removing mitochondrial and unassigned reads
$ sed '/chrM/d;/random/d;/chrUn/d' $treatment1.sam > $treatment1_filtered.sam
$ sed '/chrM/d;/random/d;/chrUn/d' $input1.sam > $input1_filtered.sam

converting sam files to bam
$ samtools view -S -b treatment1_filtered.sam > treatment1_filtered.bam
$ samtools view -S -b input1_filtered.sam > input1_filtered.bam

Count nuber of reads in bam file
$ samtools view -c treatment1_filtered.bam
20000000

Normalize aligned files for equal coverage. 
Sample reads to obtain ~ 10 million mapped (customized) reads for treatments and ~ 12 million mapped reads for input samples.
10000000 / 20000000 = 0.5 + 1 => 1.5
12000000 / 20000000 = 0.4 + 1 => 1.4

$ samtools view -b -s 1.5 treatment1_filtered.bam > treatment1_10E6.bam
$ samtools view -b -s 1.5 treatment2_filtered.bam > treatment2_10E6.bam
$ samtools view -b -s 1.4 input1_filtered.bam > input1_12E6.bam
$ samtools view -b -s 1.4 input2_filtered.bam > input2_12E6.bam
check the authorization for each new file



##### MACS2 Peak Calling #####

$ pip install macs2

$ macs2 callpeak -t treatment1_10E6.bam -c input1_12E6.bam -f BAM -n treatment1 -g hs --bdg -q 0.05 
$ macs2 callpeak -t treatment2_10E6.bam -c input2_12E6.bam -f BAM -n treatment2 -g hs --bdg -q 0.05 

Obtain script to convert bedgraph file into wiggle file
$ wget (%20bedgraph_to_wig.pl download link)
$ chmod 755 %20bedgraph_to_wig.pl
$ perl %20bedgraph_to_wig.pl --bedgraph treatment1.treat.pileup.bdg --wig treatment1.wig --step 50
$ perl %20bedgraph_to_wig.pl --bedgraph input1.treat.pileup.bdg --wig input1.wig --step 50

Obtain script to convert bedgraph to Bigwig (pertinent for genome browser viewing)
$ wget (bedGraphToBigWig download link)
$ chmod 755 bedGraphToBigWig

fetch chromosome sizes
$ wget (fetchChromSizes download link)
$ chmod 755 fetchChromSizes
$ ~/fetchChromSizes hg38 > hg38.chrom.sizes

convert bedgraph to Bigwig
$ ~/bedGraphToBigWig treatment1.treat.pileup.bdg hg38.chrom.sizes treatment1.BigWig
$ ~/bedGraphToBigWig input1.control.lambda.bdg hg38.chrom.sizes input1.BigWig



##### Differential Peak Calling Using HOMER #####
$ makeTagDirectory treatment1.tagdir treatment1_10E6.bam
$ makeTagDirectory treatment2.tagdir treatment2_10E6.bam

$ getDifferentialPeaks treatment1_peaks.narrowPeak treatment1.tagdir treatment2.tagdir > treatment1_diff_peaks.txt
$ getDifferentialPeaks treatment2_peaks.narrowPeak treatment2.tagdir treatment1.tagdir > treatment2_diff_peaks.txt

