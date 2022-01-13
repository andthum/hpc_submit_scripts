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

if [[ ${cluster_name} == palma* ]]; then
    module purge || exit
    module load GCC/8.2.0-2.31.1 || exit
    module load OpenMPI/3.1.3 || exit
    module load GROMACS/2018.8 || exit
elif [[ ${cluster_name} == bagheera ]]; then
    source ${HOME}/usr/local/gromacs/bin/GMXRC || exit
else
    echo
    echo "Error: Unkown cluster name"
    echo "  cluster_name = ${cluster_name}"
    exit 1
fi


scripts=("gmx_energy_lintf2_ether.sh")
scripts+=("gmx_make_ndx_lintf2_ether.sh")
scripts+=("gmx_trjconv_whole_lintf2_ether.sh")
scripts+=("gmx_trjconv_nojump_lintf2_ether.sh")
scripts+=("mda_create_universe_lintf2_ether.sh")

# gmx msd takes the nojump trajectory, although it don't have to
scripts+=("gmx_msd_lintf2_ether.sh")             # Requires .ndx file
scripts+=("gmx_msd_tensor_lintf2_ether.sh")      # Requires .ndx file
scripts+=("gmx_msd_lateral-z_lintf2_ether.sh")   # Requires .ndx file
scripts+=("gmx_msd_parallel-z_lintf2_ether.sh")  # Requires .ndx file
scripts+=("gmx_msd_electrodes_lintf2_ether.sh")  # Requires .ndx file

scripts+=("gmx_rdf_Li_lintf2_ether.sh")
scripts+=("gmx_rdf_NBT_lintf2_ether.sh")
scripts+=("gmx_rdf_OE_lintf2_ether.sh")
scripts+=("gmx_rdf_Li-com_lintf2_ether.sh")
scripts+=("gmx_rdf_NTf2-com_lintf2_ether.sh")
scripts+=("gmx_rdf_ether-com_lintf2_ether.sh")
scripts+=("gmx_rdf_slab-z_Li_lintf2_ether.sh")
scripts+=("gmx_rdf_slab-z_NBT_lintf2_ether.sh")
scripts+=("gmx_rdf_slab-z_OE_lintf2_ether.sh")
# scripts+=("gmx_rdf_slab-z_Li-com_lintf2_ether.sh")     # Slab RDFs using
# scripts+=("gmx_rdf_slab-z_NTf2-com_lintf2_ether.sh")   # center of mass
# scripts+=("gmx_rdf_slab-z_ether-com_lintf2_ether.sh")  # often crash

scripts+=("gmx_Mdens-z_lintf2_ether.sh")         # Requires .ndx file
scripts+=("gmx_Ndens-z_lintf2_ether.sh")         # Requires .ndx file
scripts+=("gmx_Qdens-z_lintf2_ether.sh")         # Requires .ndx file
scripts+=("gmx_potential-z_lintf2_ether.sh")     # Requires .ndx file

# gmx densmap must take .trr trajectory, otherwise it may crash
scripts+=("gmx_densmap-z_Li_lintf2_ether.sh")
scripts+=("gmx_densmap-z_OBT_lintf2_ether.sh")   # Requires .ndx file
scripts+=("gmx_densmap-z_NBT_lintf2_ether.sh")   # Requires .ndx file
scripts+=("gmx_densmap-z_OE_lintf2_ether.sh")    # Requires .ndx file
scripts+=("gmx_densmap-z_gra_lintf2_ether.sh")   # Requires .ndx file

scripts+=("gmx_polystat_lintf2_ether.sh")        # Requires .ndx file


########################################################################
#                    Information and usage function                    #
########################################################################


information () {
    echo
    echo "Submit GROMACS analysis tools for systems containing Li[NTf2]"
    echo "and linear poly(ethylene oxides) of arbitrary length"
    echo "(including dimethyl ether) to the Slurm Workload Manager of"
    echo "${cluster_name}"
    echo
    return 0
}


