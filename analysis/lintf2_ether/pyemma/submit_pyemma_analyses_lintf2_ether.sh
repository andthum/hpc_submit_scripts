#!/bin/bash

timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"
thisfile=$(basename "${BASH_SOURCE}")
cluster_name="palma2"

dir_bash_scripts="${HOME}/Promotion/scripts/bash"
if [ ! -d ${dir_bash_scripts} ]; then
    echo
    echo "Error: ${dir_bash_scripts} does not exist"
    exit 1
fi
export PATH=${PATH}:${dir_bash_scripts} || exit


scripts=("msm_discrete.sh")
scripts+=("msm_its.sh")
scripts+=("msm_mm.sh")
scripts+=("msm_cktest.sh")


########################################################################
#                    Information and usage function                    #
########################################################################

information () {
    echo
    echo "Submit PyEMMA analysis tools to estimate Markov models from MD"
    echo "trajectories for systems containing Li[NTf2] and linear"
    echo "poly(ethylene oxides) of arbitrary length (including dimethyl"
    echo "ether) to the Slurm Workload Manager of ${cluster_name}"
    echo
    return 0
}


usage () {
    echo
    echo "Usage:"
    echo
    echo "Required arguments:"
    echo "  -s    System to be analyzed. Example pattern:"
    echo "        lintf2_<ether>_<mixing ratio>"
    echo "  -e    Used simulation settings. Pattern:"
    echo "        <equilibration/production>_<ensemble><temperature>_<other settings like used thermostat and barostat>"
    echo
    echo "Optional arguments:"
    echo "  -h    Show this help message and exit"
    echo
    echo "  -a    Select the analysis script(s) to be submitted."
    echo "          0 = All"
    echo "          1 = msm_discrete and msm_its"
    echo "          2 = msm_mm and msm_cktest"
    echo "          3 = msm_its, msm_mm and msm_cktest"
    echo "        Or directly type the name of the script you want to"
    echo "        start. Works only for a single script:"
    echo "          msm_discrete         msm_its"
    echo "          msm_mm               msm_cktest"
    echo "        Default: 0"
    echo "  -r    Select the residue for which to estimate the Markov"
    echo "        model. Possible choices are li, ntf2, peo, g<i> (where"
    echo "        i is the number of monomers per glyme molecule)."
    echo "        Default: li"
    echo
    echo "  -b    First frame to read from trajectory. Frame numbering"
    echo "        starts at zero. Default: 0"
    echo "  -f    Last frame to read from trajectory (exclusive)."
    echo "        Default: -1 (means last frame in trajectory)"
    echo "  -d    Only read every n-th frame. Default: 1"
    echo
    echo "  -D    Spatial direction along which the discretization is"
    echo "        done and the Markov model is constructed. Either x, y"
    echo "        or z. Default: z"
    echo "  -w    Bin width (in Angstrom) to use for the spatial"
    echo "        discretization of the trajectory along the given"
    echo "        direction. Default: 0.5"
    echo
    echo "  -l    Lagtime for the estimation of the Markov model in"
    echo "        multiples of trajectory steps. Default: 1"
    echo "  -t    Real time corresponding to one trajectory step in ps."
    echo "        Default: Infer timestep from the .mdp file."
    echo "  -u    Estimate the uncertainty of the model. Note that this"
    echo "        will increase the computational cost and memory"
    echo "        consumption significantly."
    echo
    return 0
}


########################################################################
#                         Function definitions                         #
########################################################################

