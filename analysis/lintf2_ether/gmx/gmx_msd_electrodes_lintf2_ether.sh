#!/bin/bash

# #SBATCH --account=q0heuer       # Charge resources used by this job to specified account
# #SBATCH --partition=q0heuer,hims,normal  # Request a specific partition for the resource allocation. A partition usually comprises multiple nodes
#SBATCH --time=7-00:00:00         # Total run time limit. The default time limit is the partition's default time limit
# #SBATCH --time-min=7-00:00:00   # Minimum time limit. If specified, the job may have it's --time limit lowered to a value not lower than --time-min
# #SBATCH --signal=INT@600        # When a job is within @[...] seconds of its end time, send it the signal [...]@

#SBATCH --job-name="msd_electrodes"             # Name for the job allocation
#SBATCH --output="msd_electrodes_slurm-%j.out"  # Filename to which standard output and error will be written
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
#SBATCH --mem=8G                  # Required memory per node

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
begin=${3}        # Time of first frame to read from trajectory in ps
end=${4}          # Time of last frame to read from trajectory in ps
begin_fit=${5}    # Start time for fitting the MSD in ps
end_fit=${6}      # End time for fitting the MSD in ps
trestart=${7}     # Time between restarting points in trajectory (ps)

echo -e "\n\n\n"
echo "Parsed arguments:"
echo "system    = ${system}"
echo "settings  = ${settings}"
echo "begin     = ${begin}"
echo "end       = ${end}"
echo "begin_fit = ${begin_fit}"
echo "end_fit   = ${end_fit}"
echo "trestart  = ${trestart}"


if [ -z ${begin} ]; then
    begin=100000
    echo
    echo "begin is not set. Going to set it to 100000"
    echo "begin = ${begin}"
fi
if [ -z ${end} ]; then
    echo
    echo "end is not set. Going to set it to the last time in the .log"
    echo "file"
    end=$(gmx_get_last_time.sh -f ${settings}_out_${system}.log || exit)
    end=$(echo "${end%%.*}" || exit)
    echo "end = ${end}"
fi
if [ -z ${begin_fit} ]; then
    begin="-1"
    echo
    echo "begin_fit is not set. Going to set it to -1"
    echo "begin_fit = ${begin_fit}"
fi
if [ -z ${end_fit} ]; then
    end_fit="-1"
    echo
    echo "end_fit is not set. Going to set it to -1"
    echo "end_fit = ${end_fit}"
fi
if [ -z ${trestart} ]; then
    trestart=1000
    echo
    echo "trestart is not set. Going to set it to 1000"
    echo "trestart = ${trestart}"
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

if [[ ${system} == *gra* ]]; then
    echo -e "\n\n\n"
    echo "=================================================================="
    echo "15 16 17 18 19 20 21 22"\  # B3 B2 B1 T1 T2 T3 graB graT
        | gmx msd -f ${settings}_out_${system}_pbc_whole_mol_nojump.xtc\
                  -s ${settings}_${system}.tpr\
                  -n ${system}.ndx\
                  -o ${settings}_${system}_msd_electrodes_normcomm.xvg\
                  -b ${begin}\
                  -e ${end}\
                  -ngroup 8\
                  -trestart ${trestart}\
                  -beginfit ${begin_fit}\
                  -endfit ${end_fit}\
        || exit
    echo "=================================================================="
    
    echo -e "\n\n\n"
    echo "=================================================================="
    echo "15 16 17 21"\  # B3 B2 B1 graB
        | gmx msd -f ${settings}_out_${system}_pbc_whole_mol_nojump.xtc\
                  -s ${settings}_${system}.tpr\
                  -n ${system}.ndx\
                  -o ${settings}_${system}_msd_graB_rmcomm.xvg\
                  -b ${begin}\
                  -e ${end}\
                  -ngroup 3\
                  -rmcomm\
                  -trestart ${trestart}\
                  -beginfit ${begin_fit}\
                  -endfit ${end_fit}\
        || exit
    echo "=================================================================="
    
    echo -e "\n\n\n"
    echo "=================================================================="
    echo "18 19 20 22"\  # T1 T2 T3 graT
        | gmx msd -f ${settings}_out_${system}_pbc_whole_mol_nojump.xtc\
                  -s ${settings}_${system}.tpr\
                  -n ${system}.ndx\
                  -o ${settings}_${system}_msd_graT_rmcomm.xvg\
                  -b ${begin}\
                  -e ${end}\
                  -ngroup 3\
                  -rmcomm\
                  -trestart ${trestart}\
                  -beginfit ${begin_fit}\
                  -endfit ${end_fit}\
        || exit
    echo "=================================================================="
    
else
    echo
    echo "Error: System contains no electrodes."
    exit 1
fi


########################################################################
#                          Clean up directory                          #
########################################################################

saveDir="msd_electrodes_slurm-${SLURM_JOB_ID}"
parrentSaveDir="ana_${settings}_${system}"
if [ ! -d ${saveDir} ]; then
    echo -e "\n\n\n"
    mkdir -v ${saveDir} || exit
    mv -v ${settings}_${system}_msd_electrodes_normcomm.xvg\
          ${settings}_${system}_msd_graB_rmcomm.xvg\
          ${settings}_${system}_msd_graT_rmcomm.xvg\
          ${settings}_${system}_msd_electrodes_slurm-${SLURM_JOB_ID}.out\
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
