#!/bin/bash

module load palma/2020b || exit
module load iccifort/2020.4.304 || exit
module load impi/2019.9.304 || exit
module load GROMACS/2018.8 || exit

if [[ ${SLURM_JOB_PARTITION} == *gpu* ]]; then
    echo
    echo "WARNING: You cannot make use of the GPUs on the allocated node,"
    echo "because the loaded Gromacs version was compiled without GPU support."
fi
