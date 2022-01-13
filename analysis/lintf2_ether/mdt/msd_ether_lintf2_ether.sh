#!/bin/bash

# #SBATCH --account=q0heuer       # Charge resources used by this job to specified account
# #SBATCH --partition=q0heuer,hims,normal  # Request a specific partition for the resource allocation. A partition usually comprises multiple nodes
#SBATCH --time=7-00:00:00         # Total run time limit. The default time limit is the partition's default time limit
# #SBATCH --time-min=7-00:00:00   # Minimum time limit. If specified, the job may have it's --time limit lowered to a value no lower than --time-min
# #SBATCH --signal=INT@600        # When a job is within @[...] seconds of its end time, send it the signal [...]@

#SBATCH --job-name="msd_ether"             # Name for the job allocation
#SBATCH --output="msd_ether_slurm-%j.out"  # Filename to which standard output and error will be written
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
#SBATCH --mem=16G                 # Required memory per node

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
begin=${3}        # First frame to read. Frame numbering starts at 0
end=${4}          # Last frame to read (exclusive)
every=${5}        # Read every n-th frame
nblocks=${6}      # Number of blocks for block averaging
restart=${7}      # Number of frames between restarting points

echo -e "\n\n\n"
echo "Parsed arguments:"
echo "system        = ${system}"
echo "settings      = ${settings}"
echo "begin         = ${begin}"
echo "end           = ${end}"
echo "every         = ${every}"
echo "nblocks       = ${nblocks}"
echo "restart       = ${restart}"

if [ -z ${begin} ]; then
    begin=0
    echo
    echo "begin is not set. Going to set it to 0"
    echo "begin = ${begin}"
fi
if [ -z ${end} ]; then
    end=-1
    echo
    echo "end is not set. Going to set it to -1"
    echo "end = ${end}"
fi
if [ -z ${every} ]; then
    every=1
    echo
    echo "every is not set. Going to set it to 1"
    echo "every = ${every}"
fi
if [ -z ${nblocks} ]; then
    nblocks=1
    echo
    echo "nblocks is not set. Going to set it to 1"
    echo "nblocks = ${nblocks}"
fi
if [ -z ${restart} ]; then
    restart=500
    echo
    echo "restart is not set. Going to set it to 500"
    echo "restart = ${restart}"
fi


########################################################################
#                  Generate system specific variables                  #
########################################################################

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
    module load GCCcore/8.2.0 || exit
    module load Python/3.7.2 || exit
    echo -e "\n\n"
    module list
fi


########################################################################
#                             Do analysis                              #
########################################################################

echo -e "\n\n\n"
echo "ether (COM)"
echo
echo "=================================================================="
${HOME}/Promotion/mdtools/env/bin/python3 -u\
    ${HOME}/Promotion/mdtools/scripts/dynamics/msd_serial.py\
        -f ${settings}_out_${system}_pbc_whole_mol_nojump.xtc\
        -s ${settings}_${system}.tpr\
        -o ${settings}_${system}_msd_ether.txt\
        --sel "resname ${solvent}"\
        --com residues\
        -b ${begin}\
        -e ${end}\
        --every ${every}\
        --nblocks ${nblocks}\
        --restart ${restart}\
    || exit
echo "=================================================================="


########################################################################
#                          Clean up directory                          #
########################################################################

saveDir="msd_ether_slurm-${SLURM_JOB_ID}"
parrentSaveDir="ana_${settings}_${system}"
if [ ! -d ${saveDir} ]; then
    echo -e "\n\n\n"
    mkdir -v ${saveDir} || exit
    mv -v ${settings}_${system}_msd_ether.txt\
          ${settings}_${system}_msd_ether_slurm-${SLURM_JOB_ID}.out\
          ${saveDir}\
        || exit
    if [ ! -d ${parrentSaveDir} ]; then
        mkdir -v ${parrentSaveDir} || exit
    fi
    if [ ! -d "${parrentSaveDir}/${saveDir}" ]; then
        mv -v ${saveDir} ${parrentSaveDir} || exit
    fi
fi


end_time=$(date -R)
elapsed_time_days=$(date_time_diff.sh -s "${start_time}" -e "${end_time}")
echo -e "\n\n\n"
echo "End time =     ${end_time}"
echo "Elapsed time = ${elapsed_time_days}"
echo
echo "${thisfile} done"
exit 0
