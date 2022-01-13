#!/bin/bash

# #SBATCH --account=q0heuer       # Charge resources used by this job to specified account
# #SBATCH --partition=q0heuer,hims,normal,express  # Request a specific partition for the resource allocation. A partition usually comprises multiple nodes
#SBATCH --time=0-00:15:00         # Total run time limit. The default time limit is the partition's default time limit
# #SBATCH --time-min=2-00:00:00   # Minimum time limit. If specified, the job may have it's --time limit lowered to a value not lower than --time-min
# #SBATCH --signal=INT@600        # When a job is within @[...] seconds of its end time, send it the signal [...]@

#SBATCH --job-name="make_ndx"             # Name for the job allocation
#SBATCH --output="make_ndx_slurm-%j.out"  # Filename to which standard output and error will be written
# #SBATCH --verbose               # Increase the information content of sbatch's messages. By default only errors will be displayed
#SBATCH --mail-type=FAIL          # Notify user by email when certain event types occur. Valid type values are NONE, BEGIN, END, FAIL, REQUEUE, ALL
#SBATCH --mail-user=a_thum01@uni-muenster.de  # User to receive email notification

#SBATCH --no-requeue              # The batch job should never be requeued under any circumstances
# #SBATCH --dependency=afterok:job_id[:jobid...]  # This job can begin execution after the specified job(s) have successfully executed
#SBATCH --kill-on-invalid-dep=yes # Cancel the job, if it has an invalid dependency and therefore can never run
# #SBATCH --test-only             # Validate the batch script and return an estimate of when a job would be scheduled to run

#SBATCH --nodes=1-1               # Number of requested nodes (min-max; if only one number is given, it is treated as min).
# #SBATCH --use-min-nodes         # If a range of node counts is given, prefer the smaller count
# #SBATCH --gres=gpu:2            # Specify generic consumable resources. Format "name[[:type]:count]"
# #SBATCH --constraint=avx2       # Only nodes which have the specified feature will be used
# #SBATCH --contiguous            # Allocated nodes must form a contiguous set (only meaningful if more than one node is allocated)
# #SBATCH --mincpus=1             # Specify a minimum number of logical CPUs/processors per node
# #SBATCH --exclusive             # Allocate the complete node.
# #SBATCH --ntasks=1              # Job steps run within the allocation can launch this maximum number of tasks (processes). Default: 1 task per node (--cpus-per-task can change this default). MPI ranks correspond to tasks.
# #SBATCH --ntasks-per-node=1     # Number of processes per node. If used with --ntasks, --ntasks will take precedence and --ntasks-per-node will be treated as a maximum count of tasks per node.
#SBATCH --cpus-per-task=1         # Number of threads per process (see example submission script http://www.ceci-hpc.be/slurm_faq.html)
# #SBATCH --threads-per-core=2    # Restrict node selection to nodes with at least the specified number of threads per core
# #SBATCH --mem=1G                # Required memory per node

# The above options are only default values, because options set with #SBATCH will be overwritten by the arguments that are parsed to sbatch


start_time=$(date -R)
timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"
thisfile=$(basename "${BASH_SOURCE}")

dir_bash_scripts="${HOME}/Promotion/scripts/bash"
if [ ! -d ${dir_bash_scripts} ]; then
    echo
    echo "Error: ${dir_bash_scripts} does not exist"
    exit 1
fi
export PATH=${PATH}:${dir_bash_scripts} || exit

echo "Start time              = ${start_time}"
echo
print_slurm_environment_variables.sh || exit


########################################################################
#                           Argument parsing                           #
########################################################################

system=${1}       # Pattern: <components>_<mixing ratio>_<charge scaling>
settings=${2}     # Pattern: <equilibration/production>_<ensemble><temperature>_<other settings like used thermostat and barostat>

echo -e "\n\n\n"
echo "Parsed arguments:"
echo "system   = ${system}"
echo "settings = ${settings}"


########################################################################
#                  Generate system specific variables                  #
########################################################################

