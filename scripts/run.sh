#!/bin/bash

if [[ $* != 2 ]]; then
  printf "Usage: %s INDIR OUTDIR\n" basename($0)
fi

IN_DIR=$1
OUT_DIR=$2

function lc() {
    wc -l $1 | cut -d ' ' -f 1
}

if [[ ! -d $IN_DIR ]]; then
  echo IN_DIR \"$IN_DIR\" does not exist.
  exit 1
fi

PROTEINS_FILE="$OUT_DIR/compiled_proteins.fa"

if 

NUM_FILES=`find $IN_DIR -maxdepth 1 -mindepth 1 -type f | wc -l`

if [ $NUM_FILES -eq 1 ]; then
  echo Found no files in \"$IN_DIR\"
  exit 1
fi

if [ $NUM_FILES -eq 1 ]; then
  cp $
fi
