.. role:: bash(code)
    :language: bash


################
Analysis Scripts
################

Slurm job scripts to analyse MD simulations.

The Slurm job scripts can conveniently be submitted via Python_ scripts
that reside in the same subdirectory as the job scripts.  Python scripts
that submit Slurm job scripts to the Slurm Workload Manager start with
:bash:`submit_*.py`.  For help how to use these scripts type
:bash:`python3 path/to/the/script.py -h` in a terminal or read the
docstring inside the script.

.. warning::

   **Work in Progress**

.. todo::

    * Rewrite Slurm job scripts.
    * Translate the Bash submit scripts to Python.


Contents
========

    * :bash:`lintf2_ether`:  Slurm job scripts to analyse MD simulations
      of LiTFSI-Ether electrolytes.
