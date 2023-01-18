.. Keep REAMDE.rst synchronized with index.rst (documentation)


##########################
HPC Submit Scripts (hpcss)
##########################

|pre-commit| |pre-commit.ci_status| |Test_Status| |CodeQL_Status|
|Documentation_Status| |License_MIT| |Made_with_Bash| |Made_with_Python|
|Code_style_black| |Made_with_Sphinx| |Doc_style_numpy|

|logo|

.. contents:: Site Contents
    :depth: 2
    :local:


Introduction
============

This project contains job and submit scripts to run and analyze
Molecular Dynamics (MD) simulations on High Performance Computing (HPC)
clusters.  Most of the scripts are job scripts for the Slurm_ (Simple
Linux Utility for Resource Management) Workload Manager.

This project only contains batch scripts and Python scripts that submit
these batch scripts to Slurm.  It does **not** contain the actual
simulation and analysis software that is evoked in the batch scripts!

The scripts of this project are designed to run on the Palma2_
("Paralleles Linux-System für Münsteraner Anwender") HPC cluster of the
University of Münster and on the Bagheera_ HPC cluster of the
`research group of Professor Heuer`_.  However, it should be easy to
adopt them to any other HPC system that runs Slurm if needed.


Documentation
=============

The complete documentation of hpcss including installation_ and usage_
instructions can be found
`here <https://hpcss.readthedocs.io/en/latest/>`_.


Support
=======

If you have any questions, feel free to use the `Question&Answer`_ forum
on GitHub_.  If you encounter a bug or want to request a new feature,
please open a new Issue_.


License
=======

hpcss is free software: you can redistribute it and/or modify it under
the terms of the `MIT License`_.

hpcss is distributed in the hope that it will be useful, but
**WITHOUT WARRANTY OF ANY KIND**.  See the `MIT License`_ for more
details.


.. _Slurm: https://slurm.schedmd.com/
.. _Palma2:
    https://confluence.uni-muenster.de/display/HPC/High+Performance+Computing
.. _Bagheera:
    https://sso.uni-muenster.de/ZIVwiki/bin/view/AKHeuer/BagheeraInfos
.. _research group of Professor Heuer:
    https://www.uni-muenster.de/Chemie.pc/en/forschung/heuer/index.html
.. _installation:
    https://hpcss.readthedocs.io/en/latest/doc_pages/general/installation.html
.. _usage: https://hpcss.readthedocs.io/en/latest/doc_pages/general/usage.html
.. _Question&Answer:
    https://github.com/andthum/hpc_submit_scripts/discussions/categories/q-a
.. _GitHub: https://github.com/
.. _Issue: https://github.com/andthum/hpc_submit_scripts/issues
.. _MIT License: https://mit-license.org/

.. |logo| image:: docs/logo/hpcss_logo_744x1012.png
    :height: 300 px
    :alt: Logo

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
