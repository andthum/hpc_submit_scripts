#!/bin/bash

module load palma/2019b || exit
module load GCC/8.3.0 || exit
module load OpenMPI/3.1.4 || exit
module load GROMACS/2019.6-PLUMED-2.6.4 || exit

if [[ ${SLURM_JOB_PARTITION} == *gpu* ]]; then
    echo
    echo "WARNING: You cannot make use of the GPUs on the allocated node,"
    echo "because the loaded Gromacs version was compiled without GPU support."
fi
