#!/bin/bash

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

# This script can be sourced in Slurm batch scripts to get access to
# the Gromacs executable.

gmx_lmod=${1}
gmx_exe=${2}

if [[ -z ${SLURM_CLUSTER_NAME} ]]; then
    echo
    echo "ERROR: The environment variable SLURM_CLUSTER_NAME is not assigned"
    exit 1
fi

if [[ ${SLURM_CLUSTER_NAME} == palma2 ]]; then
    if [[ ! -f ${gmx_lmod} ]]; then
        echo
        echo "ERROR: Cannot load Gromacs.  No such file: '${gmx_lmod}'"
        exit 1
    fi
    module --force purge || exit
    # shellcheck source=/dev/null
    source "${gmx_lmod}" || exit
    echo
    module list
elif [[ ${SLURM_CLUSTER_NAME} != bagheera ]]; then
    echo
    echo "ERROR: Unkown cluster name '${SLURM_CLUSTER_NAME}'"
    exit 1
fi

echo
echo "Gromacs executable:"
which "${gmx_exe}" || exit
