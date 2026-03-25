#!/bin/bash

##############
# Submission #
##############

for system in lintf2_*; do
    if [[ "${system}" == "lintf2_g0_20-1_sc80" ]]; then
        settings=pr_nvt303_nh
    else
        settings=pr_nvt423_nh
    fi

    echo "${system}/07_${settings}_${system}"
    cd "${system}/07_${settings}_${system}" || exit

    # Submit all "normal" bulk contact histograms.
    submit_mdt_analyses_lintf2_ether.py --system "${system}" --settings "${settings}" --scripts 6.1 --begin 0 --end 50000 --time 1-00:00:00 || exit
    # Submit sll lifetime autocorrelations.
    submit_mdt_analyses_lintf2_ether.py --system "${system}" --settings "${settings}" --scripts 10 --begin 0 --end 100000 --time 1-00:00:00 || exit
    # Submit sll lifetime autocorrelations --nblocks
    submit_mdt_analyses_lintf2_ether.py --system "${system}" --settings "${settings}" --scripts 10 --nblocks 5 --time 1-00:00:00 || exit

    cd ../../ || exit
done


###########
# Cleanup #
###########

# General
# shellcheck disable=SC2044
for file in $(find . -type f -user root -name "pr_*_slurm-[0-9]*.out"); do rm -vf "${file:?}"; done

# shellcheck disable=SC2044
for file in $(find . -type f -name "*.out"); do gzip --best --verbose "${file}"; done
# shellcheck disable=SC2044
for file in $(find . -type f -name "*.txt"); do gzip --best --verbose "${file}"; done


# Contact histograms
block=0-100ns
for system in lintf2_*; do
    if [[ "${system}" == "lintf2_g0_20-1_sc80" ]]; then
        settings=pr_nvt303_nh
    else
        settings=pr_nvt423_nh
    fi

    echo "${system}/07_${settings}_${system}/ana_${settings}_${system}/mdt"
    cd "${system}/07_${settings}_${system}/ana_${settings}_${system}/mdt" || exit

    for cmp in Li-O Li-OBT Li-OE O-Li OBT-Li OE-Li; do

        # Create "root" directory.
        if [[ ! -d "contact_hist_block_average/contact_hist_${cmp}" ]]; then
            mkdir -p "contact_hist_block_average/contact_hist_${cmp}" || exit
        fi

        for dir in "contact_hist_${cmp}_slurm-"[0-9]*; do
            cd "${dir}" || exit
            for file in *"_contact_hist_${cmp}"*; do
                mv "${file}" "${file//_contact_hist_${cmp}/_contact_hist_${cmp}_${block}}" || exit
            done
            cd .. || exit
            mv "contact_hist_${cmp}_slurm-"[0-9]*/* "contact_hist_block_average/contact_hist_${cmp}" || exit
            rm -r "contact_hist_${cmp}_slurm-"[0-9]*/ || exit
        done
    done

    cd ../../../../ || exit
done


# Lifetime autocorrelations
block=0-200ns
for system in lintf2_*; do
    if [[ "${system}" == "lintf2_g0_20-1_sc80" ]]; then
        settings=pr_nvt303_nh
    else
        settings=pr_nvt423_nh
    fi

    echo "${system}/07_${settings}_${system}/ana_${settings}_${system}/mdt"
    cd "${system}/07_${settings}_${system}/ana_${settings}_${system}/mdt" || exit

    for cmp in Li-NTf2 Li-OBT Li-OE Li-ether; do

        # Create "root" directory.
        if [[ ! -d "lifetime_autocorr_block_average/lifetime_autocorr_${cmp}" ]]; then
            mkdir -p "lifetime_autocorr_block_average/lifetime_autocorr_${cmp}" || exit
        fi

        for dir in "lifetime_autocorr_${cmp}_slurm-"[0-9]*; do
            cd "${dir}" || exit
            for file in *"_lifetime_autocorr_${cmp}"*; do
                mv "${file}" "${file//_lifetime_autocorr_${cmp}/_lifetime_autocorr_${cmp}_${block}}" || exit
            done
            cd .. || exit
            mv "lifetime_autocorr_${cmp}_slurm-"[0-9]*/* "lifetime_autocorr_block_average/lifetime_autocorr_${cmp}" || exit
            rm -r "lifetime_autocorr_${cmp}_slurm-"[0-9]*/ || exit
        done
    done

    cd ../../../../ || exit
done


# Lifetime autocorrelations --nblocks
for system in lintf2_*; do
    if [[ "${system}" == "lintf2_g0_20-1_sc80" ]]; then
        settings=pr_nvt303_nh
    else
        settings=pr_nvt423_nh
    fi

    echo "${system}/07_${settings}_${system}/ana_${settings}_${system}/mdt"
    cd "${system}/07_${settings}_${system}/ana_${settings}_${system}/mdt" || exit

    for cmp in Li-NTf2 Li-OBT Li-OE Li-ether; do

        # Create "root" directory.
        if [[ ! -d "lifetime_autocorr_block_average" ]]; then
            mkdir "lifetime_autocorr_block_average" || exit
        fi

        for dir in "lifetime_autocorr_${cmp}_slurm-"[0-9]*; do
            cd "${dir}" || exit
            for file in *"_lifetime_autocorr_${cmp}"*; do
                mv "${file}" "${file//_lifetime_autocorr_${cmp}/_lifetime_autocorr_${cmp}_nblocks_5}" || exit
            done
            cd .. || exit
            mv "lifetime_autocorr_${cmp}_slurm-"[0-9]*/* "lifetime_autocorr_block_average" || exit
            rm -r "lifetime_autocorr_${cmp}_slurm-"[0-9]*/ || exit
        done
    done

    cd ../../../../ || exit
done
