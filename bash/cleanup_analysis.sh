#!/bin/bash

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# Cleanup steps after finishing an analysis task.

########################################################################
# Argument Parsing                                                     #
########################################################################

system=${1}       # The name of the system
settings=${2}     # The used simulation settings
save_dir=${3}     # The directory where to store the analysis results
sub_save_dir=${4} # Sub-level storage directory

########################################################################
# Cleanup                                                              #
########################################################################

top_save_dir="ana_${settings}_${system}"

if [[ ! -d ${top_save_dir} ]]; then
    mkdir -v "${top_save_dir}" || exit
fi
if [[ ! -d ${top_save_dir}/${sub_save_dir} ]]; then
    mkdir -v "${top_save_dir}/${sub_save_dir}" || exit
fi
if [[ ! -d ${top_save_dir}/${sub_save_dir}/${save_dir} ]]; then
    mv -v "${save_dir}" "${top_save_dir}/${sub_save_dir}"
fi
