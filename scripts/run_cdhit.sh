#$ -S /bin/bash

cd $CWD

# for cdhit 
PROGRAM="/usr/local/bin/cd-hit"
INDIR=$1
OUTDIR=$2
IDEN="0.6"
COV="0.8"
OPTIONS="-g 1 -n 4 -d 0 -T 24 -M 45000"

# run self clustering for each sample in the set
INFILE="$INDIR/cdhit60"
OUT="$OUTDIR/cdhit60"

# run cdhit
$PROGRAM -i $INFILE -o $OUT -c $IDEN -aS $COV $OPTIONS

# get 20+ id clusters and cluster to count FILE
OUTCL="$OUTDIR/cdhit60.clstr"
OUTFILE="$OUTDIR/cdhit60.id2cl"

# create a list of ids that belong to the 20+ member clusters
/usr/local/bin/pcpipe/create_id_to_clst.pl $OUTCL $OUTFILE 

# create a fasta FILE with sequences from 20+ member clusters
LIST="$OUTFILE"
OUTFA="$OUTFILE.fa"
/usr/local/bin/pcpipe/get_list_from_fa.pl $INFILE $LIST $OUTFA  
