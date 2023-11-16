#!/bin/bash

#SBATCH --time=7-00:00:00
#SBATCH --job-name="gmx_rdf_slab-z_OE"
#SBATCH --output="gmx_rdf_slab-z_OE_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_gmx_analyses_lintf2_ether.py

analysis="rdf_slab-z_OE"
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
dt=${8}        # Only write frame when t MOD dt = first time
bin_width=${9} # Bin width in nm
zmin=${10}     # Only atoms in a slab in the xy-plane between zmin
zmax=${11}     # and zmax are considered (in nm)

echo -e "\n"
echo "Parsed arguments:"
echo "bash_dir  = ${bash_dir}"
echo "gmx_lmod  = ${gmx_lmod}"
echo "gmx_exe   = ${gmx_exe}"
echo "system    = ${system}"
echo "settings  = ${settings}"
echo "begin     = ${begin}"
echo "end       = ${end}"
echo "dt        = ${dt}"
echo "bin_width = ${bin_width}"
echo "zmin      = ${zmin}"
echo "zmax      = ${zmax}"

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
echo "OE-OE slab-z ${zmin}-${zmax} nm"
echo "================================================================="
${gmx_exe} rdf \
    -f "${settings}_out_${system}_pbc_whole_mol.xtc" \
    -s "${settings}_${system}.tpr" \
    -o "${settings}_${system}_${analysis}_${zmin}-${zmax}nm.xvg" \
    -cn "${settings}_${system}_cn${analysis}_${zmin}-${zmax}nm.xvg" \
    -b "${begin}" \
    -e "${end}" \
    -dt "${dt}" \
    -bin "${bin_width}" \
    -xy \
    -ref "atomtype OE and (z >= ${zmin} and z < ${zmax})" \
    -sel "atomtype OE and (z >= ${zmin} and z < ${zmax})" ||
    exit
echo "================================================================="

########################################################################
# Compress output file(s)                                              #
########################################################################

echo -e "\n"
echo "Compressing output file(s)..."
gzip --best --verbose "${settings}_${system}_${analysis}_${zmin}-${zmax}nm.xvg" || exit
gzip --best --verbose "${settings}_${system}_cn${analysis}_${zmin}-${zmax}nm.xvg" || exit

########################################################################
# Cleanup                                                              #
########################################################################

echo -e "\n"
mv -v \
    "${settings}_${system}_${analysis}_slurm-${SLURM_JOB_ID}.out" \
    "${settings}_${system}_${analysis}_${zmin}-${zmax}nm_slurm-${SLURM_JOB_ID}.out"

save_dir="${analysis}_${zmin}-${zmax}nm_slurm-${SLURM_JOB_ID}"
if [[ ! -d ${save_dir} ]]; then
    echo -e "\n"
    mkdir -v "${save_dir}" || exit
    mv -v \
        "${settings}_${system}_${analysis}_${zmin}-${zmax}nm.xvg.gz" \
        "${settings}_${system}_cn${analysis}_${zmin}-${zmax}nm.xvg.gz" \
        "${settings}_${system}_${analysis}_${zmin}-${zmax}nm_slurm-${SLURM_JOB_ID}.out" \
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
