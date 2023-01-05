#!/bin/bash

#SBATCH --signal=INT@900
#SBATCH --job-name="gmx_mdrun"
#SBATCH --output="gmx_mdrun_slurm-%j.out"
# The above options are only default values that can be overwritten by
# command-line arguments

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst

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
gmx_mpi_exe=${10}       # MPI version of the Gromacs executable (None = no MPI)
guess_num_threads=${11} # Guess number of thread-MPI ranks and OMP threads.  0 = No, 1 = Yes
# See https://github.com/koalaman/shellcheck/wiki/SC2086#exceptions
# and https://github.com/koalaman/shellcheck/wiki/SC2206
# shellcheck disable=SC2206
mdrun_flags=(${12}) # Additional flags to parse to mdrun
# shellcheck disable=SC2206
grompp_flags=(${13}) # Additional flags to parse to grompp

echo -e "\n"
echo "Parsed arguments:"
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
echo "mdrun_flags       = ${mdrun_flags[*]}"
echo "grompp_flags      = ${grompp_flags[*]}"

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
        echo "--ntasks-per-node is provided to sbtach"
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
# Load required executable(s)                                          #
########################################################################

if [[ ${SLURM_JOB_NUM_NODES} -gt 1 ]] && [[ ${gmx_mpi_exe} == "None" ]]; then
    gmx_mpi_exe="gmx_mpi"
    echo
    echo "NOTE: SLURM_JOB_NUM_NODES (${SLURM_JOB_NUM_NODES}) is greater than"
    echo "one but you did not provide the MPI executable of Gromacs."
    echo "I will try '${gmx_mpi_exe}' as MPI executable"
fi
if [[ ${gmx_mpi_exe} == "None" ]]; then
    # shellcheck source=/dev/null
    source "${bash_dir}/load_gmx.sh" "${gmx_lmod}" "${gmx_exe}"
else
    # shellcheck source=/dev/null
    source "${bash_dir}/load_gmx.sh" "${gmx_lmod}" "${gmx_mpi_exe}"
fi

########################################################################
# Function Definitions                                                 #
########################################################################

rm_old_energy_files() {
    echo -e "\n"
    echo "Removing old energy.xvg files..."
    # From https://stackoverflow.com/a/34862475
    # shellcheck disable=SC2010
    ls "${settings}_out_${system}_energy_"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*".xvg" -tp |
        grep -v '/$' |
        tail -n +2 |
        xargs -I {} rm -v -- {}
    if compgen -G "${settings}_out_${system}_energy_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*.xvg" > /dev/null; then
        mv -v \
            "${settings}_out_${system}_energy_"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*".xvg" \
            "${settings}_out_${system}_energy.xvg"
    fi
}

compress() {
    echo -e "\n"
    echo "Compressing large files..."
    if [[ -z ${SLURM_CPUS_ON_NODE} ]]; then
        if [[ -z ${SLURM_CPUS_PER_TASK} ]]; then
            echo
            echo "Unexpected ERROR: SLURM_CPUS_ON_NODE and SLURM_CPUS_PER_TASK"
            echo "are not assigned"
            exit 1
        fi
        NCPUS=${SLURM_CPUS_PER_TASK}
    else
        NCPUS=${SLURM_CPUS_ON_NODE}
    fi
    NJOBS=3
    NCPUS=$((NCPUS / NJOBS > 0 ? NCPUS / NJOBS : 1))
    if [[ -f ${settings}_out_${system}.edr ]]; then
        srun --ntasks 1 --cpus-per-task "${NCPUS}" --exclusive \
            gzip --best --verbose "${settings}_out_${system}.edr" &
    fi
    if [[ -f ${settings}_out_${system}.log ]]; then
        srun --ntasks 1 --cpus-per-task "${NCPUS}" --exclusive \
            gzip --best --verbose "${settings}_out_${system}.log" &
    fi
    if [[ -f ${settings}_out_${system}_energy.xvg ]]; then
        srun --ntasks 1 --cpus-per-task "${NCPUS}" --exclusive \
            gzip --best --verbose "${settings}_out_${system}_energy.xvg" &
    fi
    wait
}

