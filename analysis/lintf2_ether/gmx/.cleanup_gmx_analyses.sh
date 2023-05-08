#!/bin/bash

# Cleanup the analysis directory after all analyses have finished.
#
# * Remove *_slurm-[0-9]* suffix in directory names.
# * Move similar analyses into one directory.

gather() {
    # Gather output of similar analyses scripts.
    root="${1}"
    mkdir "${root}" || exit
    mv "${root}"_*slurm-[0-9]* "${root}"/
    cd "${root}"/ || exit
    mv "${root}"_*slurm-[0-9]*/* ./
    rm -r "${root}"_*slurm-[0-9]*
    cd ../ || exit
}

mv energy_slurm-[0-9]* energy
mv make_ndx_slurm-[0-9]* make_ndx
mv polystat_slurm-[0-9]* polystat
mv potential-z_slurm-[0-9]* potential-z

gather density-z
gather densmap-z
gather msd
gather trjconv

name1=rdf
name2=rdf_slab-z
gather "${name2}"
mkdir "${name1}" || exit
mv "${name1}"_* "${name1}"/
cd "${name1}"/ || exit
mv "${name2}"/ ../
mv "${name1}"_*/* ./
rm -r "${name1}"_*
cd ../ || exit
