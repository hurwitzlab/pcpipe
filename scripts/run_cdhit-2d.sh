#$ -S /bin/bash

cd $CWD

# for cdhit 
PROGRAM="/usr/local/bin/cd-hit-2d"
# cluster fasta file
DB1=$1
# sequence fasta file defined by the user
DB2=$2
OUTDIR=$3
IDEN="0.6"
COV="0.8"
OPTIONS="-g 1 -n 4 -d 0 -T 24 -M 45000"

# run pu clustering
OUT="$OUTDIR/cdhit60"

# run cdhit
$PROGRAM -i $DB1 -i2 $DB2 -o $OUT -c $IDEN -aS $COV $OPTIONS