clean_up() {
    rm_old_energy_files
    compress
    echo -e "\n"
    echo "Moving simulation files to '${settings}_${system}'..."
    if [[ -d ${settings}_${system} ]]; then
        echo
        echo "WARNING: The directory already exists: '${settings}_${system}'"
    elif [[ ! -d ${settings}_${system} ]]; then
        mkdir -v "${settings}_${system}" || exit
        if [[ -f ${structure} ]]; then
            mv -v "${structure}" "${settings}_${system}"
        fi
        if [[ -f ${system}.top ]]; then
            mv -v "${system}.top" "${settings}_${system}"
        fi
        if [[ -f ${system}.ndx ]]; then
            mv -v "${system}.ndx" "${settings}_${system}"
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
    exit "${mdrun_exit_code}"
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
        script_exit_code=0
    elif [[ ${current_step} -lt ${nsteps} ]]; then
        echo "current_step (${current_step}) < nsteps (${nsteps})"
        echo "NOTE: Setting exit code to 0 so that the depending jobs can start"
        final_info
        script_exit_code=0
    elif [[ ${current_step} -ge ${nsteps} ]]; then
        echo "current_step (${current_step}) >= nsteps (${nsteps})"
        echo "NOTE: Setting exit code to 9 so that the depending jobs will be"
        echo "cancelled."
        clean_up
        final_info
        script_exit_code=9
    else
        echo "Unexpected ERROR: The current number of simulation steps is"
        echo "neither less than nor greater than nor equal to nsteps:"
        echo "current_step (${current_step}) <>=? nsteps (${nsteps})"
        script_exit_code=1
    fi
    if [[ ${mdrun_exit_code} -eq 0 ]] || [[ ${mdrun_exit_code} -eq 1 ]]; then
        # gmx mdrun finished gracefully or was terminated by INT signal.
        exit "${script_exit_code}"
    else
        # gmx mdrun exited with an error.
        exit "${mdrun_exit_code}"
    fi
}

gmx_energy() {
    timestamp=$(date +%Y-%m-%d_%H-%M-%S || exit)
    echo -e "\n"
    echo "================================================================="
    echo -e \
        "Potential \n" \
        "Kinetic-E \n" \
        "Total-E \n" \
        "Conserved-E \n" \
        "Temperature \n" \
        "Pressure \n" \
        "Volume \n" \
        "Density" |
        "${gmx_exe}" energy \
            -f "${settings}_out_${system}.edr" \
            -s "${settings}_${system}.tpr" \
            -o "${settings}_out_${system}_energy_${timestamp}.xvg" ||
        exit
    echo "================================================================="
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
        echo "================================================================="
        "${gmx_exe}" check -f "${dir}/${settings}_out_${system}.cpt" || exit
        echo "================================================================="
    fi
    if [[ -f ${dir}/${settings}_out_${system}.edr ]]; then
        echo -e "\n"
        echo "================================================================="
        "${gmx_exe}" check -e "${dir}/${settings}_out_${system}.edr" || exit
        echo "================================================================="
    fi
    if [[ -f ${dir}/${settings}_out_${system}.gro ]]; then
        echo -e "\n"
        echo "================================================================="
        "${gmx_exe}" check -f "${dir}/${settings}_out_${system}.gro" || exit
        echo "================================================================="
    fi
    if [[ -f ${dir}/${settings}_out_${system}_prev.cpt ]]; then
        echo -e "\n"
        echo "================================================================="
        "${gmx_exe}" check -f "${dir}/${settings}_out_${system}_prev.cpt" || exit
        echo "================================================================="
    fi
    if [[ -f ${dir}/${settings}_out_${system}.trr ]] &&
        [[ -f ${dir}/${settings}_${system}.tpr ]]; then
        echo -e "\n"
        echo "================================================================="
        echo 0 | "${gmx_exe}" trjconv \
            -f "${dir}/${settings}_out_${system}.trr" \
            -s "${dir}/${settings}_${system}.tpr" \
            -o "${dir}/test.xtc" \
            -e 0 ||
            exit
        echo "================================================================="
        echo
        rm -v "${dir}/test.xtc"
    elif [[ -f ${dir}/${settings}_out_${system}.trr ]]; then
        echo -e "\n"
        echo "================================================================="
        "${gmx_exe}" trjconv \
            -f "${dir}/${settings}_out_${system}.trr" \
            -o "${dir}/test.xtc" \
            -e 0 ||
            exit
        echo "================================================================="
        echo
        rm -v "${dir}/test.xtc"
    fi
}

########################################################################
# Backup Files from a Previous Simulation                              #
########################################################################

