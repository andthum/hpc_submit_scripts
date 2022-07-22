#!/bin/bash

#SBATCH --time=0-00:20:00
#SBATCH --job-name="gmx_energy"
#SBATCH --output="gmx_energy_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=512M
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_gmx_analyses_lintf2_ether.py

analysis="energy"
thisfile=$(basename "${BASH_SOURCE[0]}")
echo "${thisfile}"
start_time=$(date --rfc-3339=seconds || exit)
echo "Start time = ${start_time}"

########################################################################
# Argument Parsing                                                     #
########################################################################

bash_dir=${1} # Directory containing bash scripts used by this script
gmx_lmod=${2} # File containing the modules to load Gromacs
gmx_exe=${3}  # Name of the Gromacs executable
system=${4}   # The name of the system to analyze
settings=${5} # The used simulation settings
begin=${6}    # First frame to read from trajectory in ps
end=${7}      # Last frame to read from trajectory in ps

echo -e "\n"
echo "Parsed arguments:"
echo "bash_dir = ${bash_dir}"
echo "gmx_lmod = ${gmx_lmod}"
echo "gmx_exe  = ${gmx_exe}"
echo "system   = ${system}"
echo "settings = ${settings}"
echo "begin    = ${begin}"
echo "end      = ${end}"

if [[ ! -d ${bash_dir} ]]; then
    echo
    echo "ERROR: No such directory: '${bash_dir}'"
    exit 1
fi

echo -e "\n"
bash "${bash_dir}/echo_slurm_output_environment_variables.sh"

########################################################################
# Load required executable(s)                                          #
########################################################################

# shellcheck source=/dev/null
source "${bash_dir}/load_gmx.sh" "${gmx_lmod}" "${gmx_exe}" || exit

########################################################################
# Start the Analysis                                                   #
########################################################################

begin_ns=$(printf "%.0f" "${begin}" || exit)
begin_ns=$((begin_ns / 1000))
end_ns=$(printf "%.0f" "${end}" || exit)
end_ns=$((end_ns / 1000))
outfile="${settings}_${system}_${analysis}_${begin_ns}-${end_ns}ns.xvg"

echo -e "\n"
echo "================================================================="
echo -e \
    "Potential \n" \
    "Kinetic-E \n" \
    "Total-E \n" \
    "Conserved-E \n" \
    "Temperature \n" \
    "Pressure \n" \
    "Volume \n" \
    "Density" |
    ${gmx_exe} energy \
        -f "${settings}_out_${system}.edr" \
        -s "${settings}_${system}.tpr" \
        -o "${outfile}" \
        -b "${begin}" \
        -e "${end}" ||
    exit
echo "================================================================="

########################################################################
# Cleanup                                                              #
########################################################################

save_dir="${analysis}_slurm-${SLURM_JOB_ID}"
if [[ ! -d ${save_dir} ]]; then
    echo -e "\n"
    mkdir -v "${save_dir}" || exit
    mv -v \
        "${outfile}" \
        "${settings}_${system}_${analysis}_slurm-${SLURM_JOB_ID}.out" \
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
