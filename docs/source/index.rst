.. Keep index.rst synchronized with README.rst


##########################################################
Welcome to the Documentation of HPC Submit Scripts (hpcss)
##########################################################

:Release: |release|
:Date: |today|

|pre-commit| |pre-commit.ci_status| |Test_Status| |CodeQL_Status|
|Documentation_Status| |License_MIT| |DOI| |Made_with_Bash|
|Made_with_Python| |Code_style_black| |Made_with_Sphinx|
|Doc_style_numpy|

.. contents:: Site Contents
    :depth: 2
    :local:


Introduction
============

This project contains job and submit scripts to run and analyze
Molecular Dynamics (MD) simulations on High Performance Computing (HPC)
clusters.  Most of the scripts are job scripts for the |Slurm| (Simple
Linux Utility for Resource Management) Workload Manager.

This project only contains batch scripts and Python scripts that submit
these batch scripts to Slurm.  It does **not** contain the actual
simulation and analysis software that is evoked in the batch scripts!

The scripts of this project are designed to run on the |Palma2|
("Paralleles Linux-System für Münsteraner Anwender") HPC cluster of the
University of Münster and on the |Bagheera| HPC cluster of the
|RG_of_Professor_Heuer|.  However, it should be easy to adopt them to
any other HPC system that runs Slurm if needed.

.. note::

    Currently, this project is mainly intended for my personal use and
    will evolve according to my personal needs.  However, everybody is
    welcome to use it and to contribute to it and to write scripts for
    his/her own purposes.  If you want to contribute, please read the
    |dev_guide|.

.. warning::

    The scripts and functions are **not** (extensively) tested!

.. toctree::
    :caption: Table of Contents
    :name: mastertoc
    :maxdepth: 1
    :hidden:
    :titlesonly:
    :glob:

    doc_pages/general/installation
    doc_pages/general/usage
    doc_pages/general/config_file
    doc_pages/general/sbatch_options
    doc_pages/general/hpc_terminology
    doc_pages/submit_scripts
    doc_pages/pymodules
    doc_pages/dev_guide/dev_guide


Why Using hpcss?
================

Benefits of hpcss:

    * Automatically resubmit MD simulations that take longer than the
      maximum allowed time limit by Slurm.
    * Submit many (or even all) analysis tasks at once while respecting
      their interconnections and dependencies.
    * Check for required input files *before* submitting jobs to Slurm
      so that jobs will not fail anymore because of missing input files.
    * Have all your Slurm job scripts at one place instead of having
      them scattered around in your different project directories.
    * Automatically adapt the Slurm job scripts to other systems or
      simulation settings.  No need to manually change file names in
      Slurm job scripts anymore.


Getting Started
===============

Installation instructions are given in the :ref:`installation-label`
section.  The basic usage of the scripts is described in the
:ref:`usage-label` section.


Support
=======

If you have any questions, feel free to use the |Q&A| forum on |GitHub|.
If you encounter a bug or want to request a new feature, please open a
new |Issue|.


Contributing
============

If you want to contribute to the project, please read the |dev_guide|.


Source Code
===========

Source code is available from
https://github.com/andthum/hpc_submit_scripts under the |MIT_License|.
You can download or clone the repository with |Git|:

.. code-block:: bash

    git clone https://github.com/andthum/hpc_submit_scripts.git


License
=======

hpcss is free software: you can redistribute it and/or modify it under
the terms of the |MIT_License|.

hpcss is distributed in the hope that it will be useful, but
**WITHOUT WARRANTY OF ANY KIND**.  See the |MIT_License| for more
details.


Indices and Tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`


.. |pre-commit| image:: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white
    :alt: pre-commit
    :target: https://github.com/pre-commit/pre-commit
.. |pre-commit.ci_status| image:: https://results.pre-commit.ci/badge/github/andthum/hpc_submit_scripts/main.svg
    :alt: pre-commit.ci status
    :target: https://results.pre-commit.ci/latest/github/andthum/hpc_submit_scripts/main
.. |Test_Status| image:: https://github.com/andthum/hpc_submit_scripts/actions/workflows/tests.yml/badge.svg
    :alt: Test Status
    :target: https://github.com/andthum/hpc_submit_scripts/actions/workflows/tests.yml
.. |CodeQL_Status| image:: https://github.com/andthum/hpc_submit_scripts/actions/workflows/codeql-analysis.yml/badge.svg
    :alt: CodeQL Status
    :target: https://github.com/andthum/hpc_submit_scripts/actions/workflows/codeql-analysis.yml
.. |Documentation_Status| image:: https://readthedocs.org/projects/hpcss/badge/?version=latest
    :alt: Documentation Status
    :target: https://hpcss.readthedocs.io/en/latest/?badge=latest
.. |License_MIT| image:: https://img.shields.io/badge/License-MIT-blue.svg
    :alt: MIT License
    :target: https://mit-license.org/
.. |DOI| image:: https://zenodo.org/badge/447523192.svg
    :alt: DOI
    :target: https://zenodo.org/doi/10.5281/zenodo.10154885
.. |Made_with_Bash| image:: https://img.shields.io/badge/Made%20with-Bash-1f425f.svg
    :alt: Made with Bash
    :target: https://www.gnu.org/software/bash/
.. |Made_with_Python| image:: https://img.shields.io/badge/Made%20with-Python-1f425f.svg
    :alt: Made with Python
    :target: https://www.python.org/
.. |Code_style_black| image:: https://img.shields.io/badge/code%20style-black-000000.svg
    :alt: Code style black
    :target: https://github.com/psf/black
.. |Made_with_Sphinx| image:: https://img.shields.io/badge/Made%20with-Sphinx-1f425f.svg
    :alt: Made with Sphinx
    :target: https://www.sphinx-doc.org/
.. |Doc_style_numpy| image:: https://img.shields.io/badge/%20style-numpy-459db9.svg
    :alt: Style NumPy
    :target: https://numpydoc.readthedocs.io/en/latest/format.html
