#!/bin/bash

#SBATCH --time=0-06:00:00
#SBATCH --job-name="mdt_renewal_events_Li-ether_back_jump_prob_discrete"
#SBATCH --output="mdt_renewal_events_Li-ether_back_jump_prob_discrete_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=24G
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021-2023  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_mdt_analyses_lintf2_ether.py

analysis="renewal_events_Li-ether_back_jump_prob_discrete"
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
mdt_path=${4} # Path to the MDTools installation
system=${5}   # The name of the system to analyze
settings=${6} # The used simulation settings

echo -e "\n"
echo "Parsed arguments:"
echo "bash_dir = ${bash_dir}"
echo "py_lmod  = ${py_lmod}"
echo "py_exe   = ${py_exe}"
echo "mdt_path = ${mdt_path}"
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

if [[ -f ${settings}_${system}_renewal_events_Li-ether_dtrj.npy ]]; then
    infile1="${settings}_${system}_renewal_events_Li-ether_dtrj.npy"
else
    infile1="${settings}_${system}_renewal_events_Li-ether_dtrj.npz"
fi
if [[ -f ${settings}_${system}_discrete-z_Li_dtrj.npy ]]; then
    infile2="${settings}_${system}_discrete-z_Li_dtrj.npy"
else
    infile2="${settings}_${system}_discrete-z_Li_dtrj.npz"
fi

echo -e "\n"
echo "back_jump_prob_discrete.py --continuous"
echo "================================================================="
${py_exe} -u \
    "${mdt_path}/scripts/discretization/back_jump_prob_discrete.py" \
    --f1 "${infile1}" \
    --f2 "${infile2}" \
    -o "${settings}_${system}_${analysis}_discard-neg_continuous.txt.gz" \
    --norm-out "${settings}_${system}_${analysis}_discard-neg_continuous_norm.txt.gz" \
    -b "0" \
    -e "-1" \
    --every "1" \
    --discard-neg \
    --continuous ||
    exit
echo "================================================================="

echo -e "\n"
echo "back_jump_prob_discrete.py"
echo "================================================================="
${py_exe} -u \
    "${mdt_path}/scripts/discretization/back_jump_prob_discrete.py" \
    --f1 "${infile1}" \
    --f2 "${infile2}" \
    -o "${settings}_${system}_${analysis}_discard-neg.txt.gz" \
    --norm-out "${settings}_${system}_${analysis}_discard-neg_norm.txt.gz" \
    -b "0" \
    -e "-1" \
    --every "1" \
    --discard-neg ||
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
        "${settings}_${system}_${analysis}_discard-neg.txt.gz" \
        "${settings}_${system}_${analysis}_discard-neg_norm.txt.gz" \
        "${settings}_${system}_${analysis}_discard-neg_continuous.txt.gz" \
        "${settings}_${system}_${analysis}_discard-neg_continuous_norm.txt.gz" \
        "${settings}_${system}_${analysis}_slurm-${SLURM_JOB_ID}.out" \
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
