#!/bin/bash

#SBATCH --time=2-00:00:00
#SBATCH --job-name="gmx_potential-z"
#SBATCH --output="gmx_potential-z_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_gmx_analyses_lintf2_ether.py

analysis="potential-z"
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
dt=${8}       # Only use frame when t MOD dt = first time
num_bins=${9} # Number of bins

echo -e "\n"
echo "Parsed arguments:"
echo "bash_dir = ${bash_dir}"
echo "gmx_lmod = ${gmx_lmod}"
echo "gmx_exe  = ${gmx_exe}"
echo "system   = ${system}"
echo "settings = ${settings}"
echo "begin    = ${begin}"
echo "end      = ${end}"
echo "dt       = ${dt}"
echo "num_bins = ${num_bins}"

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

echo -e "\n"
echo "================================================================="
echo 0 |
    ${gmx_exe} potential \
        -f "${settings}_out_${system}_pbc_whole_mol.xtc" \
        -s "${settings}_${system}.tpr" \
        -n "${system}.ndx" \
        -o "${settings}_${system}_${analysis}.xvg" \
        -oc "${settings}_${system}_charge_density-z.xvg" \
        -of "${settings}_${system}_field-z.xvg" \
        -b "${begin}" \
        -e "${end}" \
        -dt "${dt}" \
        -d Z \
        -sl "${num_bins}" \
        -correct ||
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
        "${settings}_${system}_${analysis}.xvg" \
        "${settings}_${system}_charge_density-z.xvg" \
        "${settings}_${system}_field-z.xvg" \
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