usage () {
    echo
    echo "Usage:"
    echo
    echo "Required arguments:"
    echo "  -s    System to be analyzed. Pattern:"
    echo "        lintf2_<ether>_<mixing ratio>"
    echo "  -e    Used simulation settings. Pattern:"
    echo "        <equilibration/production>_<ensemble><temperature>_<other settings like used thermostat and barostat>"
    echo
    echo "Optional arguments:"
    echo "  -h    Show this help message and exit"
    echo
    echo "  -a    Select the analysis script(s) to be submitted."
    echo "          0   = All scripts"
    echo "          1   = All scripts analyzing the bulk system"
    echo "                (including z-profiles)"
    echo "          2   = All trjconv scripts (including create_universe)"
    echo "          3   = All MSDs"
    echo "          4   = All RDFs (bulk and slab-z)"
    echo "          4.1 = All bulk RDFs"
    echo "          4.2 = All slab-z RDFs"
    echo "          5   = All z-profiles (*dens-z and potential-z)"
    echo "          6   = All z-densmaps"
    echo "        Or directly type the name of the script you want to"
    echo "        start. Works only for a single script:"
    echo "          energy                    make_ndx"
    echo "          trjconv_whole             trjconv_nojump"
    echo "          create_universe"
    echo "          msd                       msd_tensor"
    echo "          msd_lateral-z             msd_parallel-z"
    echo "          msd_electrodes"
    echo "          rdf_Li                    rdf_Li-com"
    echo "          rdf_NBT                   rdf_NTf2-com"
    echo "          rdf_OE                    rdf_ether-com"
    echo "          rdf_slab-z_Li             rdf_slab-z_NBT"
    echo "          rdf_slab-z_OE"
    echo "          Ndens-z                   Mdens-z"
    echo "          Qdens-z                   potential-z"
    echo "          densmap-z_Li              densmap-z_OE"
    echo "          densmap-z_NBT             densmap-z_OBT"
    echo "          densmap-z_gra"
    echo "          polystat"
    echo "        Default: 1"
    echo
    echo "  -b    First frame (in ps) to read from trajectory."
    echo "        Default: 100000"
    echo "  -f    Last frame (in ps) to read from trajectory."
    echo "        Default: Last frame in .log file."
    echo "  -d    Only read frame when t MOD dt = first time (in ps)."
    echo "        Default: 1"
    echo
    echo "  -m    Start lag time (in ps) for fitting the MSD."
    echo "        Default: -1 (means begin fit after 10 %)"
    echo "  -M    End lag time (in ps) for fitting the MSD."
    echo "        Default: -1 (means fit until 90 %)"
    echo "  -r    Time (in ps) between restarting points in the"
    echo "        trajectory for MSD calculation. Default: 1000"
    echo
    echo "  -w    Bin width (in nm) for distance resolved quantities"
    echo "        (like RDFs or z-profiles). Default: 0.005"
    echo
    echo "  Only for scripts that analyze a slab in xy plane:"
    echo "  -z    Lower boundary (in nm) of the slab in xy plane."
    echo "        Default: 0.00"
    echo "  -Z    Upper boundary (in nm) of the slab in xy plane."
    echo "        Default: Maximum z box length (inferred from the final"
    echo "        .gro file)"
    echo "  -W    Slab width (in nm) to use when -l or -k is set."
    echo "        Default: 0.10"
    echo "  -l    Divide the simulation box from -z to -Z in slabs of"
    echo "        width -W and submit all scripts analyzing slabs in xy"
    echo "        plane selected with -a for each created slab."
    echo "  -k    Create a slab in xy plane of width -W exactly in the"
    echo "        middle of the simulation box (in z direction) and"
    echo "        submit all scripts analyzing slabs in xy plane"
    echo "        selected with -a for that slab."
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
        # echo "box_length_z = ${box_length_z}"
        # echo "bin_width    = ${bin_width}"
        # echo "num_bins     = ${num_bins}"
        return 0
    fi
}


########################################################################
#                           Argument parsing                           #
########################################################################

# Required arguments
sflag=false
eflag=false

# Optional arguments
aflag=false

bflag=false
fflag=false
dflag=false

mflag=false
Mflag=false
rflag=false

wflag=false

zflag=false
Zflag=false
Wflag=false
lflag=false
kflag=false

