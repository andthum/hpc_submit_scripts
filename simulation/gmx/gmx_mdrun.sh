#!/bin/bash

#SBATCH --signal=INT@300
#SBATCH --job-name="gmx_mdrun"
#SBATCH --output="gmx_mdrun_slurm-%j.out"

# MIT License
# Copyright (c) 2021  All authors listed in the file AUTHORS.rst

# This script is meant to be submitted by submit_gmx_mdrun.py

thisfile=$(basename "${BASH_SOURCE[0]}")
echo "${thisfile}"
start_time=$(date --rfc-3339=seconds || exit)
echo "Start time = ${start_time}"

########################################################################
# Argument Parsing                                                     #
########################################################################

bash_dir=${1}           # Directory containing bash scripts used by this script
system=${2}             # The name of the system to simulate
settings=${3}           # The simulation settings to use
structure=${4}          # Name of the file that contains the starting structure
continue=${5}           # Continue a previous simulation? {0, 1, 2, 3}
nsteps=${6}             # Maximum number of simulation steps
backup=${7}             # Backup old files?  0 = No.  1 = Yes.
gmx_lmod=${8}           # File containing the modules to load Gromacs
gmx_exe=${9}            # Name of the Gromacs executable
gmx_mpi_exe=${10}       # MPI version of the Gromacs executable (0 = no MPI)
guess_num_threads=${11} # Guess number of thread-MPI ranks and OMP threads.  0 = No, 1 = Yes
# See https://github.com/koalaman/shellcheck/wiki/SC2086#exceptions
# and https://github.com/koalaman/shellcheck/wiki/SC2206
# shellcheck disable=SC2206
grompp_flags=(${11}) # Additional flags to parse to grompp

echo -e "\n"
echo "Parsed arguments:"
# Leave as two separated strings.  See
# https://github.com/koalaman/shellcheck/wiki/SC2145
echo "grompp_flags =" "${grompp_flags[@]}"
echo "bash_dir          = ${bash_dir}"
echo "system            = ${system}"
echo "settings          = ${settings}"
echo "structure         = ${structure}"
echo "continue          = ${continue}"
echo "nsteps            = ${nsteps}"
echo "backup            = ${backup}"
echo "gmx_lmod          = ${gmx_lmod}"
echo "gmx_exe           = ${gmx_exe}"
echo "gmx_mpi_exe       = ${gmx_mpi_exe}"
echo "guess_num_threads = ${guess_num_threads}"

if [[ ! -d ${bash_dir} ]]; then
    echo
    echo "ERROR: No such directory: '${bash_dir}'"
    exit 1
fi
if [[ ${continue} -ne 0 ]] &&
    [[ ${continue} -ne 1 ]] &&
    [[ ${continue} -ne 2 ]] &&
    [[ ${continue} -ne 3 ]]; then
    echo
    echo "ERROR: 'continue' must be either 0, 1, 2 or 3 but you gave"
    echo "'${continue}'"
    exit 1
fi
if [[ ${backup} -ne 0 ]] && [[ ${backup} -ne 1 ]]; then
    echo
    echo "ERROR: 'backup' must be either 0 or 1 but you gave '${backup}'"
    exit 1
fi
if [[ ${guess_num_threads} -ne 0 ]] && [[ ${guess_num_threads} -ne 1 ]]; then
    echo
    echo "ERROR: 'guess_num_threads' must be either 0 or 1 but you gave"
    echo "'${guess_num_threads}'"
    exit 1
fi

########################################################################
# Runtime Information                                                  #
########################################################################

echo -e "\n"
bash "${bash_dir}/echo_slurm_output_environment_variables.sh"
if [[ ${guess_num_threads} -eq 1 ]]; then
    echo "CPUS_PER_TASK           = Guessed by Gromacs"
elif [[ ${guess_num_threads} -eq 0 ]]; then
    # If not guess, set the number of thread-MPI to
    # SLURM_NTASKS_PER_NODE and the number of OpenMP threads per
    # (thread-)MPI to CPUS_PER_TASK
    if [[ -z ${SLURM_NTASKS_PER_NODE} ]]; then
        echo
        echo "ERROR: SLURM_NTASKS_PER_NODE is not assigned.  Make sure"
        echo "--ntasks-per-node is set by sbtach"
        exit 1
    fi
    if [[ -z ${SLURM_CPUS_PER_TASK} ]]; then
        if [[ -z ${SLURM_CPUS_ON_NODE} ]]; then
            echo
            echo "Unexpected ERROR: SLURM_CPUS_PER_TASK and SLURM_CPUS_ON_NODE"
            echo "are not assigned"
            exit 1
        fi
        CPUS_PER_TASK=$((SLURM_CPUS_ON_NODE / SLURM_NTASKS_PER_NODE))
    else
        CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
    fi
    echo "CPUS_PER_TASK           = ${CPUS_PER_TASK}"
