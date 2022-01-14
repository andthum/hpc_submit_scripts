.. role:: bash(code)
    :language: bash


###################################
Scripts to Load Environment Modules
###################################

Some HPC clusters (like Palma2_) use the Lmod_ (or other) software to
manage the user environment.  The user environment determines which
programs are available to the user.

On HPC clusters that use Lmod, you typically have to load specific
modules before you can run a certain program.  Which modules to load and
how they are called depends on how you cluster administrator has set up
the Lmod module system.


Contents
========

This directory contains predefined bash scripts that can be used to load
specific modules to get access to specific software.  Note that the
scripts must be sourced to make the modules available in the parent
shell.

    * :bash:`palma`:  Bash scripts that load modules on the Palma2 HPC
      cluster of the University of Münster, ordered into subdirectories
      according to the different software stacks on Palma2 (refer to the
      `Palma2 Wiki`_ for more information about the module system on
      Palma2).


.. _Palma2: https://confluence.uni-muenster.de/display/HPC/High+Performance+Computing
.. _Lmod: https://lmod.readthedocs.io/en/latest/index.html
.. _Palma2 Wiki: https://confluence.uni-muenster.de/display/HPC/The+module+system