while getopts s:e:ha:b:f:d:m:M:r:w:z:Z:W:lk option; do
    case "${option}" in
        # Required arguments
        s  ) sflag=true; system=${OPTARG};;
        e  ) eflag=true; settings=${OPTARG};;
        
        # Optional arguments
        h  ) information; usage; exit 0;;
        
        a  ) aflag=true; analysis_type=${OPTARG};;
        l  ) lflag=true;;
        
        b  ) bflag=true; begin=${OPTARG};;
        f  ) fflag=true; end=${OPTARG};;
        d  ) dflag=true; dt=${OPTARG};;
        
        m  ) mflag=true; beginMSDfit=${OPTARG};;
        M  ) Mflag=true; endMSDfit=${OPTARG};;
        r  ) rflag=true; trestart=${OPTARG};;
        
        w  ) wflag=true; bin_width=${OPTARG};;
        
        z  ) zflag=true; zmin=${OPTARG};;
        Z  ) Zflag=true; zmax=${OPTARG};;
        W  ) Wflag=true; slab_width=${OPTARG};;
        l  ) lflag=true;;
        k  ) kflag=true;;
        
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
    analysis_type=1
fi

if [[ ${bflag} == false ]]; then
    begin=100000
fi
if [[ ${fflag} == false ]]; then
    end=$(gmx_get_last_time.sh -f ${settings}_out_${system}.log || exit)
    end=$(echo "${end%%.*}" || exit)
fi
if [[ ${dflag} == false ]]; then
    dt=1
fi

if [[ ${mflag} == false ]]; then
    beginMSDfit=-1
fi
if [[ ${Mflag} == false ]]; then
    endMSDfit=-1
fi
if [[ ${rflag} == false ]]; then
    trestart=1000
fi

if [[ ${wflag} == false ]]; then
    bin_width=0.005
fi

if [[ ${zflag} == false ]]; then
    zmin=0.00
fi
if [[ ${Zflag} == false ]]; then
    zmax=$(gmx_get_box_lengths.sh -f ${settings}_out_${system}.gro -z || exit)
fi
if [[ ${Wflag} == false ]]; then
    slab_width=0.10
fi
if [[ ${lflag} == true ]]; then
    zmax_tot=${zmax}
fi
if [[ ${kflag} == true ]]; then
    box_length_z=$(gmx_get_box_lengths.sh -f ${settings}_out_${system}.gro -z || exit)
    zmin=$(echo "scale=2; (${box_length_z}-${slab_width})/2" | bc || exit)
    zmax=$(echo "scale=2; (${box_length_z}+${slab_width})/2" | bc || exit)
fi

if [[ ${analysis_type} == 0 ]] ||\
   [[ ${analysis_type} == 1 ]] ||\
   [[ ${analysis_type} == 5 ]] ||\
   [[ ${analysis_type} == *dens-z ]] ||\
   [[ ${analysis_type} == potential-z ]];then
    get_num_bins || exit
fi

# Check user input for consistency
zmin=$(printf "%.2f" "${zmin}" || exit)  # Round to 2 decimal places
zmax=$(printf "%.2f" "${zmax}" || exit)
if (( $(echo "${zmax} <= ${zmin}" | bc || exit) )); then
    echo
    echo "Error: zmax <= zmin"
    echo "  zmax = ${zmax}"
    echo "  zmin = ${zmin}"
    exit 1
fi
if [[ ${lflag} == true ]] &&\
   (( $(echo "${zmax} - ${zmin} < ${slab_width}" | bc || exit) )); then
    echo
    echo "Error: zmax-zmin < slab_width"
    echo "  zmax       = ${zmax}"
    echo "  zmin       = ${zmin}"
    echo "  slab_width = ${slab_width}"
    exit 1
fi
if [[ ${lflag} == true ]] &&\
   ( [[ ${analysis_type} != 0 ]] ||\
     [[ ${analysis_type} != 4.2 ]] ||\
     [[ ${analysis_type} != 6 ]] ||\
     [[ ${analysis_type} != *slab-z* ]] ||\
     [[ ${analysis_type} != densmap-z* ]] ); then
    echo
    echo "Error: -l flag can only be used for scripts analyzing a slab"
    echo "  in xy plane"
    exit 1
fi
if [[ ${lflag} == true ]] && [[ ${kflag} == true ]]; then
    echo
    echo "Error: -l and -k are cannot be given at the same time"
    exit 1
