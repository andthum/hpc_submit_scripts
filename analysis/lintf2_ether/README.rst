Sbatch scripts to submit jobs to the Slurm Workload Manager on the
PALMA II computing cluster of the University of Münster or on the
Bagheera computing cluster of the work group of Professor Heuer.

The sbatch scripts in this directory may call the following bash scripts:

    * print_slurm_environment_variables.sh
    * date_time_diff.sh
    * gmx_get_last_time.sh
    * gmx_get_box_lengths.sh

Things that other users of the scripts have to change:

    * Mail address: Change "a_thum01" to your username. This has to be
      done in all sbatch scripts. The line to change is

      .. code-block:: bash

          #SBATCH --mail-user=a_thum01@uni-muenster.de

    * Path to related bash scripts: Give the path where you store the
      above mentioned bash scripts. This has to be done in all sbatch
      scripts and in the submit script. The line to change is

      .. code-block:: bash

          dir_bash_scripts="${HOME}/Promotion/scripts/bash"
