.. role:: bash(code)
    :language: bash


##################
HPC Submit Scripts
##################

|CodeQL_Status| |pre-commit.ci_status| |pre-commit| |MIT_License|
|Made_with_Bash| |Made_with_Python| |Code_style_black|

|logo|

.. contents:: Site Contents
    :depth: 2


Introduction
============

This project contains scripts that I use to run and analyse Molecular
Dynamics (MD) simulations on High Performance Computers (HPCs).  Most of
the scripts are job scripts for the Slurm_ (Simple Linux Utility for
Resource Management) workload manager.

The scripts of this project are designed to run on the Palma2_
(Paralleles Linux-System für Münsteraner Anwender) HPC cluster of the
University of Münster and on the Bagheera_ HPC cluster of the
`research group of Professor Heuer`_.  However, it should be easy to
adopt them to your HPC system.


Project Tree / Contents
=======================

    * :bash:`analysis`:  Slurm job scripts to analyze MD simulations.
    * :bash:`bash`:  Standalone Bash script that are used by some of the
      Slurm job scripts.
    * :bash:`img`:  Image files for use in the documentation.
    * :bash:`lmod`:  Bash scripts that can be sourced to load Lmod_
      modules into the current shell.
    * :bash:`python`:  Python modules containig functions and classes
      that are used by the Python submit scripts.
    * :bash:`simulation`:  Slurm job scripts to run MD simulations.

Refer to the README's of the different subdirectories for further
details.

The Slurm job scripts can conveniently be submitted via Python_ scripts
that reside in the same subdirectory as the job scripts.  Python scripts
that submit Slurm job scripts to the Slurm Workload Manager start with
:bash:`submit_*.py`.  For help how to use these scripts type
:bash:`python3 path/to/the/script.py -h` in a terminal or read the
docstring inside the script.


Prerequisites
=============

    * Bash shell.
    * Python_ 3 for the Python submit scripts.
    * Slurm_ for the Slurm job scripts.  If you run the scripts on
      another HPC cluster than Palma2 or Bagheera, you need to modify
      the parts of the job scripts where the cluster name is checked.
      Search for :bash:`${SLURM_CLUSTER_NAME}` to find these parts.
    * Lmod_ (optional).


Installation
============

No installation required, simply clone the project to any location on
your computer:

.. code-block:: bash

    git clone https://github.com/andthum/hpc_submit_scripts.git

If you want you can make the Python submit scripts executable with
:bash:`chmod u+x path/to/the/script.py` and add them to your PATH
variable.  Then you can simply call the scripts directly instead of
having to type :bash:`python3 path/to/the/script.py`.

To get the latest changes, simply do

.. code-block:: bash

    cd path/to/hpc_submit_scripts
    git pull

You may want to change the default settings of the Python submit
scripts.  For example, you may want to set the default for the
--mail-user option to your mail adress.


Usage
=====

Use the corresponding Python submit scripts to submit the desired Slurm
jobs scripts to the Slurm Workload Manager.


HPC Terminology
===============

For all newcomers to high-performance computing (especially our Bachelor
Students):  You might want to take a look at
`TERMINOLOGY.rst <./TERMINOLOGY.rst>`_ to get an overview of the
different terms used in the context of HPC.


Support
=======

If you have any questions, feel free to use the `Question&Answer`_ forum
on GitHub_.  If you encounter a bug or want to request a new feature,
please `open a new issue`_.


Contributing
============

Please see `CONTRIBUTING.rst <./CONTRIBUTING.rst>`_ for a list of rules
to follow when contributing to this project.


License
=======

The scripts are distributed under the `MIT License`_.  Feel free to use
the scripts or adopt them to your needs.


.. _Slurm: https://slurm.schedmd.com/
.. _Palma2: https://confluence.uni-muenster.de/display/HPC/High+Performance+Computing
.. _Bagheera: https://sso.uni-muenster.de/ZIVwiki/bin/view/AKHeuer/BagheeraInfos
.. _research group of Professor Heuer: https://www.uni-muenster.de/Chemie.pc/en/forschung/heuer/index.html
.. _Lmod: https://lmod.readthedocs.io/en/latest/index.html
.. _Python: https://www.python.org/
.. _Question&Answer: https://github.com/andthum/hpc_submit_scripts/discussions/categories/q-a
.. _GitHub: https://github.com/
.. _open a new issue: https://github.com/andthum/hpc_submit_scripts/issues
.. _MIT License: https://mit-license.org/

.. |logo| image:: ./img/logo.png
    :height: 400 px
    :alt: Logo

.. |CodeQL_Status| image:: https://github.com/andthum/hpc_submit_scripts/actions/workflows/codeql-analysis.yml/badge.svg
    :alt: CodeQL Status
    :target: https://github.com/andthum/hpc_submit_scripts/actions/workflows/codeql-analysis.yml
.. |pre-commit.ci_status| image:: https://results.pre-commit.ci/badge/github/andthum/hpc_submit_scripts/main.svg
    :alt: pre-commit.ci status
    :target: https://results.pre-commit.ci/latest/github/andthum/hpc_submit_scripts/main
.. |pre-commit| image:: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white
    :alt: pre-commit
    :target: https://github.com/pre-commit/pre-commit
.. |MIT_License| image:: https://img.shields.io/badge/License-MIT-blue.svg
    :alt: MIT License
    :target: https://mit-license.org/
.. |Made_with_Bash| image:: https://img.shields.io/badge/Made%20with-Bash-1f425f.svg
    :alt: Made with Bash
    :target: https://www.gnu.org/software/bash/
.. |Made_with_Python| image:: https://img.shields.io/badge/Made%20with-Python-1f425f.svg
    :alt: Made with Python
    :target: https://www.python.org/
.. |Code_style_black| image:: https://img.shields.io/badge/code%20style-black-000000.svg
    :alt: Code style black
    :target: https://github.com/psf/black
