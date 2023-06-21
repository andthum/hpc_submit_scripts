#!/bin/bash

# Cleanup the analysis directory after all analyses have finished.
#
# * Remove *_slurm-[0-9]* suffix in directory names.
# * Move similar analyses into one directory.

gather() {
    # Gather output of similar analyses scripts.
    root="${1}"
    if [[ -d ${root} ]]; then
        echo "WARNING: Directory already exists: '${root}'"
        return 0
    fi
    if [[ -n $(find . -maxdepth 1 -type d -name "${root}_*slurm-[0-9]*" -print -quit) ]]; then
        mkdir "${root}/" || exit
        mv "${root}"_*slurm-[0-9]*/ "${root}/" || exit
        cd "${root}/" || exit
        mv "${root}"_*slurm-[0-9]*/* ./ || exit
        rm -r "${root:?}"_*slurm-[0-9]*/ || exit
        cd ../ || exit
    else
        echo "WARNING: No directory matching pattern '${root}_*slurm-[0-9]*'"
    fi
}

gather "density-z"
gather "densmap-z"
gather "energy"
gather "make_ndx"
gather "msd"
gather "polystat"
gather "potential-z"
gather "rdf_slab-z"
gather "rdf"
gather "trjconv"
