#!/bin/bash

module load palma/2019a || exit
module load GCC/8.2.0-2.31.1 || exit
module load OpenMPI/3.1.3 || exit
module load GROMACS/2018.8 || exit

if [[ ${SLURM_JOB_PARTITION} == *gpu* ]]; then
    echo
    echo "WARNING: You cannot make use of the GPUs on the allocated node,"
    echo "because the loaded Gromacs version was compiled without GPU support."
fi
