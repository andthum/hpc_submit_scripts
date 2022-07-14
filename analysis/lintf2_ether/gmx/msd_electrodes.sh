#!/bin/bash

#SBATCH --time=7-00:00:00
#SBATCH --job-name="gmx_msd_electrodes"
#SBATCH --output="gmx_msd_electrodes_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_gmx_analyses_lintf2_ether.py

thisfile=$(basename "${BASH_SOURCE[0]}")
echo "${thisfile}"
start_time=$(date --rfc-3339=seconds || exit)
echo "Start time = ${start_time}"

########################################################################
# Argument Parsing                                                     #
########################################################################

bash_dir=${1}  # Directory containing bash scripts used by this script
gmx_lmod=${2}  # File containing the modules to load Gromacs
gmx_exe=${3}   # Name of the Gromacs executable
system=${4}    # The name of the system to analyze
settings=${5}  # The used simulation settings
begin=${6}     # First frame to read from trajectory in ps
end=${7}       # Last frame to read from trajectory in ps
begin_fit=${8} # Start time for fitting the MSD in ps
end_fit=${9}   # End time for fitting the MSD in ps
trestart=${10} # Time between restarting points in trajectory (ps)

echo -e "\n"
echo "Parsed arguments:"
echo "bash_dir  = ${bash_dir}"
echo "gmx_lmod  = ${gmx_lmod}"
echo "gmx_exe   = ${gmx_exe}"
echo "system    = ${system}"
echo "settings  = ${settings}"
echo "begin     = ${begin}"
echo "end       = ${end}"
echo "begin_fit = ${begin_fit}"
echo "end_fit   = ${end_fit}"
echo "trestart  = ${trestart}"

if [[ ! -d ${bash_dir} ]]; then
    echo
    echo "ERROR: No such directory: '${bash_dir}'"
    exit 1
fi

if [[ ${system} != *gra* ]]; then
    echo
    echo "Error: System contains no electrodes."
    exit 1
fi

echo -e "\n"
bash "${bash_dir}/echo_slurm_output_environment_variables.sh"

########################################################################
# Start the Analysis                                                   #
########################################################################

# shellcheck source=/dev/null
source "${bash_dir}/load_gmx.sh" "${gmx_lmod}" "${gmx_exe}" || exit

echo -e "\n"
echo "================================================================="
# B3 B2 B1 T1 T2 T3 graB graT
echo "15 16 17 18 19 20 21 22" |
    ${gmx_exe} msd \
        -f "${settings}_out_${system}_pbc_whole_mol_nojump.xtc" \
        -s "${settings}_${system}.tpr" \
        -n "${system}.ndx" \
        -o "${settings}_${system}_msd_electrodes_normcomm.xvg" \
        -b "${begin}" \
        -e "${end}" \
        -ngroup 8 \
        -trestart "${trestart}" \
        -beginfit "${begin_fit}" \
        -endfit "${end_fit}" ||
    exit
echo "================================================================="
echo -e "\n"
echo "================================================================="
# B3 B2 B1 graB
echo "15 16 17 21" |
    ${gmx_exe} msd \
        -f "${settings}_out_${system}_pbc_whole_mol_nojump.xtc" \
        -s "${settings}_${system}.tpr" \
        -n "${system}.ndx" \
        -o "${settings}_${system}_msd_graB_rmcomm.xvg" \
        -b "${begin}" \
        -e "${end}" \
        -ngroup 3 \
        -rmcomm \
        -trestart "${trestart}" \
        -beginfit "${begin_fit}" \
        -endfit "${end_fit}" ||
    exit
echo "================================================================="
echo -e "\n"
echo "================================================================="
# T1 T2 T3 graT
echo "18 19 20 22" |
    ${gmx_exe} msd \
        -f "${settings}_out_${system}_pbc_whole_mol_nojump.xtc" \
        -s "${settings}_${system}.tpr" \
        -n "${system}.ndx" \
        -o "${settings}_${system}_msd_graT_rmcomm.xvg" \
        -b "${begin}" \
        -e "${end}" \
        -ngroup 3 \
        -rmcomm \
        -trestart "${trestart}" \
        -beginfit "${begin_fit}" \
        -endfit "${end_fit}" ||
    exit
echo "================================================================="

########################################################################
# Cleanup                                                              #
########################################################################

save_dir="msd_electrodes_slurm-${SLURM_JOB_ID}"
if [[ ! -d ${save_dir} ]]; then
    echo -e "\n"
    mkdir -v "${save_dir}" || exit
    mv -v \
        "${settings}_${system}_msd_electrodes_normcomm.xvg" \
        "${settings}_${system}_msd_graB_rmcomm.xvg" \
        "${settings}_${system}_msd_graT_rmcomm.xvg" \
        "${settings}_${system}_msd_electrodes_slurm-${SLURM_JOB_ID}.out" \
        "${save_dir}"
    bash "${bash_dir}/cleanup_analysis.sh" \
        "${system}" \
        "${settings}" \
        "${save_dir}" \
        "gmx"
fi

end_time=$(date --rfc-3339=seconds)
elapsed_time=$(bash \
    "${bash_dir}/date_time_diff.sh" \
    -s "${start_time}" \
    -e "${end_time}")
echo -e "\n"
echo "End time     = ${end_time}"
echo "Elapsed time = ${elapsed_time}"
echo "${thisfile} done"