fi
if [[ ${kflag} == true ]] &&\
   ( [[ ${zflag} == true ]] || [[ ${Zflag} == true ]] ); then
    echo
    echo "Note: -z ${zmin} and -Z ${zmax} will be ignored, because -k"
    echo "  is set"
fi


########################################################################
#                 Check if necessary input files exist                 #
########################################################################

if [ ! -f ${settings}_${system}.tpr ]; then
    echo
    echo "${settings}_${system}.tpr does not exist!"
    exit 1
fi

if [[ ${analysis_type} == 0 ]] ||\
   [[ ${analysis_type} == 1 ]] ||\
   [[ ${analysis_type} == energy ]]; then
    if [ ! -f ${settings}_out_${system}.edr ]; then
        echo
        echo "${settings}_out_${system}.edr does not exist!"
        exit 1
    fi
fi

if [[ ${analysis_type} == 0 ]] ||\
   [[ ${analysis_type} == 1 ]] ||\
   [[ ${analysis_type} == 2 ]] ||\
   [[ ${analysis_type} == 6 ]] ||\
   [[ ${analysis_type} == trjconv_whole ]] ||\
   [[ ${analysis_type} == densmap-z* ]]; then
    if [ ! -f ${settings}_out_${system}.trr ]; then
        echo
        echo "${settings}_out_${system}.trr does not exist!"
        exit 1
    fi
fi
if [[ ${analysis_type} != 0 ]] &&\
   [[ ${analysis_type} != 1 ]] &&\
   [[ ${analysis_type} != 2 ]] &&\
   [[ ${analysis_type} != 6 ]] &&\
   [[ ${analysis_type} != energy ]] &&\
   [[ ${analysis_type} != make_ndx ]] &&\
   [[ ${analysis_type} != trjconv_whole ]] &&\
   [[ ${analysis_type} != densmap-z* ]]; then
    if [ ! -f ${settings}_out_${system}_pbc_whole_mol.xtc ]; then
        echo
        echo "${settings}_out_${system}_pbc_whole_mol.xtc does not exist!"
        exit 1
    fi
fi
if [[ ${analysis_type} == 3 ]] ||\
   [[ ${analysis_type} == msd* ]]; then
    if [ ! -f ${settings}_out_${system}_pbc_whole_mol_nojump.xtc ]; then
        echo
        echo "${settings}_out_${system}_pbc_whole_mol_nojump.xtc does"
        echo "not exist!"
        exit 1
    fi
fi

if [[ ${analysis_type} != 0 ]] &&\
   [[ ${analysis_type} != 1 ]] &&\
   [[ ${analysis_type} != 2 ]] &&\
   [[ ${analysis_type} != 4* ]] &&\
   [[ ${analysis_type} != energy ]] &&\
   [[ ${analysis_type} != make_ndx ]] &&\
   [[ ${analysis_type} != trjconv* ]] &&\
   [[ ${analysis_type} != create_universe* ]] &&\
   [[ ${analysis_type} != rdf* ]] &&\
   [[ ${analysis_type} != densmap-z_Li ]]; then
    if [ ! -f ${system}.ndx ]; then
        echo
        echo "${system}.ndx does not exist!"
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
    constraint="--constraint=avx2"
else
    echo
    echo "Error: Unkown cluster name"
    echo "  cluster_name = ${cluster_name}"
    exit 1
fi


scripts_submitted=0