get_num_bins () {
    # echo
    # echo "Going to determine the number of bins for the given bin width"
    # echo "of ${bin_width}"
    
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
        # echo "box_length_z = ${box_length_z}"
        # echo "bin_width    = ${bin_width}"
        # echo "num_bins     = ${num_bins}"
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

# Required arguments
sflag=false
eflag=false

# Optional arguments
aflag=false
rflag=false

bflag=false
fflag=false
dflag=false

Dflag=false
wflag=false

lflag=false
tflag=false
uflag=false

while getopts s:e:ha:r:b:f:d:D:w:l:t:u option; do
    case "${option}" in
        # Required arguments
        s  ) sflag=true; system=${OPTARG};;
        e  ) eflag=true; settings=${OPTARG};;
        
        # Optional arguments
        h  ) information; usage; exit 0;;
        
        a  ) aflag=true; analysis_type=${OPTARG};;
        r  ) rflag=true; residue=${OPTARG};;
        
        b  ) bflag=true; begin=${OPTARG};;
        f  ) fflag=true; end=${OPTARG};;
        d  ) dflag=true; every=${OPTARG};;
        
        D  ) Dflag=true; direction=${OPTARG};;
        w  ) wflag=true; bin_width=${OPTARG};;
        
        l  ) lflag=true; lagtime=${OPTARG};;
        t  ) tflag=true; timestep="${OPTARG} ps";;
        u  ) uflag=true;;
        
        # Error management
        \? ) echo "Error: Unknown option: -${OPTARG}" >&2; usage; exit 1;;
        :  ) echo "Error: Missing option argument for -${OPTARG}" >&2; usage; exit 1;;
        *  ) echo "Error: Unimplemented option: -${OPTARG}" >&2; usage; exit 1;;
    esac
done

# Check if all required arguments are given
if [[ ${sflag} == false ]]; then
    echo
    echo "Error: -s [system] required."
    usage
    exit 1
fi
if [[ ${eflag} == false ]]; then
    echo
    echo "Error: -e [settings] required."
    usage
    exit 1
fi

# Set defaults for optional arguments
if [[ ${aflag} == false ]]; then
    analysis_type=0
fi
if [[ ${rflag} == false ]]; then
    residue=li
fi

if [[ ${bflag} == false ]]; then
    begin=0
fi
if [[ ${fflag} == false ]]; then
    end=-1
fi
if [[ ${dflag} == false ]]; then
    every=1
fi

if [[ ${Dflag} == false ]]; then
    direction=z
fi
if [[ ${wflag} == false ]]; then
    bin_width=0.5
fi
get_num_bins || exit

if [[ ${lflag} == false ]]; then
    lagtime=1
fi
if [[ ${tflag} == false ]]; then
    if [[ ${analysis_type} == 0 ]] ||\
       [[ ${analysis_type} == 2 ]] ||\
       [[ ${analysis_type} == 3 ]] ||\
       [[ ${analysis_type} == msm_mm ]]; then
        echo
        echo "timestep is not set."
        echo "Trying to get the timestep from ${settings}_${system}.mdp"
        if [ -f ${settings}_${system}.mdp ]; then
            get_timestep || exit
        else
            echo
            echo "Error: Could not get the timestep from"
            echo "  ${settings}_${system}.mdp"
            echo "  The file does not exist!"
            echo "  Set the timestep with -t manually."
            echo "  timestep = ${timestep}"
            exit 1
        fi
    fi
fi
if [[ ${uflag} == false ]]; then
    error="false"
else
    error="true"
fi


########################################################################
#                 Check if necessary input files exist                 #
########################################################################

if [[ ${analysis_type} == 0 ]] ||\
   [[ ${analysis_type} == 1 ]] ||\
   [[ ${analysis_type} == msm_discrete ]]; then
    if [ ! -f ${settings}_${system}.tpr ]; then
        echo
        echo "${settings}_${system}.tpr does not exist!"
        exit 1
    fi
    if [ ! -f ${settings}_out_${system}_pbc_whole_mol.xtc ]; then
        echo
        echo "${settings}_out_${system}_pbc_whole_mol.xtc does not exist!"
        exit 1
    fi
fi

