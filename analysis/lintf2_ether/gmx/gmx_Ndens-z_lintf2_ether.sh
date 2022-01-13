#!/bin/bash

# #SBATCH --account=q0heuer       # Charge resources used by this job to specified account
# #SBATCH --partition=q0heuer,hims,normal  # Request a specific partition for the resource allocation. A partition usually comprises multiple nodes
#SBATCH --time=2-00:00:00         # Total run time limit. The default time limit is the partition's default time limit
# #SBATCH --time-min=2-00:00:00   # Minimum time limit. If specified, the job may have it's --time limit lowered to a value not lower than --time-min
# #SBATCH --signal=INT@600        # When a job is within @[...] seconds of its end time, send it the signal [...]@

#SBATCH --job-name="Ndens-z"             # Name for the job allocation
#SBATCH --output="Ndens-z_slurm-%j.out"  # Filename to which standard output and error will be written
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
#SBATCH --mem=1G                  # Required memory per node

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
#                         Function definitions                         #
########################################################################

get_num_bins () {
    echo
    echo "Going to determine the number of bins for the given bin width"
    echo "of ${bin_width}"
    
    box_length_z=$(gmx_get_box_lengths.sh -f ${settings}_out_${system}.gro -z || exit)
    num_bins=$(printf "%.0f" "$(echo "scale=5; ${box_length_z}/${bin_width}" | bc || exit)" || exit)
    if [ -z ${num_bins} ]; then
        echo
        echo "Error in get_num_bins: Could not determine the number of"
        echo "  bins."
        echo "  box_length_z = ${box_length_z}"
        echo "  bin_width    = ${bin_width}"
        echo "  num_bins     = ${num_bins}"
        exit 1
    else
        echo "box_length_z = ${box_length_z}"
        echo "bin_width    = ${bin_width}"
        echo "num_bins     = ${num_bins}"
        return 0
    fi
}


########################################################################
#                           Argument parsing                           #
########################################################################

system=${1}    # Pattern: <components>_<mixing ratio>_<charge scaling>
settings=${2}  # Pattern: <equilibration/production>_<ensemble><temperature>_<other settings like used thermostat and barostat>
begin=${3}     # Time of first frame to read from trajectory in ps
end=${4}       # Time of last frame to read from trajectory in ps
dt=${5}        # Only write frame when t MOD dt = first time
num_bins=${6}  # Number of bins

echo -e "\n\n\n"
echo "Parsed arguments:"
echo "system   = ${system}"
echo "settings = ${settings}"
echo "begin    = ${begin}"
echo "end      = ${end}"
echo "dt       = ${dt}"
echo "num_bins = ${num_bins}"

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
if [ -z ${dt} ]; then
    dt=1
    echo
    echo "dt is not set. Going to set it to 1"
    echo "dt = ${dt}"
fi
if [ -z ${num_bins} ]; then
    echo
    echo "num_bins is not set."
    echo "Trying to read box length in z direction from"
    echo "${settings}_out_${system}.gro and set num_bins to"
    echo "box_length_z/0.005"
    if [ -f ${settings}_out_${system}.gro ]; then
        bin_width=0.005
        get_num_bins || exit
    else
        num_bins=2000
        echo
        echo "Could not read box length in z direction from"
        echo "${settings}_out_${system}.gro"
        echo "The file does not exist!"
        echo "Going to set num_bins to 2000"
        echo "num_bins = ${num_bins}" 
    fi
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
    selection="24 2 3 4 25 26 30 21 22 23 0"
    # electrolyte li ntf2 <ether>
    # NTF2_&_N* NTF2_&_O* <ETHER>_&_O*
    # graB graT electrodes System
    ngroups=11
else
    selection="0 2 3 4 9 10 14"
    # System li ntf2 <ether> NTF2_&_N* NTF2_&_O* <ETHER>_&_O*
    ngroups=7
fi
echo -e "\n\n\n"
echo "=================================================================="
echo ${selection}\
    | gmx density -f ${settings}_out_${system}_pbc_whole_mol.xtc\
                  -s ${settings}_${system}.tpr\
                  -n ${system}.ndx\
                  -o ${settings}_${system}_Ndens-z.xvg\
                  -b ${begin}\
                  -e ${end}\
                  -dt ${dt}\
                  -d Z\
                  -sl ${num_bins}\
                  -dens number\
                  -ng ${ngroups}\
    || exit
echo "=================================================================="


########################################################################
#                          Clean up directory                          #
########################################################################

saveDir="Ndens-z_slurm-${SLURM_JOB_ID}"
parrentSaveDir="ana_${settings}_${system}"
if [ ! -d ${saveDir} ]; then
    echo -e "\n\n\n"
    mkdir -v ${saveDir} || exit
    mv -v ${settings}_${system}_Ndens-z.xvg\
          ${settings}_${system}_Ndens-z_slurm-${SLURM_JOB_ID}.out\
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
