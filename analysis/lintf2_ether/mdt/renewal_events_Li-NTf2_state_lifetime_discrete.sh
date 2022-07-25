#!/bin/bash

#SBATCH --time=2-00:00:00
#SBATCH --job-name="mdt_renewal_events_Li-NTf2_state_lifetime_discrete"
#SBATCH --output="mdt_renewal_events_Li-NTf2_state_lifetime_discrete_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_mdt_analyses_lintf2_ether.py

analysis="renewal_events_Li-NTf2_state_lifetime_discrete"
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
restart=${7}  # Number of frames between restarting points

echo -e "\n"
echo "Parsed arguments:"
echo "bash_dir = ${bash_dir}"
echo "py_lmod  = ${py_lmod}"
echo "py_exe   = ${py_exe}"
echo "mdt_path = ${mdt_path}"
echo "system   = ${system}"
echo "settings = ${settings}"
echo "restart  = ${restart}"

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
echo "state_lifetime_discrete.py --continuous"
echo "================================================================="
${py_exe} -u \
    "${mdt_path}/scripts/discretization/state_lifetime_discrete.py" \
    --f1 "${settings}_${system}_renewal_events_Li-NTf2_dtrj.npy" \
    --f2 "${settings}_${system}_discrete-z_Li_dtrj.npy" \
    -o "${settings}_${system}_${analysis}_discard-neg-start_continuous.txt" \
    -b "0" \
    -e "-1" \
    --every "1" \
    --restart "${restart}" \
    --discard-neg-start \
    --continuous ||
    exit
echo "================================================================="

echo -e "\n"
echo "state_lifetime_discrete.py"
echo "================================================================="
${py_exe} -u \
    "${mdt_path}/scripts/discretization/state_lifetime_discrete.py" \
    --f1 "${settings}_${system}_renewal_events_Li-NTf2_dtrj.npy" \
    --f2 "${settings}_${system}_discrete-z_Li_dtrj.npy" \
    -o "${settings}_${system}_${analysis}_discard-neg-start.txt" \
    -b "0" \
    -e "-1" \
    --every "1" \
    --restart "${restart}" \
    --discard-neg-start ||
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
        "${settings}_${system}_${analysis}_discard-neg-start.txt" \
        "${settings}_${system}_${analysis}_discard-neg-start_continuous.txt" \
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
