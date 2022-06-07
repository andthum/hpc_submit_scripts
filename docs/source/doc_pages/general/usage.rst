.. _usage-label:

Usage
=====

The usage of hpcss is rather simple.  Just select the |Slurm| job script
you want to run and submit it to the Slurm Workload Manager with the
corresponding |Python| submit script.

Python scripts that submit Slurm job scripts to the Slurm Workload
Manager reside in the same directory as the job scripts and start with
:bash:`submit_*.py`.  All (documented) Python submit scripts are listed
in the :ref:`submit-scripts-label` section.

.. contents:: Site Contents
    :depth: 2
    :local:


Project Structure
-----------------

How to find a suitable Slurm job script?  How is this project
structured?

The two main directories that contain Slurm job scripts are
:file:`simulation` and :file:`analysis`.  As the names suggests,
:file:`simulation` contains job scripts that run the actual simulations
and :file:`analysis` contains job scripts that run analysis tasks.  The
corresponding Python submit scripts reside in the same directory as the
Slurm job scripts that they submit.

.. list-table:: Top-Level Directories
    :align: left
    :widths: auto

    * - :file:`analysis`
      - Slurm job scripts to analyze MD simulations and their
        corresponding Python submit scripts.
    * - :file:`bash`
      - Standalone Bash scripts that are used by some of the Slurm job
        scripts.
    * - :file:`docs`
      - Directory containing this documentation.
    * - :file:`lmod`
      - Bash scripts that can be sourced to load |Lmod| modules into the
        current shell.
    * - :file:`python`
      - Python modules that are used by some of the Python submit
        scripts.
    * - :file:`simulation`
      - Slurm job scripts to run MD simulations and their corresponding
        Python submit scripts.

Each top-level directory should contain a :file:`README` file that
explains the contents and the structure of this directory.

.. important::

    You should not change the directory structure or move scripts
    around, because the scripts call and import other scripts based on
    relative paths.


The :file:`lmod` Directory
--------------------------

If you are submitting jobs on |Palma2|, another important directory
besides :file:`simulation` and :file:`analysis` is :file:`lmod`.  This
directory contains Bash scripts that can be sourced to load the required
|Lmod| modules for your job.  By selecting the corresponding Lmod source
script, you can specify which version of a software package to use for
your simulation or analysis.  For example
:file:`lmod/palma/2019a/gmx2018-8_foss` loads Gromacs 2018.8 compiled
and linked with free and open source software (foss), whereas
:file:`lmod/palma/2020a/gmx2020-1_foss` loads Gromacs 2020.1.


How to Run the Python Submit Scripts?
-------------------------------------

You can run the Python scripts simply by:

.. code-block:: bash

    python3 path/to/script.py

If you have made the scripts executable with

.. code-block:: bash

    chmod u+x path/to/script.py

you can also run the scripts in the following way:

.. code-block:: bash

    path/to/script.py


Examples
--------

.. todo::

    Give one or more examples how to use the scripts.
