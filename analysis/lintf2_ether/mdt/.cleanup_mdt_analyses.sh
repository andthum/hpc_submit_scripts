#!/bin/bash

# Cleanup the analysis directory after all analyses have finished.
#
# * Remove *_slurm-* suffix in directory names.
# * Move similar analyses into one directory.

gather() {
    # Gather output of similar analyses scripts.
    root="${1}"
    mkdir "${root}" || exit
    mv "${root}"_* "${root}"/
    cd "${root}"/ || exit
    mv "${root}"_*/* ./
    rm -r "${root}"_*
    cd ../ || exit
}

mv create_mda_universe_slurm-* create_mda_universe
mv energy_dist_slurm-* energy_dist
mv subvolume_charge_slurm-* subvolume_charge

gather discrete-z
gather lifetime_autocorr

name=attribute_hist
for cmp in Li NBT OBT OE NTf2 ether; do
    gather "${name}"_"${cmp}"
done
mkdir "${name}" || exit
mv "${name}"_* "${name}"/

name=axial_hex_dist
for cmp in 1nn 2nn; do
    gather "${name}"_"${cmp}"
done
mkdir "${name}" || exit
mv "${name}"_* "${name}"/

name=discrete_hex
for cmp in Li NBT OBT OE; do
    gather "${name}"_"${cmp}"
done
mkdir "${name}" || exit
mv "${name}"_* "${name}"/

name=renewal_events
for cmp in Li-ether Li-NTf2; do
    gather "${name}"_"${cmp}"
done
mkdir "${name}" || exit
mv "${name}"_* "${name}"/

name=topo_map
for cmp in Li-OBT Li-OE; do
    gather "${name}"_"${cmp}"
done
mkdir "${name}" || exit
mv "${name}"_* "${name}"/

name1=contact_hist
name2=contact_hist_at_pos_change
name3=contact_hist_slab-z
gather "${name2}"
for cmp in Li-OBT Li-OE; do
    gather "${name3}"_"${cmp}"
done
mkdir "${name3}" || exit
mv "${name3}"_* "${name3}"/
mkdir "${name1}" || exit
mv "${name1}"_* "${name1}"/
cd "${name1}"/ || exit
mv "${name2}"/ "${name3}"/ ../
mv "${name1}"_*/* ./
rm -r "${name1}"_*
cd ../ || exit

name1=msd
name2=msd_at_coord_change
name3=msd_layer
gather "${name2}"
gather "${name3}"
cd "${name3}" || exit
for cmp in ether Li NBT NTf2 OBT OE; do
    for file in *_"${cmp}"_slurm-*; do
        if [[ -f ${file} ]]; then
            mkdir "${name3}"_"${cmp}" || exit
            mv ./*_"${cmp}"_* "${name3}"_"${cmp}"/
            break
        fi
    done
done
cd ../ || exit
mkdir "${name1}" || exit
mv "${name1}"_* "${name1}"/
cd "${name1}"/ || exit
mv "${name2}"/ "${name3}"/ ../
mv "${name1}"_*/* ./
rm -r "${name1}"_*
cd ../ || exit

name1=lig_change_at_pos_change_blocks
name2=lig_change_at_pos_change_blocks_hist
gather "${name2}"
mkdir "${name1}" || exit
mv "${name1}"_* "${name1}"/
cd "${name1}"/ || exit
mv "${name2}"/ ../
mv "${name1}"_*/* ./
rm -r "${name1}"_*
cd ../ || exit
name1=lig_change_at_pos_change
name2=lig_change_at_pos_change_blocks
name3=lig_change_at_pos_change_blocks_hist
mkdir "${name1}" || exit
mv "${name1}"_* "${name1}"/
cd "${name1}"/ || exit
mv "${name2}"/ "${name3}"/ ../
mv "${name1}"_*/* ./
rm -r "${name1}"_*
cd ../ || exit
