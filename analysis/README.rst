.. role:: bash(code)
    :language: bash


################
Analysis Scripts
################

Slurm job scripts to analyse MD simulations.

The Slurm job scripts can conveniently be submitted via Python scripts
that reside in the same subdirectory as the job scripts.  Python scripts
that submit Slurm job scripts to the Slurm Workload Manager start with
:bash:`submit_*.py`.  For help how to use these scripts type
:bash:`python3 path/to/the/script.py -h` in a terminal or read the
documentation of the script.


Directory Tree / Contents
=========================

    * :bash:`lintf2_ether`:  Slurm job scripts to analyse MD simulations
      of LiTFSI-Ether electrolytes.

Refer to the README's of the different subdirectories for further
details.
