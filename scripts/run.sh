#!/bin/bash

set -u

if [[ $# != 3 ]]; then
  printf "Usage: %s FASTA_DIR CLUSTER_FILD OUT_DIR\n" $(basename $0)
  exit
fi

IN_DIR=$1
CLUSTER_FILE=$2
OUT_DIR=$3

#
# Set up env
#
COMMON=common.sh

if [[ -e $COMMON ]]; then
  source $COMMON
else
  echo Cannot find \"$COMMON\"
  exit
fi

BIN="$( readlink -f -- "${0%/*}" )"
PATH=$BIN/../bin:$PATH


#
# Check args
#
if [[ ! -d $IN_DIR ]]; then
  echo IN_DIR \"$IN_DIR\" does not exist.
  exit
fi

if [[ ! -d $OUT_DIR ]]; then
  mkdir -p $OUT_DIR
fi

#
# Put all the incoming sequences into one file
#
PROTEINS_FILE="$OUT_DIR/compiled_proteins.fa"

if [[ -e $PROTEINS_FILE ]]; then
  rm $PROTEINS_FILE
fi

FILES_LIST=$OUT_DIR/files_list
find $IN_DIR -maxdepth 1 -mindepth 1 -type f > $FILES_LIST
NUM_FILES=$(lc $FILES_LIST)
echo NUM_FILES \"$NUM_FILES\"

if [ $NUM_FILES -gt 0 ]; then
  for FILE in $(cat $FILES_LIST); do
    echo Compiling $FILE
    cat $FILE >> $PROTEINS_FILE
  done
else
  echo Found no files in \"$IN_DIR\"
  exit
fi

#
# Run cd-hit-2d
#
CD_HIT_2D_IDEN="0.6"
CD_HIT_2D_COV="0.8"
CD_HIT_2D_OPTS="-g 1 -n 4 -d 0 -T 24 -M 45000"
CD_HIT_2D_OUT_DIR="$OUT_DIR/cd-hit-2d"

if [[ -d $CD_HIT_2D_OUT_DIR ]]; then
  rm -rf $CD_HIT_2D_OUT_DIR/*
else
  mkdir -p $CD_HIT_2D_OUT_DIR
fi

# run cdhit
echo Running cd-hit-2d
cd-hit-2d -i $CLUSTER_FILE -i2 $PROTEINS_FILE \
  -o $CD_HIT_2D_OUT_DIR -c $CD_HIT_2D_IDEN -aS $CD_HIT_2D_COV $CD_HIT_2D_OPTS

#
# Run cd-hit
#
CD_HIT_OUT_DIR="$OUT_DIR/cd-hit"

if [[ -d $CD_HIT_OUT_DIR ]]; then
  rm -rf $CD_HIT_OUT_DIR/*
else
  mkdir -p $CD_HIT_OUT_DIR
fi

CD_HIT_IDEN="0.6"
CD_HIT_COV="0.8"
CD_HIT_OPTS="-g 1 -n 4 -d 0 -T 24 -M 45000"

cd-hit -i $CD_HIT_2D_OUT_DIR -o $CD_HIT_OUT_DIR \
  -c $CD_HIT_IDEN -aS $CD_HIT_COV $CD_HIT_OPTS

# get 20+ id clusters and cluster to count FILE
OUTCL="$CD_HIT_OUT_DIR/cdhit60.clstr"
OUTFILE="$CD_HIT_OUT_DIR/cdhit60.id2cl"

# create a list of ids that belong to the 20+ member clusters
create_id_to_clst.pl $OUTCL $OUTFILE 

# create a fasta FILE with sequences from 20+ member clusters
LIST="$OUTFILE"
OUTFA="$OUTFILE.fa"
get_list_from_fa.pl $INFILE $LIST $OUTFA  
