#!/bin/bash

module load palma/2019a || exit
module load icc/2019.1.144-GCC-8.2.0-2.31.1 || exit
module load impi/2018.4.274 || exit
module load GROMACS/2016.6 || exit

if [[ ${SLURM_JOB_PARTITION} == *gpu* ]]; then
    echo
    echo "WARNING: You cannot make use of the GPUs on the allocated node,"
    echo "because the loaded Gromacs version was compiled without GPU support."
fi
