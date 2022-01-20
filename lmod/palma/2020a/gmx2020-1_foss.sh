#!/bin/bash

module load palma/2020a || exit
module load GCC/9.3.0 || exit
module load OpenMPI/4.0.3 || exit
module load GROMACS/2020.1-Python-3.8.2 || exit

if [[ ${SLURM_JOB_PARTITION} == *gpu* ]]; then
    echo
    echo "WARNING: You cannot make use of the GPUs on the allocated node,"
    echo "because the loaded Gromacs version was compiled without GPU support."
fi
