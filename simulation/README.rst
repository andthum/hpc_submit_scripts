.. role:: bash(code)
    :language: bash


##########################
Scripts to Run Simulations
##########################

Slurm job scripts to run MD simulations.

The Slurm job scripts can conveniently be submitted via Python scripts
that reside in the same subdirectory as the job scripts.  Python scripts
that submit Slurm job scripts to the Slurm Workload Manager start with
:bash:`submit_*.py`.  For help how to use these scripts type
:bash:`python3 path/to/the/script.py -h` in a terminal or read the
documentation of the script.


Directory Tree / Contents
=========================

    * :bash:`gmx`:  Scripts to run simulations with Gromacs_.


.. _Gromacs: https://www.gromacs.org/
