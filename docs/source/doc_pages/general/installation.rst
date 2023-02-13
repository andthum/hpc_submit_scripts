.. _installation-label:

Installation
============

.. contents:: Site Contents
    :depth: 2
    :local:


Prerequisites
-------------

The following software is assumed to run on your target machine:

    * Bash shell.
    * |Python|\3.8 or higher for the Python submit scripts.
    * |Slurm| to submit the Slurm job scripts.  If you run the scripts
      on another HPC cluster than |Palma2| or |Bagheera|, you need to
      modify the parts of the job scripts where the cluster name is
      checked.  This is done in the :bash:`bash/load_*.sh` files.
    * Any software that is evoked in the Slurm job scripts you want to
      run.


Install
-------

No installation required, simply clone (or download) the project to any
location on your target machine:

.. code-block:: bash

    git clone https://github.com/andthum/hpc_submit_scripts.git

If you like, you can make the Python submit scripts executable with
:bash:`chmod u+x path/to/the/script.py` and add them to your
:bash:`${PATH}` variable.  Then you can simply call the scripts directly
instead of having to type :bash:`python3 path/to/the/script.py`.

To get the latest changes, simply do

.. code-block:: bash

    cd path/to/hpc_submit_scripts
    git pull

or re-download the project repository (if you don't use |Git|).

After cloning or pulling the repository, you may want to change the
default settings using a |config_file|.  For example, you may want to
set the default for the \--mail-user option of sbatch to your mail
address.


Development Installation
------------------------

See the :ref:`dev-install-label` section in the |dev_guide|.


Uninstall
---------

Simply remove the project directory:

.. code-block:: bash

    rm -r path/to/hpc_submit_scripts
