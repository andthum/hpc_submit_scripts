#!/bin/bash

# #SBATCH --account=q0heuer       # Charge resources used by this job to specified account
# #SBATCH --partition=q0heuer,hims,normal  # Request a specific partition for the resource allocation. A partition usually comprises multiple nodes
#SBATCH --time=2-00:00:00         # Total run time limit. The default time limit is the partition's default time limit
# #SBATCH --time-min=2-00:00:00   # Minimum time limit. If specified, the job may have it's --time limit lowered to a value not lower than --time-min
# #SBATCH --signal=INT@600        # When a job is within @[...] seconds of its end time, send it the signal [...]@

#SBATCH --job-name="msm_mm"             # Name for the job allocation
#SBATCH --output="msm_mm_slurm-%j.out"  # Filename to which standard output and error will be written
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
#                         Function definitions                         #
########################################################################

get_num_bins () {
    echo
    echo "Going to determine the number of bins for the given bin width"
    echo "of ${bin_width}"

    box_length_z=$(gmx_get_box_lengths.sh -f ${settings}_out_${system}.gro -z || exit)
    box_length_z=$(echo "scale=4; ${box_length_z} * 10" | bc || exit )  # nm -> Angstrom
    num_bins=$(printf "%.0f" "$(echo "scale=4; ${box_length_z}/${bin_width}" | bc || exit)" || exit)
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


get_timestep () {
    dt=$(grep -m 1 "dt" ${settings}_${system}.mdp | awk '{print $3}' || exit)
    dt=$(printf "%f" ${dt} || exit)
    nstxout=$(grep -m 1 "nstxout" ${settings}_${system}.mdp | awk '{print $3}' || exit)
    nstxout=$(printf "%f" ${nstxout} || exit)
    timestep=$(echo "scale=0; ${dt} * ${nstxout} / 1" | bc || exit )
    timestep="${timestep} ps"
}


########################################################################
#                           Argument parsing                           #
########################################################################

system=${1}       # Pattern: <components>_<mixing ratio>_<charge scaling>
settings=${2}     # Pattern: <equilibration/production>_<ensemble><temperature>_<other settings like used thermostat and barostat>
residue=${3}      # Residue for wich to estimate the Markov model
direction=${4}    # Spatial direction to discretize
num_bins=${5}     # Number of bins
lagtime=${6}      # Lagtime in multiples of trajectory steps
timestep=${7}     # Real time corresponding to one trajectory step
error=${8}        # Whether to estimate the uncertainty of the model or not

echo -e "\n\n\n"
echo "Parsed arguments:"
echo "system   = ${system}"
echo "settings = ${settings}"
echo "residue   = ${residue}"
echo "direction = ${direction}"
echo "num_bins = ${num_bins}"
echo "lagtime  = ${lagtime}"
echo "timestep = ${timestep}"
echo "error    = ${error}"

if [ -z ${direction} ]; then
    direction=z
    echo
    echo "direction is not set. Going to set it to z"
    echo "direction = ${direction}"
fi
if [ -z ${num_bins} ]; then
    echo
    echo "num_bins is not set."
    echo "Trying to read box length in z direction from"
    echo "${settings}_out_${system}.gro and set num_bins to"
    echo "box_length_z/0.05"
    if [ -f ${settings}_out_${system}.gro ]; then
        bin_width=0.05
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
if [ -z ${lagtime} ]; then
    lagtime=1
    echo
    echo "lagtime is not set. Going to set it to 1"
    echo "lagtime = ${lagtime}"
fi
if [[ -z ${timestep} ]]; then
    echo
    echo "timestep is not set."
    echo "Trying to get the timestep from ${settings}_${system}.mdp"
    if [ -f ${settings}_${system}.mdp ]; then
        get_timestep || exit
    else
        timestep="1 step"
        echo
        echo "Could not get the timestep from ${settings}_${system}.mdp"
        echo "The file does not exist!"
        echo "Going to set timestep to '1 step'"
        echo "timestep = ${timestep}"
    fi
fi
if [ -z ${error} ]; then
    error=false
    echo
    echo "error is not set. Going to set it to false"
    echo "error = ${error}"
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
echo "=================================================================="
if [[ ${error} == true ]]; then
    ${HOME}/Promotion/mdtools/env/bin/python3 -u\
        ${HOME}/Promotion/mdtools/scripts/markov_modeling/pyemma_mm.py\
            -f ${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_traj.npy\
            --bins ${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_bins.npy\
            -o ${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}\
            --no-plots\
            --lag ${lagtime}\
            --dt ${timestep}\
            --bayes\
        || exit
else
    ${HOME}/Promotion/mdtools/env/bin/python3 -u\
        ${HOME}/Promotion/mdtools/scripts/markov_modeling/pyemma_mm.py\
            -f ${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_traj.npy\
            --bins ${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_bins.npy\
            -o ${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}\
            --no-plots\
            --lag ${lagtime}\
            --dt ${timestep}\
        || exit
fi
echo "=================================================================="


########################################################################
#                          Clean up directory                          #
########################################################################

# Ouput files are needed by pyemma_cktest.py => do not rename them them
# or move them to another directory

# saveDir="msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm_slurm-${SLURM_JOB_ID}"
# parrentSaveDir="ana_${settings}_${system}"
# if [ ! -d ${saveDir} ]; then
#     echo -e "\n\n\n"
#     mkdir -v ${saveDir} || exit
#     mv -v ${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm*\
#           ${saveDir}\
#         || exit
#     if [ ! -d ${parrentSaveDir} ]; then
#         mkdir -v ${parrentSaveDir} || exit
#     fi
#     if [ ! -d "${parrentSaveDir}/${saveDir}" ]; then
#         mv -v ${saveDir} ${parrentSaveDir} || exit
#     fi
# fi


end_time=$(date -R)
elapsed_time_days=$(date_time_diff.sh -s "${start_time}" -e "${end_time}")
echo -e "\n\n\n"
echo "End time =     ${end_time}"
echo "Elapsed time = ${elapsed_time_days}"
echo
echo "${thisfile} done"
exit 0