if [[ ${analysis_type} == 2 ]] ||\
   [[ ${analysis_type} == 3 ]] ||\
   [[ ${analysis_type} == msm_its ]] ||\
   [[ ${analysis_type} == msm_mm ]]; then
    if [ ! -f ${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_traj.npy ]; then
        echo
        echo "${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_traj.npy"
        echo " does not exist!"
        exit 1
    fi
fi

if [[ ${analysis_type} == 2 ]] ||\
   [[ ${analysis_type} == 3 ]] ||\
   [[ ${analysis_type} == msm_mm ]]; then
    if [ ! -f ${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_bins.npy ]; then
        echo
        echo "${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_bins.npy"
        echo " does not exist!"
        exit 1
    fi
fi

if [[ ${analysis_type} == msm_cktest ]]; then
    if [ ! -f ${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm.h5 ]; then
        echo
        echo "${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm.h5"
        echo " does not exist!"
        exit 1
    fi
fi


########################################################################
#           Submit the scripts to the Slurm Workload Manager           #
########################################################################

if [[ ${cluster_name} == palma* ]]; then
    account=""
    partion_prio="--partition=himsshort,q0heuer,hims,express,normal"  # time <= 0-02:00:00
    partion_short="--partition=q0heuer,hims,normal"                   # time <= 2-00:00:00
    partion_long="--partition=q0heuer,hims,normal"                    # time <= 7-00:00:00
    constraint=""
elif [[ ${cluster_name} == bagheera ]]; then
    account="--account=q0heuer"
    partion_prio="--partition=prio,short,long"  # time <= 0-02:00:00
    partion_short="--partition=short,long"      # time <= 2-00:00:00
    partion_long="--partition=long"             # time <= 7-00:00:00
    constraint="--constraint=avx2|avx|fma"
else
    echo
    echo "Error: Unkown cluster name"
    echo "  cluster_name = ${cluster_name}"
    exit 1
fi
if [[ ${error} == true ]]; then
    PARTITION="${partion_long} --time=7-00:00:00"
    CPUS=4
    MEM=64G
    MEM_CKTEST=124G
else
    PARTITION="${partion_short} --time=2-00:00:00"
    CPUS=1
    MEM=8G
    MEM_CKTEST=16G
fi


scripts_submitted=0

### Start a single script by name ###
for script in ${scripts[@]}; do
    if [[ ${analysis_type} == ${script::-3} ]]; then
        if [[ ${script::-3} == msm_discrete ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete\
                   --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_slurm-%j.out\
                   ${script} ${system} ${settings} ${residue} ${begin} ${end} ${every} ${direction} ${num_bins}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-3} == msm_its ]]; then
            sbatch ${account} ${PARTITION} ${constraint}\
                   --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_its\
                   --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_its_slurm-%j.out\
                   --cpus-per-task=${CPUS}\
                   --mem=${MEM}\
                   ${script} ${system} ${settings} ${residue} ${direction} ${num_bins} ${error}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-3} == msm_mm ]]; then
            sbatch ${account} ${PARTITION} ${constraint}\
                   --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm\
                   --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm_slurm-%j.out\
                   --cpus-per-task=${CPUS}\
                   --mem=${MEM}\
                   ${script} ${system} ${settings} ${residue} ${direction} ${num_bins} ${lagtime} "${timestep}" ${error}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-3} == msm_cktest ]]; then
            sbatch ${account} ${PARTITION} ${constraint}\
                   --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_cktest\
                   --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_cktest_slurm-%j.out\
                   --cpus-per-task=${CPUS}\
                   --mem=${MEM_CKTEST}\
                   ${script} ${system} ${settings} ${residue} ${direction} ${num_bins} ${lagtime}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
        analysis_type=-1
        break
    fi
done


