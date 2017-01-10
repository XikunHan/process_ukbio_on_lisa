#!/bin/bash

bs=$((1024*1024))
infile=$1
outfile=$2
skip=$3
length=$4

(
  dd bs=1 skip=$skip count=0 > /dev/null
  dd bs=$bs count=$(($length / $bs)) iflag=fullblock conv=notrunc >> "$outfile"
  dd bs=$(($length % $bs)) count=1 iflag=fullblock conv=notrunc >> "$outfile"
) < "$infile"
