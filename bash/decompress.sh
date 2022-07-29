#!/bin/bash

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# Decompress the input file if necessary.
#
# Prints 1 if the input file has been decompressed and 0 if no
# decompression was done.

########################################################################
# Argument Parsing                                                     #
########################################################################

infile=${1} # The input file (without the compression extension!)
# See https://github.com/koalaman/shellcheck/wiki/SC2086#exceptions
# and https://github.com/koalaman/shellcheck/wiki/SC2206
# shellcheck disable=SC2206
flags=(${2}) # Additional flags to parse to the decompressor (besides --decompress)

########################################################################
# Decompression                                                        #
########################################################################

if [[ -f ${infile} ]]; then
    decompressed=0
elif [[ -f ${infile}.gz ]]; then
    gzip --decompress "${flags[*]}" "${infile}.gz" || exit
    decompressed=1
elif [[ -f ${infile}.bz2 ]]; then
    bzip2 --decompress "${flags[*]}" "${infile}.bz2" || exit
    decompressed=1
elif [[ -f ${infile}.xz ]]; then
    xz --decompress "${flags[*]}" "${infile}.xz" || exit
    decompressed=1
elif [[ -f ${infile}.lzma ]]; then
    lzma --decompress "${flags[*]}" "${infile}.lzma" || exit
    decompressed=1
fi

echo "${decompressed}"