backup_dir="${settings}_${system}_backup"
backup_dir_prev="${backup_dir}_prev"
rsync_log_file="rsync.log"
if [[ ${backup} -eq 1 ]]; then
    echo -e "\n"
    echo "Creating backup of files from a previous simulation..."
    if [[ -f ${settings}_${system}_mdout.mdp ]] ||
        [[ -f ${settings}_${system}.tpr ]] ||
        compgen -G "${settings}_out_${system}*" > /dev/null; then
        echo "Found files from a previous simulation"
        echo "Going to backup them to ${backup_dir}"
        if [[ -d ${backup_dir} ]]; then
            echo
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
            echo "    --archive \\"
            echo "    --partial \\"
            echo "    --append-verify \\"
            echo "    --delete \\"
            echo "    --verbose \\"
            echo "    --progress \\"
            echo "    --human-readable \\"
            echo "    --stats \\"
            echo "    --log-file=${rsync_log_file} \\"
            echo "    --exclude=${rsync_log_file} \\"
            echo "    ./${backup_dir}/ \\"
            echo "    ./${backup_dir_prev}/"
            rsync \
                --archive \
                --partial \
                --append-verify \
                --delete \
                --verbose \
                --progress \
                --human-readable \
                --stats \
                --log-file="${rsync_log_file}" \
                --exclude="${rsync_log_file}" \
                "./${backup_dir}/" \
                "./${backup_dir_prev}/" ||
                exit
            mv -v "${rsync_log_file}" "${backup_dir_prev}"
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
        echo "    --archive \\"
        echo "    --partial \\"
        echo "    --append-verify \\"
        echo "    --delete \\"
        echo "    --verbose \\"
        echo "    --progress \\"
        echo "    --human-readable \\"
        echo "    --stats \\"
        echo "    --log-file=${rsync_log_file} \\"
        echo "    --exclude=${rsync_log_file} \\"
        echo "    --exclude=${backup_dir}* \\"
        echo "    --exclude=${backup_dir_prev}* \\"
        echo "    --include=${settings}_${system}_mdout.mdp \\"
        echo "    --include=${settings}_${system}.tpr \\"
        echo "    --include=${settings}_out_${system}* \\"
        echo "    --exclude=* \\"
        echo "    ./ \\"
        echo "    ./${backup_dir}/"
        rsync \
            --archive \
            --partial \
            --append-verify \
            --delete \
            --verbose \
            --progress \
            --human-readable \
            --stats \
            --log-file="${rsync_log_file}" \
            --exclude="${rsync_log_file}" \
            --exclude="${backup_dir}*" \
            --exclude="${backup_dir_prev}*" \
            --include="${settings}_${system}_mdout.mdp" \
            --include="${settings}_${system}.tpr" \
            --include="${settings}_out_${system}*" \
            --exclude="*" \
            "./" \
            "./${backup_dir}/" ||
            exit
        mv -v "${rsync_log_file}" "${backup_dir}"
    else
        echo
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
if [[ ${gmx_mpi_exe} == "None" ]]; then
    mdrun="srun --ntasks 1 ${gmx_exe} mdrun"
else
    mdrun="srun ${gmx_mpi_exe}"
fi
mdrun="${mdrun} \
    -s ${settings}_${system}.tpr \
    -deffnm ${settings}_out_${system} \
    ${mdrun_flags[*]}"
if [[ ${guess_num_threads} -eq 0 ]]; then
    if [[ ${gmx_mpi_exe} == "None" ]]; then
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
    grompp="${gmx_exe} grompp \
        -f ${settings}_${system}.mdp \
        -c ${structure} \
        -p ${system}.top \
        -o ${settings}_${system}.tpr \
        ${grompp_flags[*]}"
    if [[ -f ${system}.ndx ]]; then
        grompp="${grompp} -n ${system}.ndx"
    fi
    echo -e "\n"
    echo "================================================================="
    ${grompp} || exit
    echo "================================================================="
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
echo "================================================================="
# A single INT signal causes gmx mdrun to exit with exit code 1.
# => Don't simply exit on non-zero exit code, because in this case
# depending jobs will be cancelled even if gmx mdrun was stopped by an
# INT signal from Slurm shortly before reaching the job's time limit.
${mdrun}
mdrun_exit_code="$?"
echo "================================================================="

gmx_energy

if [[ ${continue} -eq 0 ]] || [[ ${continue} -eq 1 ]]; then
    # No resubmission, single slurm job.
    finish
elif [[ ${continue} -eq 2 ]] || [[ ${continue} -eq 3 ]]; then
    # Potential resubmission, multiple dependend slurm jobs.
    check_resubmission_and_quit
else
    echo
    echo "ERROR: 'continue' must be either 0, 1, 2 or 3 but you gave"
    echo "'${continue}'"
    exit 1
fi
