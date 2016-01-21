#!/bin/bash

set -u

if [[ $# != 3 ]]; then
  printf "Usage: %s FASTA_DIR CLUSTER_FILE OUT_DIR\n" $(basename $0)
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

if [[ ! -s $CLUSTER_FILE ]]; then
  echo Bad CLUSTER_FILE \"$CLUSTER_FILE\" 
  exit
fi

if [[ ! -d $OUT_DIR ]]; then
  mkdir -p $OUT_DIR
fi

#
# Put all the incoming sequences into one file
#
SEQUENCES_FILE="$OUT_DIR/compiled_sequences.fa"

if [[ -e $SEQUENCES_FILE ]]; then
  rm $SEQUENCES_FILE
fi

FILES_LIST=$OUT_DIR/files_list
find $IN_DIR -maxdepth 1 -mindepth 1 -type f > $FILES_LIST
NUM_FILES=$(lc $FILES_LIST)
echo NUM_FILES \"$NUM_FILES\"

if [ $NUM_FILES -gt 0 ]; then
  for FILE in $(cat $FILES_LIST); do
    echo Compiling $FILE
    cat $FILE >> $SEQUENCES_FILE
  done
else
  echo Found no files in \"$IN_DIR\"
  exit
fi

if [[ ! -s $SEQUENCES_FILE ]]; then
  echo Empty SEQUENCES_FILE \"$SEQUENCES_FILE\"
  exit
fi

#
# Run cd-hit-2d
# It will create a "clstr" file of those that did cluster 
# and the -o "novel" file of those that didn't -- this is
# the file we want to self-cluster with cd-hit
#
CD_HIT_2D_IDEN="0.6"
CD_HIT_2D_COV="0.8"
CD_HIT_2D_OPTS="-g 1 -n 4 -d 0 -T 24 -M 45000"
CD_HIT_2D_OUT_DIR="$OUT_DIR/cdhit-2d-outdir"
CD_HIT_2D_NOVEL="$CD_HIT_2D_OUT_DIR/novel.fa"

if [[ ! -d $CD_HIT_2D_OUT_DIR ]]; then
  mkdir -p $CD_HIT_2D_OUT_DIR
fi

if [[ -s $CD_HIT_2D_NOVEL ]]; then
  echo CD_HIT_2D_NOVEL \"$CD_HIT_2D_NOVEL\" exists already.
else
  echo Running cd-hit-2d
  cd-hit-2d -i $CLUSTER_FILE -i2 $SEQUENCES_FILE \
  -o $CD_HIT_2D_NOVEL -c $CD_HIT_2D_IDEN -aS $CD_HIT_2D_COV $CD_HIT_2D_OPTS
fi

if [[ ! -s $CD_HIT_2D_NOVEL ]]; then
  echo All sequences clustered.  Exiting.
  exit
fi

#
# Run cd-hit on the "novel" sequences
#
CD_HIT_IDEN="0.6"
CD_HIT_COV="0.8"
CD_HIT_OPTS="-g 1 -n 4 -d 0 -T 24 -M 45000"
CD_HIT_OUT_DIR="$OUT_DIR/cdhit-outdir"
CD_HIT_OUT_FILE="$CD_HIT_OUT_DIR/cdhit60"

if [[ ! -d $CD_HIT_OUT_DIR ]]; then
  mkdir -p $CD_HIT_OUT_DIR
fi

if [[ -s $CD_HIT_OUT_FILE ]]; then
  echo CD_HIT_OUT_FILE \"$CD_HIT_OUT_FILE\" exists already.
else
  echo Running cd-hit
  cd-hit -i $CD_HIT_2D_NOVEL -o $CD_HIT_OUT_FILE \
    -c $CD_HIT_IDEN -aS $CD_HIT_COV $CD_HIT_OPTS
fi

#
# Create a FASTA file of the representative sequences from 
# clusters having more than 20 constituents
#
CD_HIT_CLUSTER_FILE="$CD_HIT_OUT_FILE.clstr"

if [[ ! -s $CD_HIT_CLUSTER_FILE ]]; then
  echo No cluster file from cd-hit.
  exit
fi

MIN_SEQS=20
NOVEL_FA="$OUT_DIR/novel.fa"
$BIN/fa_from_clusters.pl --cluster_file $CD_HIT_CLUSTER_FILE \
  --sequence_file $SEQUENCES_FILE -n $MIN_SEQS -o $NOVEL_FA