### Start a single script by name ###
for script in ${scripts[@]}; do
    if [[ ${analysis_type} == ${script:4:-16} ]]; then
        if [[ ${script:4:-16} == energy ]]; then
            sbatch ${account} ${partion_prio} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == make_ndx ]]; then
            sbatch ${account} ${partion_prio} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == trjconv* ]] ||\
             [[ ${script:4:-16} == polystat ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == create_universe ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == msd_electrodes ]] &&\
             [[ ${system} != *gra* ]]; then
            echo
            echo "Note: ${script:4:-16} will not be submitted, because"
            echo "  the system contains no electrodes"
            echo "  system = ${system}"
        elif [[ ${script:4:-16} == msd* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${beginMSDfit} ${endMSDfit} ${trestart}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == densmap-z_gra ]] &&\
             [[ ${system} != *gra* ]]; then
            echo
            echo "Note: ${script:4:-16} will not be submitted, because"
            echo "  the system contains no electrodes"
            echo "  system = ${system}"
        elif ( [[ ${script:4:-16} == rdf_slab-z* ]] ||\
               [[ ${script:4:-16} == densmap-z* ]] ) &&\
             [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.2f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_long} ${constraint}\
                       --job-name=${settings:3}_${system}_${script:4:-16}_${zmin}-${zmax}nm\
                       --output=${settings}_${system}_${script:4:-16}_${zmin}-${zmax}nm_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width} ${zmin} ${zmax}
                scripts_submitted=$((${scripts_submitted} + 1))
                zmin=${zmax}
            done
        elif ( [[ ${script:4:-16} == rdf_slab-z* ]] ||\
               [[ ${script:4:-16} == densmap-z* ]] ) &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}_${zmin}-${zmax}nm\
                   --output=${settings}_${system}_${script:4:-16}_${zmin}-${zmax}nm_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width} ${zmin} ${zmax}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == rdf* ]]  &&\
             [[ ${script:4:-16} != rdf_slab-z* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == *dens-z ]] ||\
             [[ ${script:4:-16} == potential-z ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${num_bins}
            scripts_submitted=$((${scripts_submitted} + 1))
        fi
        analysis_type=-1
        break
    fi
done


### Start multiple scripts by number ###
if [[ ${analysis_type} == 0 ]]; then
    # All scripts
    # energy
    sbatch ${account} ${partion_prio} ${constraint}\
           --job-name=${settings:3}_${system}_${scripts[0]:4:-16}\
           --output=${settings}_${system}_${scripts[0]:4:-16}_slurm-%j.out\
           ${scripts[0]} ${system} ${settings} ${begin} ${end}
    scripts_submitted=$((${scripts_submitted} + 1))
    # make_ndx
    job_id_make_ndx=$(sbatch ${account} ${partion_prio} ${constraint}\
                             --job-name=${settings:3}_${system}_${scripts[1]:4:-16}\
                             --output=${settings}_${system}_${scripts[1]:4:-16}_slurm-%j.out\
                             ${scripts[1]} ${system} ${settings}\
                      | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    # trjconv_whole
    job_id_trjconv_whole=$(sbatch ${account} ${partion_short} ${constraint}\
                                  --dependency=afterok:${job_id_make_ndx}\
                                  --kill-on-invalid-dep=yes\
                                  --job-name=${settings:3}_${system}_${scripts[2]:4:-16}\
                                  --output=${settings}_${system}_${scripts[2]:4:-16}_slurm-%j.out\
                                  ${scripts[2]} ${system} ${settings} ${begin} ${end} ${dt}\
                           | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    # trjconv_nojump
    job_id_trjconv_nojump=$(sbatch ${account} ${partion_short} ${constraint}\
                                   --dependency=afterok:${job_id_trjconv_whole}\
                                   --kill-on-invalid-dep=yes\
                                   --job-name=${settings:3}_${system}_${scripts[3]:4:-16}\
                                   --output=${settings}_${system}_${scripts[3]:4:-16}_slurm-%j.out\
                                   ${scripts[3]} ${system} ${settings} ${begin} ${end} ${dt}\
                           | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    for script in ${scripts[@]}; do
        if [[ ${script:4:-16} == create_universe ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --dependency=afterok:${job_id_trjconv_nojump}\
                   --kill-on-invalid-dep=yes\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == polystat ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --dependency=afterok:${job_id_trjconv_whole}\
                   --kill-on-invalid-dep=yes\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == msd_electrodes ]] &&\
             [[ ${system} != *gra* ]]; then
            echo
            echo "Note: ${script:4:-16} will not be submitted, because"
            echo "  the system contains no electrodes"
            echo "  system = ${system}"
        elif [[ ${script:4:-16} == msd* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --dependency=afterok:${job_id_trjconv_nojump}\
                   --kill-on-invalid-dep=yes\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${beginMSDfit} ${endMSDfit} ${trestart}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == densmap-z_gra ]] &&\
             [[ ${system} != *gra* ]]; then
            echo
            echo "Note: ${script:4:-16} will not be submitted, because"
            echo "  the system contains no electrodes"
            echo "  system = ${system}"
        elif ( [[ ${script:4:-16} == rdf_slab-z* ]] ||\
               [[ ${script:4:-16} == densmap-z* ]] ) &&\
             [[ ${lflag} == true ]]; then
            if [[ ${script:4:-16} == rdf_slab-z* ]]; then
                job_id=${job_id_trjconv_whole}
            elif [[ ${script:4:-16} == densmap-z* ]]; then
                job_id=${job_id_make_ndx}
            fi
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.2f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_long} ${constraint}\
                       --dependency=afterok:${job_id}\
                       --kill-on-invalid-dep=yes\
                       --job-name=${settings:3}_${system}_${script:4:-16}_${zmin}-${zmax}nm\
                       --output=${settings}_${system}_${script:4:-16}_${zmin}-${zmax}nm_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width} ${zmin} ${zmax}
                scripts_submitted=$((${scripts_submitted} + 1))
                zmin=${zmax}
            done
        elif ( [[ ${script:4:-16} == rdf_slab-z* ]] ||\
               [[ ${script:4:-16} == densmap-z* ]] ) &&\
             [[ ${lflag} == false ]]; then
            if [[ ${script:4:-16} == rdf_slab-z* ]]; then
                job_id=${job_id_trjconv_whole}
            elif [[ ${script:4:-16} == densmap-z* ]]; then
                job_id=${job_id_make_ndx}
            fi
            sbatch ${account} ${partion_long} ${constraint}\
                   --dependency=afterok:${job_id}\
                   --kill-on-invalid-dep=yes\
                   --job-name=${settings:3}_${system}_${script:4:-16}_${zmin}-${zmax}nm\
                   --output=${settings}_${system}_${script:4:-16}_${zmin}-${zmax}nm_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width} ${zmin} ${zmax}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == rdf* ]] &&\
             [[ ${script:4:-16} != rdf_slab-z* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --dependency=afterok:${job_id_trjconv_whole}\
                   --kill-on-invalid-dep=yes\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == *dens-z ]] ||\
             [[ ${script:4:-16} == potential-z ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --dependency=afterok:${job_id_trjconv_whole}\
                   --kill-on-invalid-dep=yes\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${num_bins}
            scripts_submitted=$((${scripts_submitted} + 1))
        fi
    done
elif [[ ${analysis_type} == 1 ]]; then
    # All scripts analyzing the bulk system (including z-profiles)
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    # energy
    sbatch ${account} ${partion_prio} ${constraint}\
           --job-name=${settings:3}_${system}_${scripts[0]:4:-16}\
           --output=${settings}_${system}_${scripts[0]:4:-16}_slurm-%j.out\
           ${scripts[0]} ${system} ${settings} ${begin} ${end}
    scripts_submitted=$((${scripts_submitted} + 1))
    # make_ndx
    job_id_make_ndx=$(sbatch ${account} ${partion_prio} ${constraint}\
                             --job-name=${settings:3}_${system}_${scripts[1]:4:-16}\
                             --output=${settings}_${system}_${scripts[1]:4:-16}_slurm-%j.out\
                             ${scripts[1]} ${system} ${settings}\
                      | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    # trjconv_whole
    job_id_trjconv_whole=$(sbatch ${account} ${partion_short} ${constraint}\
                                  --dependency=afterok:${job_id_make_ndx}\
                                  --kill-on-invalid-dep=yes\
                                  --job-name=${settings:3}_${system}_${scripts[2]:4:-16}\
                                  --output=${settings}_${system}_${scripts[2]:4:-16}_slurm-%j.out\
                                  ${scripts[2]} ${system} ${settings} ${begin} ${end} ${dt}\
                           | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    # trjconv_nojump
    job_id_trjconv_nojump=$(sbatch ${account} ${partion_short} ${constraint}\
                                   --dependency=afterok:${job_id_trjconv_whole}\
                                   --kill-on-invalid-dep=yes\
                                   --job-name=${settings:3}_${system}_${scripts[3]:4:-16}\
                                   --output=${settings}_${system}_${scripts[3]:4:-16}_slurm-%j.out\
                                   ${scripts[3]} ${system} ${settings} ${begin} ${end} ${dt}\
                           | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    for script in ${scripts[@]}; do
        if [[ ${script:4:-16} != *slab* ]] &&\
           [[ ${script:4:-16} != densmap-z* ]]; then
            if [[ ${script:4:-16} == create_universe ]]; then
                sbatch ${account} ${partion_short} ${constraint}\
                       --dependency=afterok:${job_id_trjconv_nojump}\
                       --kill-on-invalid-dep=yes\
                       --job-name=${settings:3}_${system}_${script:4:-16}\
                       --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                       ${script} ${system} ${settings}
                scripts_submitted=$((${scripts_submitted} + 1))
            elif [[ ${script:4:-16} == polystat ]]; then
                sbatch ${account} ${partion_short} ${constraint}\
                       --dependency=afterok:${job_id_trjconv_whole}\
                       --kill-on-invalid-dep=yes\
                       --job-name=${settings:3}_${system}_${script:4:-16}\
                       --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${dt}
                scripts_submitted=$((${scripts_submitted} + 1))
            elif [[ ${script:4:-16} == msd_electrodes ]] &&\
                 [[ ${system} != *gra* ]]; then
                echo
                echo "Note: ${script:4:-16} will not be submitted, because"
                echo "  the system contains no electrodes"
                echo "  system = ${system}"
            elif [[ ${script:4:-16} == msd* ]]; then
                sbatch ${account} ${partion_long} ${constraint}\
                       --dependency=afterok:${job_id_trjconv_nojump}\
                       --kill-on-invalid-dep=yes\
                       --job-name=${settings:3}_${system}_${script:4:-16}\
                       --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${beginMSDfit} ${endMSDfit} ${trestart}
                scripts_submitted=$((${scripts_submitted} + 1))
            elif [[ ${script:4:-16} == rdf* ]] &&\
                 [[ ${script:4:-16} != rdf_slab-z* ]]; then
                sbatch ${account} ${partion_long} ${constraint}\
                       --dependency=afterok:${job_id_trjconv_whole}\
                       --kill-on-invalid-dep=yes\
                       --job-name=${settings:3}_${system}_${script:4:-16}\
                       --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width}
                scripts_submitted=$((${scripts_submitted} + 1))
            elif [[ ${script:4:-16} == *dens-z ]] ||\
                 [[ ${script:4:-16} == potential-z ]]; then
                sbatch ${account} ${partion_short} ${constraint}\
                       --dependency=afterok:${job_id_trjconv_whole}\
                       --kill-on-invalid-dep=yes\
                       --job-name=${settings:3}_${system}_${script:4:-16}\
                       --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${dt} ${num_bins}
                scripts_submitted=$((${scripts_submitted} + 1))
            fi
        fi
    done
elif [[ ${analysis_type} == 2 ]]; then
    # All trjconv scripts (including create_universe)
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    # trjconv_whole
    job_id_trjconv_whole=$(sbatch ${account} ${partion_short} ${constraint}\
                                  --dependency=afterok:${job_id_make_ndx}\
                                  --kill-on-invalid-dep=yes\
                                  --job-name=${settings:3}_${system}_${scripts[2]:4:-16}\
                                  --output=${settings}_${system}_${scripts[2]:4:-16}_slurm-%j.out\
                                  ${scripts[2]} ${system} ${settings} ${begin} ${end} ${dt}\
                           | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    # trjconv_nojump
    job_id_trjconv_nojump=$(sbatch ${account} ${partion_short} ${constraint}\
                                   --dependency=afterok:${job_id_trjconv_whole}\
                                   --kill-on-invalid-dep=yes\
                                   --job-name=${settings:3}_${system}_${scripts[3]:4:-16}\
                                   --output=${settings}_${system}_${scripts[3]:4:-16}_slurm-%j.out\
                                   ${scripts[3]} ${system} ${settings} ${begin} ${end} ${dt}\
                           | sed 's/[^0-9]*//g' || exit)
    scripts_submitted=$((${scripts_submitted} + 1))
    for script in ${scripts[@]}; do
        if [[ ${script:4:-16} == create_universe ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --dependency=afterok:${job_id_trjconv_nojump}\
                   --kill-on-invalid-dep=yes\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings}
            scripts_submitted=$((${scripts_submitted} + 1))
        fi
    done
elif [[ ${analysis_type} == 3 ]]; then
    # All MSDs
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script:4:-16} == msd_electrodes ]] &&\
           [[ ${system} != *gra* ]]; then
            echo
            echo "Note: ${script:4:-16} will not be submitted, because"
            echo "  the system contains no electrodes"
            echo "  system = ${system}"
        elif [[ ${script:4:-16} == msd* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${beginMSDfit} ${endMSDfit} ${trestart}
            scripts_submitted=$((${scripts_submitted} + 1))
        fi
    done
elif [[ ${analysis_type} == 4 ]]; then
    # All RDFs (bulk and slab-z)
    for script in ${scripts[@]}; do
        if [[ ${script:4:-16} == rdf_slab-z* ]] &&\
           [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.2f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_long} ${constraint}\
                       --job-name=${settings:3}_${system}_${script:4:-16}_${zmin}-${zmax}nm\
                       --output=${settings}_${system}_${script:4:-16}_${zmin}-${zmax}nm_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width} ${zmin} ${zmax}
                scripts_submitted=$((${scripts_submitted} + 1))
                zmin=${zmax}
            done
        elif [[ ${script:4:-16} == rdf_slab-z* ]] &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}_${zmin}-${zmax}nm\
                   --output=${settings}_${system}_${script:4:-16}_${zmin}-${zmax}nm_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width} ${zmin} ${zmax}
            scripts_submitted=$((${scripts_submitted} + 1))
        elif [[ ${script:4:-16} == rdf* ]] &&\
             [[ ${script:4:-16} != rdf_slab-z* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width}
            scripts_submitted=$((${scripts_submitted} + 1))
        fi
    done
elif [[ ${analysis_type} == 4.1 ]]; then
    # All bulk RDFs
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script:4:-16} == rdf* ]] &&\
           [[ ${script:4:-16} != rdf_slab-z* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width}
            scripts_submitted=$((${scripts_submitted} + 1))
        fi
    done
elif [[ ${analysis_type} == 4.2 ]]; then
    # All slab-z RDFs
    for script in ${scripts[@]}; do
        if [[ ${script:4:-16} == rdf_slab-z* ]] &&\
           [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.2f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_long} ${constraint}\
                       --job-name=${settings:3}_${system}_${script:4:-16}_${zmin}-${zmax}nm\
                       --output=${settings}_${system}_${script:4:-16}_${zmin}-${zmax}nm_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width} ${zmin} ${zmax}
                scripts_submitted=$((${scripts_submitted} + 1))
                zmin=${zmax}
            done
        elif [[ ${script:4:-16} == rdf_slab-z* ]] &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}_${zmin}-${zmax}nm\
                   --output=${settings}_${system}_${script:4:-16}_${zmin}-${zmax}nm_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width} ${zmin} ${zmax}
            scripts_submitted=$((${scripts_submitted} + 1))
        fi
    done