### Start multiple scripts by number ###
if [[ ${analysis_type} == 0 ]]; then
    # All scripts
    # msm_discrete
    job_id=$(sbatch ${account} ${partion_short} ${constraint}\
                    --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete\
                    --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_slurm-%j.out\
                    ${scripts[0]} ${system} ${settings} ${residue} ${begin} ${end} ${every} ${direction} ${num_bins}\
                    | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    # msm_its
    sbatch ${account} ${PARTITION} ${constraint}\
           --dependency=afterok:${job_id}\
           --kill-on-invalid-dep=yes\
           --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_its\
           --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_its_slurm-%j.out\
           --cpus-per-task=${CPUS}\
           --mem=${MEM}\
           ${scripts[1]} ${system} ${settings} ${residue} ${direction} ${num_bins} ${error}
    scripts_submitted=$((${scripts_submitted} + 1))
    # msm_mm
    job_id=$(sbatch ${account} ${PARTITION} ${constraint}\
                    --dependency=afterok:${job_id}\
                    --kill-on-invalid-dep=yes\
                    --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm\
                    --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm_slurm-%j.out\
                    --cpus-per-task=${CPUS}\
                    --mem=${MEM}\
                    ${scripts[2]} ${system} ${settings} ${residue} ${direction} ${num_bins} ${lagtime} "${timestep}" ${error}\
                    | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    # msm_cktest
    sbatch ${account} ${PARTITION} ${constraint}\
           --dependency=afterok:${job_id}\
           --kill-on-invalid-dep=yes\
           --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_cktest\
           --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_cktest_slurm-%j.out\
           --cpus-per-task=${CPUS}\
           --mem=${MEM_CKTEST}\
           ${scripts[3]} ${system} ${settings} ${residue} ${direction} ${num_bins} ${lagtime}
    scripts_submitted=$(( ${scripts_submitted} + 1 ))
elif [[ ${analysis_type} == 1 ]]; then
    # msm_discrete and msm_its
    # msm_discrete
    job_id=$(sbatch ${account} ${partion_short} ${constraint}\
                    --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete\
                    --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_discrete_slurm-%j.out\
                    ${scripts[0]} ${system} ${settings} ${residue} ${begin} ${end} ${every} ${direction} ${num_bins}\
                    | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    # msm_its
    sbatch ${account} ${PARTITION} ${constraint}\
           --dependency=afterok:${job_id}\
           --kill-on-invalid-dep=yes\
           --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_its\
           --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_its_slurm-%j.out\
           --cpus-per-task=${CPUS}\
           --mem=${MEM}\
           ${scripts[1]} ${system} ${settings} ${residue} ${direction} ${num_bins} ${error}
    scripts_submitted=$((${scripts_submitted} + 1))
elif [[ ${analysis_type} == 2 ]]; then
    # msm_mm and msm_cktest
    # msm_mm
    job_id=$(sbatch ${account} ${PARTITION} ${constraint}\
                    --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm\
                    --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm_slurm-%j.out\
                    --cpus-per-task=${CPUS}\
                    --mem=${MEM}\
                    ${scripts[2]} ${system} ${settings} ${residue} ${direction} ${num_bins} ${lagtime} "${timestep}" ${error}\
                    | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    # msm_cktest
    sbatch ${account} ${PARTITION} ${constraint}\
           --dependency=afterok:${job_id}\
           --kill-on-invalid-dep=yes\
           --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_cktest\
           --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_cktest_slurm-%j.out\
           --cpus-per-task=${CPUS}\
           --mem=${MEM_CKTEST}\
           ${scripts[3]} ${system} ${settings} ${residue} ${direction} ${num_bins} ${lagtime}
    scripts_submitted=$(( ${scripts_submitted} + 1 ))
elif [[ ${analysis_type} == 3 ]]; then
    # msm_its, msm_mm and msm_cktest
    # msm_its
    sbatch ${account} ${PARTITION} ${constraint}\
           --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_its\
           --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_its_slurm-%j.out\
           --cpus-per-task=${CPUS}\
           --mem=${MEM}\
           ${scripts[1]} ${system} ${settings} ${residue} ${direction} ${num_bins} ${error}
    scripts_submitted=$((${scripts_submitted} + 1))
    # msm_mm
    job_id=$(sbatch ${account} ${PARTITION} ${constraint}\
                    --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm\
                    --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_mm_slurm-%j.out\
                    --cpus-per-task=${CPUS}\
                    --mem=${MEM}\
                    ${scripts[2]} ${system} ${settings} ${residue} ${direction} ${num_bins} ${lagtime} "${timestep}" ${error}\
                    | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    # msm_cktest
    sbatch ${account} ${PARTITION} ${constraint}\
           --dependency=afterok:${job_id}\
           --kill-on-invalid-dep=yes\
           --job-name=${settings:3}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_cktest\
           --output=${settings}_${system}_msm-${direction}_${residue}_bin${num_bins}_lag${lagtime}_cktest_slurm-%j.out\
           --cpus-per-task=${CPUS}\
           --mem=${MEM_CKTEST}\
           ${scripts[3]} ${system} ${settings} ${residue} ${direction} ${num_bins} ${lagtime}
    scripts_submitted=$(( ${scripts_submitted} + 1 ))
elif [[ ${analysis_type} != -1 ]]; then
    echo
    echo "Illegal option -a ${analysis_type}"
    usage
    exit 1
fi


if [[ ${scripts_submitted} -eq 0 ]]; then
    echo
    echo "Error: No script submitted"
    exit 1
fi


echo
echo "${thisfile} done"
exit 0
