#!/bin/bash

#SBATCH --time=2-00:00:00
#SBATCH --job-name="mdt_lig_change_at_pos_change_blocks_Li-OBT"
#SBATCH --output="mdt_lig_change_at_pos_change_blocks_Li-OBT_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=1G
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_mdt_analyses_lintf2_ether.py

analysis="lig_change_at_pos_change_blocks_Li-OBT"
thisfile=$(basename "${BASH_SOURCE[0]}")
echo "${thisfile}"
start_time=$(date --rfc-3339=seconds || exit)
echo "Start time = ${start_time}"

########################################################################
# Argument Parsing                                                     #
########################################################################

bash_dir=${1}        # Directory containing bash scripts used by this script
py_lmod=${2}         # File containing the modules to load Python
py_exe=${3}          # Name of the Python executable
mdt_path=${4}        # Path to the MDTools installation
system=${5}          # The name of the system to analyze
settings=${6}        # The used simulation settings
begin=${7}           # First frame to read.  Frame numbering starts at 0
end=${8}             # Last frame to read (exclusive)
every=${9}           # Read every n-th frame
cutoff=${10}         # Cutoff in Angstrom
lag_compare=${11}    # Lag time (in frames) after which to compare two quantities
min_block_size=${12} # Minimum valid block size (in frames)
max_gap_size=${13}   # Maximum allowed number of frames between blocks

echo -e "\n"
echo "Parsed arguments:"
echo "bash_dir       = ${bash_dir}"
echo "py_lmod        = ${py_lmod}"
echo "py_exe         = ${py_exe}"
echo "mdt_path       = ${mdt_path}"
echo "system         = ${system}"
echo "settings       = ${settings}"
echo "begin          = ${begin}"
echo "end            = ${end}"
echo "every          = ${every}"
echo "cutoff         = ${cutoff}"
echo "lag_compare    = ${lag_compare}"
echo "min_block_size = ${min_block_size}"
echo "max_gap_size   = ${max_gap_size}"

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
echo "=================================================================="
${py_exe} -u \
    "${mdt_path}/scripts/structure/lig_change_at_pos_change_blocks.py" \
    -f "${settings}_out_${system}_pbc_whole_mol.xtc" \
    -s "${settings}_${system}.tpr" \
    -o "${settings}_${system}_${analysis}.txt.gz" \
    -b "${begin}" \
    -e "${end}" \
    --every "${every}" \
    --ref "type Li" \
    --sel "type OBT" \
    --refcmp "atoms" \
    --selcmp "residues" \
    -c "${cutoff}" \
    --lag "${lag_compare}" \
    --min-block-size "${min_block_size}" \
    --max-gap-size "${max_gap_size}" \
    -d z \
    --bins "${settings}_${system}_density-z_number_Li_binsA.txt.gz" \
    --bins-out "${settings}_${system}_${analysis}_bins.txt.gz" ||
    exit
echo "=================================================================="

########################################################################
# Cleanup                                                              #
########################################################################

save_dir="${analysis}_slurm-${SLURM_JOB_ID}"
if [[ ! -d ${save_dir} ]]; then
    echo -e "\n"
    mkdir -v "${save_dir}" || exit
    mv -v \
        "${settings}_${system}_${analysis}.txt.gz" \
        "${settings}_${system}_${analysis}_bins.txt.gz" \
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