else
    echo
    echo "ERROR: 'guess_num_threads' must be either 0 or 1 but you gave"
    echo "'${guess_num_threads}'"
    exit 1
fi

########################################################################
# Get Access to the Gromacs Executable                                 #
########################################################################

if [[ -z ${SLURM_CLUSTER_NAME} ]]; then
    echo
    echo "Unexpected ERROR: SLURM_CLUSTER_NAME is not assigned"
    exit 1
fi
if [[ ${SLURM_CLUSTER_NAME} == palma2 ]]; then
    if [[ ${gmx_lmod} == 0 ]]; then
        gmx_lmod="${bash_dir}/../lmod/palma/2019a/gmx2018-8_foss.sh"
        echo
        echo "NOTE: SLURM_CLUSTER_NAME is '${SLURM_CLUSTER_NAME}' but gmx_lmod"
        echo "is set to zero.  I will try to load Gromacs from '${gmx_lmod}'"
    fi
    if [[ ! -f ${gmx_lmod} ]]; then
        echo
        echo "ERROR: Cannot load Gromacs.  No such file: '${gmx_lmod}'"
        exit 1
    fi
    module --force purge || exit
    # shellcheck source=/dev/null
    source "${gmx_lmod}" || exit
    echo
    module list
elif [[ ${SLURM_CLUSTER_NAME} == bagheera ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/usr/local/gromacs/bin/GMXRC" || exit
else
    echo
    echo "ERROR: Unkown cluster name '${SLURM_CLUSTER_NAME}'"
    exit 1
fi

if [[ ${SLURM_JOB_NUM_NODES} -gt 1 ]] && [[ ${gmx_mpi_exe} == 0 ]]; then
    gmx_mpi_exe="gmx_mpi"
    echo
    echo "NOTE: SLURM_JOB_NUM_NODES (${SLURM_JOB_NUM_NODES}) is greater than"
    echo "one but you did not provide the MPI executable of Gromacs."
    echo "I will try '${gmx_mpi_exe}' as MPI executable"
fi
echo
echo "Gromacs executable:"
if [[ ${gmx_mpi_exe} == 0 ]]; then
    which "${gmx_exe}" || exit
else
    which "${gmx_mpi_exe}" || exit
fi

########################################################################
# Function Definitions                                                 #
########################################################################

clean_up() {
    if [[ -d ${settings}_${system} ]]; then
        echo
        echo "WARNING: The directory already exists: '${settings}_${system}'"
    elif [[ ! -d ${settings}_${system} ]]; then
        mkdir -v "${settings}_${system}" || exit
        if [[ -f ${structure} ]]; then
            mv -v "${structure}" "${settings}_${system}"
        fi
        mv -v "${settings}_${system}"* "${settings}_${system}"
        mv -v "${settings}_out_${system}"* "${settings}_${system}"
    else
        echo
        echo "Unexpected WARNING: Existence of directory cannot be checked:"
        echo "'${settings}_${system}'"
    fi
}

final_info() {
    end_time=$(date --rfc-3339=seconds)
    elapsed_time=$(bash \
        "${bash_dir}/date_time_diff.sh" \
        -s "${start_time}" \
        -e "${end_time}")
    echo -e "\n"
    echo "End time     = ${end_time}"
    echo "Elapsed time = ${elapsed_time}"
    echo "${thisfile} done"
}

finish() {
    clean_up
    final_info
    exit
}

gmx_energy() {
    echo -e "\n"
    timestamp=$(date +%Y-%m-%d_%H-%M-%S || exit)
    echo -e \
        "Potential \n" \
        "Kinetic-E \n" \
        "Total-E \n" \
        "Temperature \n" \
        "Pressure \n" \
        "Volume \n" \
        "Density" |
        "${gmx_exe}" energy \
            -f "${settings}_out_${system}.edr" \
            -s "${settings}_${system}.tpr" \
            -o "${settings}_out_${system}_energy_${timestamp}.xvg" ||
        exit
}

gmx_check_corruption() {
    dir="${1}"
    if [[ -z ${dir} ]]; then
        dir="."
    fi
    if [[ ! -d ${dir} ]]; then
        echo
        echo "ERROR: No such directory: '${dir}'"
        exit 1
    fi
    if [[ -f ${dir}/${settings}_out_${system}.cpt ]]; then
        echo -e "\n"
        "${gmx_exe}" check -f "${dir}/${settings}_out_${system}.cpt" || exit
    fi
    if [[ -f ${dir}/${settings}_out_${system}.edr ]]; then
        echo -e "\n"
        "${gmx_exe}" check -e "${dir}/${settings}_out_${system}.edr" || exit
    fi
    if [[ -f ${dir}/${settings}_out_${system}.gro ]]; then
        echo -e "\n"
        "${gmx_exe}" check -f "${dir}/${settings}_out_${system}.gro" || exit
    fi
    if [[ -f ${dir}/${settings}_out_${system}_prev.cpt ]]; then
        echo -e "\n"
        "${gmx_exe}" check -f "${dir}/${settings}_out_${system}_prev.cpt" || exit
    fi
    if [[ -f ${dir}/${settings}_out_${system}.trr ]] &&
        [[ -f ${dir}/${settings}_${system}.tpr ]]; then
        echo -e "\n"
        echo 0 | "${gmx_exe}" trjconv \
            -f "${dir}/${settings}_out_${system}.trr" \
            -s "${dir}/${settings}_${system}.tpr" \
            -o "${dir}/test.xtc" \
            -e 0 ||
            exit
        rm -v "${dir}/test.xtc"
    elif [[ -f ${dir}/${settings}_out_${system}.trr ]]; then
        echo -e "\n"
        "${gmx_exe}" trjconv \
            -f "${dir}/${settings}_out_${system}.trr" \
            -o "${dir}/test.xtc" \
            -e 0 ||
            exit
        rm -v "${dir}/test.xtc"
    fi
}

check_resubmission_and_quit() {
    current_step=$(bash \
        "${bash_dir}/gmx_get_num_steps_from_log.sh" \
        -f "${settings}_out_${system}.log" ||
        exit)
    echo -e "\n"
    if [[ ${nsteps} -lt 0 ]]; then
        echo "nsteps (${nsteps}) < 0 (No simulation step limit)"
        echo "NOTE: Setting exit code to 0 so that the depending jobs can start"
        final_info
        exit 0
    elif [[ ${current_step} -lt ${nsteps} ]]; then
        echo "current_step (${current_step}) < nsteps (${nsteps})"
        echo "NOTE: Setting exit code to 0 so that the depending jobs can start"
        final_info
        exit 0
    elif [[ ${current_step} -ge ${nsteps} ]]; then
        echo "current_step (${current_step}) >= nsteps (${nsteps})"
        echo "NOTE: Setting exit code to 9 so that the depending jobs will be"
        echo "cancelled."
        clean_up
        final_info
        exit 9
    else
        echo "Unexpected ERROR: The current number of simulation steps is"
        echo "neither less than nor greater than nor equal to nsteps:"
        echo "current_step (${current_step}) <>=? nsteps (${nsteps})"
        exit 1
    fi
}

########################################################################
# Backup Files from a Previous Simulation                              #
########################################################################

backup_dir="${settings}_${system}_backup"
backup_dir_prev="${settings}_${system}_backup_prev"
log_file="rsync.log"
if [[ ${backup} -eq 1 ]]; then
    echo -e "\n"
    echo "Creating backup of files from a previous simulation..."
    if [[ -f ${settings}_${system}_mdout.mdp ]] ||
        [[ -f ${settings}_${system}.tpr ]] ||
        [[ -f ${settings}_out_${system}.cpt ]] ||
        [[ -f ${settings}_out_${system}.edr ]] ||
        [[ -f ${settings}_out_${system}_energy.xvg ]] ||
        [[ -f ${settings}_out_${system}.gro ]] ||
        [[ -f ${settings}_out_${system}.log ]] ||
        [[ -f ${settings}_out_${system}_prev.cpt ]] ||
        [[ -f ${settings}_out_${system}_slurm.out ]] ||
        [[ -f ${settings}_out_${system}.trr ]]; then
        echo "Found files from a previous simulation"
        echo "Going to backup them to ${backup_dir}"
        if [[ -d ${backup_dir} ]]; then
            echo "NOTE: Directory already exists: '${backup_dir}'"
            echo "Going to backup it to '${backup_dir_prev}'"
            if [[ -d ${backup_dir_prev} ]]; then
                echo
                echo "NOTE: Directory already exists: '${backup_dir_prev}'"
                echo "Going to overwrite its content"
            else
                mkdir -v "${backup_dir_prev}" || exit
            fi
            echo -e "\n"
            echo "Checking files for corruption..."
            gmx_check_corruption "${backup_dir}"
            echo -e "\n"
            echo "rsync \\"
            echo "    -aPv \\"
            echo "    --append-verify \\"
            echo "    --delete \\"
            echo "    --human-readable \\"
            echo "    --stats \\"
            echo "    --log-file=${log_file} \\"
            echo "    ./${backup_dir}/ \\"
            echo "    ./${backup_dir_prev}/"
            rsync \
                -aPv \
                --append-verify \
                --delete \
                --human-readable \
                --stats \
                --log-file="${log_file}" \
                "./${backup_dir}/" \
                "./${backup_dir_prev}/" ||
                exit
            mv -v "${log_file}" "${backup_dir_prev}"
            echo -e "\n"
            echo "Backup of the backup directory done.  Now I can backup files"
            echo "from the previous simulation to the backup directory"
            echo "${backup_dir}"
        else
            mkdir -v "${backup_dir}" || exit
        fi
        echo -e "\n"
        echo "Checking files for corruption..."
        gmx_check_corruption "./"
        echo -e "\n"
        echo "rsync \\"
        echo "    -aPv \\"
        echo "    --append-verify \\"
        echo "    --delete \\"
        echo "    --exclude=${backup_dir}* \\"
        echo "    --exclude=${backup_dir_prev}* \\"
        echo "    --include=${settings}* \\"
        echo "    --exclude=* \\"
        echo "    --human-readable \\"
        echo "    --stats \\"
        echo "    --log-file=${log_file} \\"
        echo "    ./ \\"
        echo "    ./${backup_dir}/"
        rsync \
            -aPv \
            --append-verify \
            --delete \
            --exclude="${backup_dir}*" \
            --exclude="${backup_dir_prev}*" \
            --include="${settings}*" \
            --exclude="*" \
            --human-readable \
            --stats \
            --log-file="${log_file}" \
            "./" \
            "./${backup_dir}/" ||
            exit
        mv -v "${log_file}" "${backup_dir}"
    else
        echo "NOTE: No files to backup"
    fi
elif [[ ${backup} -ne 0 ]]; then
    echo
    echo "ERROR: 'backup' must be either 0 or 1 but you gave '${backup}'"
    exit 1
fi

########################################################################
# Start the Gromacs Simulation                                         #
########################################################################

# Prepare Gromacs mdrun command:
mdrun="-s ${settings}_${system}.tpr \
    -deffnm ${settings}_out_${system} \
if [[ ${gmx_mpi_exe} == 0 ]]; then
    mdrun="--ntasks 1 ${gmx_exe} mdrun ${mdrun}"
else
    mdrun="${gmx_mpi_exe} ${mdrun}"
fi
if [[ ${guess_num_threads} -eq 0 ]]; then
    if [[ ${gmx_mpi_exe} == 0 ]]; then
        mdrun="${mdrun} -ntmpi ${SLURM_NTASKS_PER_NODE}"
    fi
    mdrun="${mdrun} -ntomp ${CPUS_PER_TASK}"
elif [[ ${guess_num_threads} -ne 1 ]]; then
    echo
    echo "ERROR: 'guess_num_threads' must be either 0 or 1 but you gave"
    echo "'${guess_num_threads}'"
    exit 1
fi

if [[ ${continue} -eq 0 ]] || [[ ${continue} -eq 2 ]]; then
    # Start a new simulation
    echo -e "\n"
    if [[ -f ${system}.ndx ]]; then
        "${gmx_exe}" grompp \
            -f "${settings}_${system}.mdp" \
            -c "${structure}" \
            -n "${system}.ndx" \
            -p "${system}.top" \
            -o "${settings}_${system}.tpr" \
            "${grompp_flags[@]}" ||
            exit
    else
        "${gmx_exe}" grompp \
            -f "${settings}_${system}.mdp" \
            -c "${structure}" \
            -p "${system}.top" \
            -o "${settings}_${system}.tpr" \
            "${grompp_flags[@]}" ||
            exit
    fi
    echo -e "\n"
    mv -v "mdout.mdp" "${settings}_${system}_mdout.mdp"
elif [[ ${continue} -eq 1 ]] || [[ ${continue} -eq 3 ]]; then
    # Continue a previous simulation
    mdrun="${mdrun} \
        -cpi ${settings}_out_${system}.cpt \
        -append"
else
    echo
    echo "ERROR: 'continue' must be either 0, 1, 2 or 3 but you gave"
    echo "'${continue}'"
    exit 1
fi
echo -e "\n"
srun "${mdrun}"
gmx_energy
if [[ ${continue} -eq 0 ]] || [[ ${continue} -eq 1 ]]; then
    # Single slurm job
    finish
elif [[ ${continue} -eq 2 ]] || [[ ${continue} -eq 3 ]]; then
    # Multiple dependend slurm jobs
    check_resubmission_and_quit
else
    echo
    echo "ERROR: 'continue' must be either 0, 1, 2 or 3 but you gave"
    echo "'${continue}'"
    exit 1
fi

echo
echo "Unexpected ERROR: The script should never have reached this point"
exit 1