salt=${system%%_*}
# cation=${salt:0:2}
anion=${salt:2}
solvent=${system#*_}
solvent=${solvent%%_*}
if [[ ${solvent} == peo* ]]; then
    solvent=peo
fi


########################################################################
#                        Load necessary modules                        #
########################################################################

if [[ ${SLURM_CLUSTER_NAME} == palma* ]]; then
    module purge || exit
    module load GCC/8.2.0-2.31.1 || exit
    module load OpenMPI/3.1.3 || exit
    module load GROMACS/2018.8 || exit
    echo -e "\n\n"
    module list
elif [[ ${SLURM_CLUSTER_NAME} == bagheera ]]; then
    source ${HOME}/usr/local/gromacs/bin/GMXRC || exit
else
    echo
    echo "Error: Unkown cluster name"
    echo "  SLURM_CLUSTER_NAME = ${SLURM_CLUSTER_NAME}"
    exit 1
fi

echo
echo "Executables:"
which gmx || exit


########################################################################
#                             Do analysis                              #
########################################################################

# For Li[NTf2]-<ETHER> mixtures
# <ETHER> = Linear poly(ethylene oxides) of arbitrary length (including
#           dimethyl ether)

#Available static index groups
# Group  0 System
# Group  1 Ion
# Group  2 li
# Group  3 ntf2
# Group  4 <ether>
# Group  5 Other
# Group  6 li
# Group  7 ntf2
# Group  8 <ether>

#Aditional static index groups when supplying the .ndx file created below
# Group  9 NTF2_&_N*
# Group 10 NTF2_&_O*
# Group 11 NTF2_&_S*
# Group 12 NTF2_&_C*
# Group 13 NTF2_&_F*
# Group 14 <ETHER>_&_O*
# Group 15 <ETHER>_&_C*
# Group 16 <ETHER>_&_H*
# Group 17 <ETHER>_&_!H*


# For Li[NTf2]-<ETHER> mixtures with graphene electrodes

#Available static index groups
# Group  0 System
# Group  1 Ion
# Group  2 li
# Group  3 ntf2
# Group  4 <ether>
# Group  5 B3
# Group  6 B2
# Group  7 B1
# Group  8 T1
# Group  9 T2
# Group 10 T3
# Group 11 Other
# Group 12 li
# Group 13 ntf2
# Group 14 <ether>
# Group 15 B3
# Group 16 B2
# Group 17 B1
# Group 18 T1
# Group 19 T2
# Group 20 T3

#Aditional static index groups when supplying the .ndx file created below
# Group 21 graB
# Group 22 graT
# Group 23 electrodes
# Group 24 electrolyte
# Group 25 NTF2_&_N*
# Group 26 NTF2_&_O*
# Group 27 NTF2_&_S*
# Group 28 NTF2_&_C*
# Group 29 NTF2_&_F*
# Group 30 <ETHER>_&_O*
# Group 31 <ETHER>_&_C*
# Group 32 <ETHER>_&_H*
# Group 33 <ETHER>_&_!H*


echo -e "\n\n\n"
if [ -f ${system}.ndx ]; then
    mv -v ${system}.ndx ${system}_${timestamp}.ndx || exit
    echo -e "\n\n\n"
    echo "=================================================================="
    echo -e "r ${anion}   &   a N* \n
             r ${anion}   &   a O* \n
             r ${anion}   &   a S* \n
             r ${anion}   &   a C* \n
             r ${anion}   &   a F* \n
             r ${solvent} &   a O* \n
             r ${solvent} &   a C* \n
             r ${solvent} &   a H* \n
             r ${solvent} & ! a H* \n
             q"\
        | gmx make_ndx -f ${settings}_${system}.tpr\
                       -n ${system}_${timestamp}.ndx\
                       -o ${system}.ndx\
        || exit
    echo "=================================================================="
else
    echo "=================================================================="
    echo -e "r ${anion}   &   a N* \n
             r ${anion}   &   a O* \n
             r ${anion}   &   a S* \n
             r ${anion}   &   a C* \n
             r ${anion}   &   a F* \n
             r ${solvent} &   a O* \n
             r ${solvent} &   a C* \n
             r ${solvent} &   a H* \n
             r ${solvent} & ! a H* \n
             q"\
        | gmx make_ndx -f ${settings}_${system}.tpr\
                       -o ${system}.ndx\
        || exit
    echo "=================================================================="
fi


########################################################################
#                          Clean up directory                          #
########################################################################

saveDir="ana_${settings}_${system}"
echo -e "\n\n\n"
if [ ! -d ${saveDir} ]; then
    mkdir -v ${saveDir}
fi
mv -v ${settings}_${system}_make_ndx_slurm-${SLURM_JOB_ID}.out\
      ${saveDir}\
    || exit


end_time=$(date -R)
elapsed_time_days=$(date_time_diff.sh -s "${start_time}" -e "${end_time}")
echo -e "\n\n\n"
echo "End time =     ${end_time}"
echo "Elapsed time = ${elapsed_time_days}"
echo
echo "${thisfile} done"
exit 0
