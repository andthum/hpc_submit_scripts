#!/bin/bash

#SBATCH --time=0-00:20:00
#SBATCH --job-name="gmx_make_ndx"
#SBATCH --output="gmx_make_ndx_slurm-%j.out"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=512M
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by
# submit_gmx_analyses_lintf2_ether.py

analysis="make_ndx"
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

echo -e "\n"
echo "Parsed arguments:"
echo "bash_dir = ${bash_dir}"
echo "gmx_lmod = ${gmx_lmod}"
echo "gmx_exe  = ${gmx_exe}"
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
# Generate System-Specific Variables                                   #
########################################################################

salt=${system%%_*}
# cation=${salt:0:2}
anion=${salt:2}
solvent=${system#*_}
solvent=${solvent%%_*}
if [[ ${solvent} == peo* ]]; then
    solvent=peo
fi

########################################################################
# Load required executable(s)                                          #
########################################################################

# shellcheck source=/dev/null
source "${bash_dir}/load_gmx.sh" "${gmx_lmod}" "${gmx_exe}" || exit

########################################################################
# Start the Analysis                                                   #
########################################################################

# Availabe Index Groups in Li[NTf2]-<ETHER> Mixtures
# ==================================================
#
# <ETHER> = Linear poly(ethylene oxides) of arbitrary length (including
# dimethyl ether)
#
#
# Li[NTf2]-<ETHER> Mixtures Without Graphene Electrodes
# -----------------------------------------------------
#
# Available static index groups (default groups):
#   Group  0 System
#   Group  1 Ion
#   Group  2 li
#   Group  3 ntf2
#   Group  4 <ether>
#   Group  5 Other
#   Group  6 li
#   Group  7 ntf2
#   Group  8 <ether>
# Aditional static index groups when supplying the .ndx file created
# below:
#   Group  9 NTF2_&_N*
#   Group 10 NTF2_&_O*
#   Group 11 NTF2_&_S*
#   Group 12 NTF2_&_C*
#   Group 13 NTF2_&_F*
#   Group 14 <ETHER>_&_O*
#   Group 15 <ETHER>_&_C*
#   Group 16 <ETHER>_&_H*
#   Group 17 <ETHER>_&_!H*
#
#
# Li[NTf2]-<ETHER> Mixtures With Graphene Electrodes
# --------------------------------------------------
#
# Available static index groups (default groups):
#   Group  0 System
#   Group  1 Ion
#   Group  2 li
#   Group  3 ntf2
#   Group  4 <ether>
#   Group  5 B3
#   Group  6 B2
#   Group  7 B1
#   Group  8 T1
#   Group  9 T2
#   Group 10 T3
#   Group 11 Other
#   Group 12 li
#   Group 13 ntf2
#   Group 14 <ether>
#   Group 15 B3
#   Group 16 B2
#   Group 17 B1
#   Group 18 T1
#   Group 19 T2
#   Group 20 T3
# Aditional static index created before starting the production run:
#   Group 21 graB
#   Group 22 graT
#   Group 23 electrodes
#   Group 24 electrolyte
# Aditional static index groups when supplying the .ndx file created
# below:
#   Group 25 NTF2_&_N*
#   Group 26 NTF2_&_O*
#   Group 27 NTF2_&_S*
#   Group 28 NTF2_&_C*
#   Group 29 NTF2_&_F*
#   Group 30 <ETHER>_&_O*
#   Group 31 <ETHER>_&_C*
#   Group 32 <ETHER>_&_H*
#   Group 33 <ETHER>_&_!H*

gmx_make_ndx="${gmx_exe} make_ndx \
    -f ${settings}_${system}.tpr \
    -o ${system}.ndx"
if [[ -f ${system}.ndx ]]; then
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    echo -e "\n"
    mv -v "${system}.ndx" "${system}_${timestamp}.ndx" || exit
    gmx_make_ndx="${gmx_make_ndx} -n ${system}_${timestamp}.ndx"
fi

echo -e "\n"
echo "================================================================="
echo -e "r ${anion}   &   a N* \n
         r ${anion}   &   a O* \n
         r ${anion}   &   a S* \n
         r ${anion}   &   a C* \n
         r ${anion}   &   a F* \n
         r ${solvent} &   a O* \n
         r ${solvent} &   a C* \n
         r ${solvent} &   a H* \n
         r ${solvent} & ! a H* \n
         q" |
    ${gmx_make_ndx} || exit
echo "================================================================="

########################################################################
# Cleanup                                                              #
########################################################################

save_dir="${analysis}_slurm-${SLURM_JOB_ID}"
if [[ ! -d ${save_dir} ]]; then
    echo -e "\n"
    mkdir -v "${save_dir}" || exit
    mv -v \
        "${settings}_${system}_${analysis}_slurm-${SLURM_JOB_ID}.out" \
        "${save_dir}"
    cp -v "${system}.ndx" "${save_dir}"
    if [[ -f ${system}_${timestamp}.ndx ]]; then
        cp -v "${system}_${timestamp}.ndx" "${save_dir}"
    fi
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
