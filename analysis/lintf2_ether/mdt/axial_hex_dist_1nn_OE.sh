#!/bin/bash

#SBATCH --time=0-06:00:00
#SBATCH --job-name="mdt_axial_hex_dist_1nn_OE"
#SBATCH --output="mdt_axial_hex_dist_1nn_OE_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=512M
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_mdt_analyses_lintf2_ether.py

analysis="axial_hex_dist_1nn_OE"
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
zmin=${10}    # Only atoms in a slab in the xy-plane between zmin
zmax=${11}    # and zmax are considered (in Angstrom)

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
echo "zmin     = ${zmin}"
echo "zmax     = ${zmax}"

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
# Load required executable(s)                                          #
########################################################################

# shellcheck source=/dev/null
source "${bash_dir}/load_python.sh" "${py_lmod}" "${py_exe}" || exit

########################################################################
# Start the Analysis                                                   #
########################################################################

if (($(echo "${zmax} < 50.0" | bc || exit))); then
    electrode="B1"
else
    electrode="T1"
fi

echo -e "\n"
echo "=================================================================="
${py_exe} -u \
    "${mdt_path}/scripts/structure/axial_hex_distribution_1nn.py" \
    -f "${settings}_out_${system}_pbc_whole_mol.xtc" \
    -s "${settings}_${system}.tpr" \
    -o "${settings}_${system}_${analysis}_${zmin}-${zmax}A.txt.gz" \
    -b "${begin}" \
    -e "${end}" \
    --every "${every}" \
    --sel "type OE" \
    --surf "resname ${electrode}" \
    --r0 "1.42" \
    --zmin "${zmin}" \
    --zmax "${zmax}" ||
    exit
echo "=================================================================="

########################################################################
# Cleanup                                                              #
########################################################################

echo -e "\n"
mv -v \
    "${settings}_${system}_${analysis}_slurm-${SLURM_JOB_ID}.out" \
    "${settings}_${system}_${analysis}_${zmin}-${zmax}A_slurm-${SLURM_JOB_ID}.out"

save_dir="${analysis}_${zmin}-${zmax}A_slurm-${SLURM_JOB_ID}"
if [[ ! -d ${save_dir} ]]; then
    echo -e "\n"
    mkdir -v "${save_dir}" || exit
    mv -v \
        "${settings}_${system}_${analysis}_${zmin}-${zmax}A.txt.gz" \
        "${settings}_${system}_${analysis}_${zmin}-${zmax}A_slurm-${SLURM_JOB_ID}.out" \
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
