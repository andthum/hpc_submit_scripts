#!/bin/bash

#SBATCH --time=1-00:00:00
#SBATCH --job-name="create_mda_universe"
#SBATCH --output="create_mda_universe_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=512M
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_mdt_analyses_lintf2_ether.py

analysis="mda_universe"
thisfile=$(basename "${BASH_SOURCE[0]}")
echo "${thisfile}"
start_time=$(date --rfc-3339=seconds || exit)
echo "Start time = ${start_time}"

########################################################################
# Argument Parsing                                                     #
########################################################################

bash_dir=${1} # Directory containing bash scripts used by this script
py_lmod=${2}  # File containing the modules to load Python
py_exe=${3}   # Name of the Python executable
system=${4}   # The name of the system to analyze
settings=${5} # The used simulation settings

echo -e "\n"
echo "Parsed arguments:"
echo "bash_dir = ${bash_dir}"
echo "py_lmod  = ${py_lmod}"
echo "py_exe   = ${py_exe}"
echo "system   = ${system}"
echo "settings = ${settings}"

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
source "${bash_dir}/load_python.sh" "${py_lmod}" "${py_exe}" || exit

########################################################################
# Start the Analysis                                                   #
########################################################################

echo -e "\n"
echo "Creating MDAnalysis Universe for"
echo "${settings}_out_${system}_pbc_whole_mol.xtc"
echo "================================================================="
${py_exe} -c "\
import MDAnalysis as mda;\
mda.Universe(\
    '${settings}_${system}.tpr', \
    '${settings}_out_${system}_pbc_whole_mol.xtc' \
)\
" ||
    exit
echo "================================================================="

echo -e "\n"
echo "Creating MDAnalysis Universe for"
echo "${settings}_out_${system}_pbc_whole_mol_nojump.xtc"
echo "================================================================="
${py_exe} -c "\
import MDAnalysis as mda;\
mda.Universe(\
    '${settings}_${system}.tpr',\
    '${settings}_out_${system}_pbc_whole_mol_nojump.xtc'\
)\
" ||
    exit
echo "================================================================="

########################################################################
# Cleanup                                                              #
########################################################################

save_dir="create_${analysis}_slurm-${SLURM_JOB_ID}"
if [[ ! -d ${save_dir} ]]; then
    echo -e "\n"
    mkdir -v "${save_dir}" || exit
    mv -v \
        "${settings}_${system}_create_${analysis}_slurm-${SLURM_JOB_ID}.out" \
        "${save_dir}"
    bash "${bash_dir}/cleanup_analysis.sh" \
        "${system}" \
        "${settings}" \
        "${save_dir}" \
        "mdt"
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
