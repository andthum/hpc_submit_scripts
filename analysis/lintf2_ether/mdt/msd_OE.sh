#!/bin/bash

#SBATCH --time=1-00:00:00
#SBATCH --job-name="mdt_msd_OE"
#SBATCH --output="mdt_msd_OE_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_mdt_analyses_lintf2_ether.py

analysis="msd_OE"
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
begin=${7}    # First frame to read.  Frame numbering starts at 0
end=${8}      # Last frame to read (exclusive)
every=${9}    # Read every n-th frame
nblocks=${10} # Number of blocks for block averaging
restart=${11} # Number of frames between restarting points

echo -e "\n"
echo "Parsed arguments:"
echo "bash_dir = ${bash_dir}"
echo "py_lmod  = ${py_lmod}"
echo "py_exe   = ${py_exe}"
echo "mdt_path = ${mdt_path}"
echo "system   = ${system}"
echo "settings = ${settings}"
echo "begin    = ${begin}"
echo "end      = ${end}"
echo "every    = ${every}"
echo "nblocks  = ${nblocks}"
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
echo "OE"
echo "================================================================="
${py_exe} -u \
    "${mdt_path}/scripts/dynamics/msd_serial.py" \
    -f "${settings}_out_${system}_pbc_whole_mol_nojump.xtc" \
    -s "${settings}_${system}.tpr" \
    -o "${settings}_${system}_${analysis}.txt.gz" \
    -b "${begin}" \
    -e "${end}" \
    --every "${every}" \
    --nblocks "${nblocks}" \
    --restart "${restart}" \
    --sel "type OE" ||
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
        "${settings}_${system}_${analysis}.txt.gz" \
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
