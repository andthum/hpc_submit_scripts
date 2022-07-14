#!/bin/bash

#SBATCH --time=2-00:00:00
#SBATCH --job-name="mdt_discrete-hex_OBT"
#SBATCH --output="mdt_discrete-hex_OBT_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_mdt_analyses_lintf2_ether.py

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
zmin=${12}    # Only atoms in a slab in the xy-plane between zmin
zmax=${13}    # and zmax are considered (in Angstrom)

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
# Start the Analysis                                                   #
########################################################################

# shellcheck source=/dev/null
source "${bash_dir}/load_python.sh" "${py_lmod}" "${py_exe}" || exit

if (($(echo "${zmax} < 50.0" | bc || exit))); then
    electrode="B1"
else
    electrode="T1"
fi

echo -e "\n"
echo "discrete_hex.py"
echo "OBT ${zmin}-${zmax} A"
echo "================================================================="
${py_exe} -u \
    "${mdt_path}/scripts/structure/discrete_hex.py" \
    -f "${settings}_out_${system}_pbc_whole_mol.xtc" \
    -s "${settings}_${system}.tpr" \
    -o "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A" \
    -b "${begin}" \
    -e "${end}" \
    --every "${every}" \
    --sel "type OBT" \
    --surf "resname ${electrode}" \
    --flat-side "x" \
    --zmin "${zmin}" \
    --zmax "${zmax}" \
    --r0 "1.42" ||
    exit
echo "================================================================="

if [[ -f ${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_traj.npy ]]; then
    echo -e "\n"
    mv -v \
        "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_traj.npy" \
        "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_dtrj.npy"
fi

echo -e "\n"
echo "state_lifetime.py --continuous"
echo "================================================================="
${py_exe} -u \
    "${mdt_path}/scripts/discretization/state_lifetime.py" \
    -f "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_dtrj.npy" \
    -o "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_state_lifetime_discard-all-neg_continuous.txt" \
    -b "0" \
    -e "-1" \
    --every "1" \
    --nblocks "${nblocks}" \
    --restart "${restart}" \
    --discard-all-neg \
    --continuous ||
    exit
echo "================================================================="

echo -e "\n"
echo "state_lifetime.py"
echo "================================================================="
${py_exe} -u \
    "${mdt_path}/scripts/discretization/state_lifetime.py" \
    -f "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_dtrj.npy" \
    -o "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_state_lifetime_discard-all-neg.txt" \
    -b "0" \
    -e "-1" \
    --every "1" \
    --nblocks "${nblocks}" \
    --restart "${restart}" \
    --discard-all-neg ||
    exit
echo "================================================================="

########################################################################
# Cleanup                                                              #
########################################################################

save_dir="discrete-hex_OBT_${zmin}-${zmax}A_slurm-${SLURM_JOB_ID}"
if [[ ! -d ${save_dir} ]]; then
    echo -e "\n"
    mkdir -v "${save_dir}" || exit
    mv -v \
        "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_lattice_faces.npy" \
        "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_lattice_vertices.npy" \
        "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_dtrj.npy" \
        "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_slurm-${SLURM_JOB_ID}.out" \
        "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_state_lifetime_discard-all-neg.txt" \
        "${settings}_${system}_discrete-hex_OBT_${zmin}-${zmax}A_state_lifetime_discard-all-neg_continuous.txt" \
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
