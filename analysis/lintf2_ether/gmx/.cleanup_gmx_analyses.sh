#!/bin/bash

# Cleanup the analysis directory after all analyses have finished.
#
# * Remove *_slurm-[0-9]* suffix in directory names.
# * Move similar analyses into one directory.

gather() {
    # Gather output of similar analysis scripts.
    local root="${1}"
    if [[ -d ${root} ]]; then
        echo "WARNING: Directory already exists: '${root}'"
        return 0
    fi
    if [[ -n $(find . -maxdepth 1 -type d -name "${root}*_slurm-[0-9]*" -print -quit) ]]; then
        mkdir "${root}/" || exit
        mv "${root}"*_slurm-[0-9]*/ "${root}/" || exit
        cd "${root}/" || exit
        mv "${root}"*_slurm-[0-9]*/* ./ || exit
        rm -r "${root:?}"*_slurm-[0-9]*/ || exit
        cd ../ || exit
    else
        echo "WARNING: No directory matching pattern '${root}*_slurm-[0-9]*'"
    fi
}

gather_cmps() {
    # Gather output of similar analysis scripts ordered by compounds
    # into sub-directories.
    local root="${1}"
    local cmps="${2}"

    # Create "root" directory.
    if [[ -d ${root} ]]; then
        echo "WARNING: Directory already exists: '${root}'"
        return 0
    else
        mkdir "${root}/" || exit
    fi

    # Move all "compound" directories to the root directory.
    for cmp in ${cmps}; do
        if [[ -n $(find . -maxdepth 1 -type d -name "${root}_${cmp}*_slurm-[0-9]*" -print -quit) ]]; then
            mv "${root}_${cmp}"*_slurm-[0-9]*/ "${root}/" || exit
        fi
    done

    # Check if the root directory is empty.
    if [[ -n $(find "${root}/" -prune -empty) ]]; then
        echo "WARNING: No directory matching pattern '${root}_<compound>*_slurm-[0-9]*'"
        rm -r "${root:?}/" || exit
        return 0
    fi

    # Gather all compound analyses.
    cd "${root}/" || exit
    for cmp in ${cmps}; do
        gather "${root}_${cmp}"
    done
    cd ../ || exit
}

gather "density-z"
gather "energy"
gather "make_ndx"
gather "msd"
gather "polystat"
gather "potential-z"
gather "trjconv"

gather_cmps "densmap-z" "gra Li NBT OBT OE"

gather_cmps "rdf_slab-z" "Li-com NTf2-com ether-com Li NBT OE"
gather "rdf"