elif [[ ${analysis_type} == 5 ]]; then
    # All z-profiles (*dens-z and potential-z)
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script:4:-16} == *dens-z ]] ||\
           [[ ${script:4:-16} == potential-z ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}\
                   --output=${settings}_${system}_${script:4:-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${num_bins}
            scripts_submitted=$((${scripts_submitted} + 1))
        fi
    done
elif [[ ${analysis_type} == 6 ]]; then
    # All z-densmaps
    for script in ${scripts[@]}; do
        if [[ ${script:4:-16} == densmap-z_gra ]] &&\
           [[ ${system} != *gra* ]]; then
            echo
            echo "Note: ${script:4:-16} will not be submitted, because"
            echo "  the system contains no electrodes"
            echo "  system = ${system}"
        elif [[ ${script:4:-16} == densmap-z* ]] &&\
             [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.2f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_long} ${constraint}\
                       --job-name=${settings:3}_${system}_${script:4:-16}_${zmin}-${zmax}nm\
                       --output=${settings}_${system}_${script:4:-16}_${zmin}-${zmax}nm_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width} ${zmin} ${zmax}
                scripts_submitted=$((${scripts_submitted} + 1))
                zmin=${zmax}
            done
        elif [[ ${script:4:-16} == densmap-z* ]] &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script:4:-16}_${zmin}-${zmax}nm\
                   --output=${settings}_${system}_${script:4:-16}_${zmin}-${zmax}nm_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${dt} ${bin_width} ${zmin} ${zmax}
            scripts_submitted=$((${scripts_submitted} + 1))
        fi
    done
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
