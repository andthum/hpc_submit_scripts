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

gather_dirs() {
    # Gather directories that have the same prefix.
    local root="${1}"
    if [[ -d ${root} ]]; then
        echo "WARNING: Directory already exists: '${root}'"
        return 0
    fi
    if [[ -n $(find . -maxdepth 1 -type d -name "${root}?*" -print -quit) ]]; then
        mkdir "${root}/" || exit
        mv "${root}"?*/ "${root}/" || exit
    else
        echo "WARNING: No directory matching pattern '${root}?*'"
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

gather_cmps_keep_dir() {
    # Gather output of similar analysis scripts ordered by compounds
    # into sub-directories but opposed to `gather_cmps` do not move the
    # files out of their respective *_slurm-[0-9] directories.
    local root="${1}"
    local cmps="${2}"

    # Create "root" directory.
    if [[ -d ${root} ]]; then
        echo "WARNING: Directory already exists: '${root}'"
        return 0
    else
        mkdir "${root}/" || exit
    fi

    for cmp in ${cmps}; do
        if [[ -n $(find . -maxdepth 1 -type d -name "${root}_${cmp}*_slurm-[0-9]*" -print -quit) ]]; then
            if [[ -d ${root}/${root}_${cmp} ]]; then
                echo "WARNING: Directory already exists: '${root}/${root}_${cmp}'"
                continue
            else
                # Create compound directory.
                mkdir "${root}/${root}_${cmp}/" || exit
                # Move analysis directories to the compound directory.
                mv "${root}_${cmp}"*_slurm-[0-9]*/ "${root}/${root}_${cmp}/" || exit
                cd "${root}/${root}_${cmp}/" || exit
                for dir in "${root}_${cmp}"*_slurm-[0-9]*; do
                    if [[ -d ${dir%_slurm-[0-9]*} ]]; then
                        echo "WARNING: Directory already exists: '${dir%_slurm-[0-9]*}'"
                        continue
                    else
                        # Remove the "_slurm-[0-9]*" suffix of the
                        # directory names.
                        mv "${dir}" "${dir%_slurm-[0-9]*}" || exit
                    fi
                done
                cd ../../ || exit
            fi
        fi
    done

    # Check if the root directory is empty.
    if [[ -n $(find "${root}/" -prune -empty) ]]; then
        echo "WARNING: No directory matching pattern '${root}_<compound>*_slurm-[0-9]*'"
        rm -r "${root:?}/" || exit
        return 0
    fi
}

gather "create_mda_universe"
gather "energy_dist"
gather "lifetime_autocorr"
gather "subvolume_charge"

gather_cmps "attribute_hist" "Li NBT OBT OE NTf2 ether"
gather_cmps "densmap-z" "Li NBT OBT OE NTf2 ether"
gather_cmps "renewal_events" "Li-ether Li-NTf2"
gather_cmps "topo_map" "Li-OBT Li-OE"

gather_dirs "lig_change_at_pos_change_blocks_hist_Li-OBT"
gather_dirs "lig_change_at_pos_change_blocks_hist_Li-OE"
gather_dirs "lig_change_at_pos_change_blocks_Li-OBT"
gather_dirs "lig_change_at_pos_change_blocks_Li-OE"
gather_dirs "lig_change_at_pos_change_Li-OBT"
gather_dirs "lig_change_at_pos_change_Li-OE"

gather_cmps "axial_hex_dist_1nn" "Li NBT OBT OE"
gather_cmps "axial_hex_dist_2nn" "Li NBT OBT OE"
gather_dirs "axial_hex_dist"

gather_cmps "contact_hist_slab-z" "Li-OBT Li-OE"
gather_cmps "contact_hist_at_pos_change" "Li-OBT Li-OE"
gather "contact_hist"

gather_cmps "msd_layer" "Li NBT OBT OE NTf2 ether"
gather "msd_at_coord_change"
gather "msd"

gather_cmps_keep_dir "discrete-hex" "Li NBT OBT OE"
gather "discrete-z"
