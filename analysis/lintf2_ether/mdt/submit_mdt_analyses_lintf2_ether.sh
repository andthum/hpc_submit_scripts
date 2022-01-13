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


scripts=("contact_hist_Li-O_lintf2_ether.sh")
scripts+=("contact_hist_O-Li_lintf2_ether.sh")
scripts+=("contact_hist_Li-OE_lintf2_ether.sh")
scripts+=("contact_hist_OE-Li_lintf2_ether.sh")
scripts+=("contact_hist_Li-OBT_lintf2_ether.sh")
scripts+=("contact_hist_OBT-Li_lintf2_ether.sh")
# scripts+=("contact_hist_slab-z_Li-O_lintf2_ether.sh")
# scripts+=("contact_hist_slab-z_O-Li_lintf2_ether.sh")
scripts+=("contact_hist_slab-z_Li-OE_lintf2_ether.sh")
# scripts+=("contact_hist_slab-z_OE-Li_lintf2_ether.sh")
scripts+=("contact_hist_slab-z_Li-OBT_lintf2_ether.sh")
# scripts+=("contact_hist_slab-z_OBT-Li_lintf2_ether.sh")
scripts+=("contact_hist_at_pos_change_Li-OE_lintf2_ether.sh")
scripts+=("contact_hist_at_pos_change_Li-OBT_lintf2_ether.sh")

scripts+=("topo_map_Li-OE_lintf2_ether.sh")
scripts+=("topo_map_Li-OBT_lintf2_ether.sh")

scripts+=("lifetime_autocorr_Li-OE_lintf2_ether.sh")
scripts+=("lifetime_autocorr_Li-OBT_lintf2_ether.sh")
scripts+=("lifetime_autocorr_Li-ether_lintf2_ether.sh")
scripts+=("lifetime_autocorr_Li-NTf2_lintf2_ether.sh")

scripts+=("msd_Li_lintf2_ether.sh")
scripts+=("msd_NTf2_lintf2_ether.sh")
scripts+=("msd_ether_lintf2_ether.sh")
scripts+=("msd_OE_lintf2_ether.sh")
scripts+=("msd_layer_Li_lintf2_ether.sh")
scripts+=("msd_layer_NTf2_lintf2_ether.sh")
scripts+=("msd_layer_ether_lintf2_ether.sh")
scripts+=("msd_layer_OE_lintf2_ether.sh")
scripts+=("msd_at_coord_change_Li-ether_lintf2_ether.sh")
scripts+=("msd_at_coord_change_Li-NTf2_lintf2_ether.sh")

scripts+=("renewal_events_Li-ether_lintf2_ether.sh")

scripts+=("discrete-z_Li_lintf2_ether.sh")
scripts+=("discrete-hex_Li_lintf2_ether.sh")


########################################################################
#                    Information and usage function                    #
########################################################################


information () {
    echo
    echo "Submit MDTools analysis scripts for systems containing"
    echo "Li[NTf2] and linear poly(ethylene oxides) of arbitrary length"
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
    echo "                (including discrete-z* and *at_pos_change*)"
    echo "          2   = All scripts analyzing a slab in xy plane from"
    echo "                -z to -Z"
    echo "          3.1 = All bulk contact histograms"
    echo "          3.2 = All slab-z contact histograms"
    echo "          3.3 = All contact histograms at position change"
    echo "          4   = All topology maps"
    echo "          5   = All lifetime autocorrelations"
    echo "          6.1 = All 'normal' MSDs"
    echo "          6.2 = All msd_layer"
    echo "          6.3 = All MSDs at coordination change"
    echo "        Or directly type the name of the script you want to"
    echo "        start. Works only for a single script:"
    echo "          contact_hist_Li-O             contact_hist_O-Li"
    echo "          contact_hist_Li-OE            contact_hist_OE-Li"
    echo "          contact_hist_Li-OBT           contact_hist_OBT-Li"
    echo "          contact_hist_slab-z_Li-OE     contact_hist_slab-z_Li-OBT"
    echo "          contact_hist_at_pos_change_Li-OE"
    echo "          contact_hist_at_pos_change_Li-OBT"
    echo "          topo_map_Li-OE                topo_map_Li-OBT"
    echo "          lifetime_autocorr_Li-OE       lifetime_autocorr_Li-ether"
    echo "          lifetime_autocorr_Li-OBT      lifetime_autocorr_Li-NTf2"
    echo "          msd_Li                        msd_NTf2"
    echo "          msd_ether                     msd_OE"
    echo "          msd_layer_Li                  msd_layer_NTf2"
    echo "          msd_layer_ether               msd_layer_OE"
    echo "          msd_at_coord_change_Li-ether  msd_at_coord_change_Li-NTf2"
    echo "          renewal_events_Li-ether"
    echo "          discrete-z_Li                 discrete-hex_Li"
    echo "        Default: 1"
    echo
    echo "  -b    First frame to read from trajectory. Frame numbering"
    echo "        starts at zero. Default: 0"
    echo "  -f    Last frame to read from trajectory (exclusive)."
    echo "        Default: -1 (means last frame in trajectory)"
    echo "  -d    Only read every n-th frame. Default: 1"
    echo "  -n    Number of blocks for scripts that support block"
    echo "        averaging. Default: 1"
    echo "  -r    Number of frames between restarting points for"
    echo "        analyses using the sliding widow method (like"
    echo "        calculation of mean square displacements or"
    echo "        autocorrelation functions). Default: 500"
    echo
    echo "  -c    Cutoff (in Angstrom) up to which two atoms are"
    echo "        regareded as bonded/coordinated. Default: 3.0"
#     echo "  -w    Bin width (in Angstrom) for distance resolved"
#     echo "        quantities (like RDFs or z-profiles). Default: 0.05"
    echo "  -i    Index of the lithium ion to analyze with topo_map_Li-*."
    echo "        Default: 0"
    echo "  -I    Intermittency for lifetime calculation. Maximum numer"
    echo "        of frames a selection atom is allowed to leave the"
    echo "        cutoff range of a reference atom whilst still being"
    echo "        considered to be bound to the reference atom."
    echo "        Default: 0"
    echo
    echo "  Only for scripts analyzing a slab in xy plane:"
    echo "  -z    Lower boundary (in Angstrom) of the slab in xy plane."
    echo "        Default: 0.0"
    echo "  -Z    Upper boundary (in Angstrom) of the slab in xy plane."
    echo "        Default: Maximum z box length (inferred from the final"
    echo "        .gro file)"
    echo "  -W    Slab width (in Angstrom) to use when -l or -k is set."
    echo "        Default: 1.0"
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
nflag=false
rflag=false

cflag=false
# wflag=false
iflag=false
Iflag=false

zflag=false
Zflag=false
Wflag=false
lflag=false
kflag=false

while getopts s:e:ha:b:f:d:n:r:c:i:I:z:Z:W:lk option; do
    case "${option}" in
        # Required arguments
        s  ) sflag=true; system=${OPTARG};;
        e  ) eflag=true; settings=${OPTARG};;
        
        # Optional arguments
        h  ) information; usage; exit 0;;
        
        a  ) aflag=true; analysis_type=${OPTARG};;
        
        b  ) bflag=true; begin=${OPTARG};;
        f  ) fflag=true; end=${OPTARG};;
        d  ) dflag=true; every=${OPTARG};;
        n  ) nflag=true; nblocks=${OPTARG};;
        r  ) rflag=true; restart=${OPTARG};;
        
        c  ) cflag=true; cutoff=${OPTARG};;
#         w  ) wflag=true; bin_width=${OPTARG};;
        i  ) iflag=true; li_ix=${OPTARG};;
        I  ) Iflag=true; intermittency=${OPTARG};;
        
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
    begin=0
fi
if [[ ${fflag} == false ]]; then
    end=-1
fi
if [[ ${dflag} == false ]]; then
    every=1
fi
if [[ ${nflag} == false ]]; then
    nblocks=1
fi
if [[ ${rflag} == false ]]; then
    restart=500
fi

if [[ ${cflag} == false ]]; then
    cutoff=3.0
fi
# if [[ ${wflag} == false ]]; then
#     bin_width=0.05
# fi
if [[ ${iflag} == false ]]; then
    li_ix=0
fi
if [[ ${Iflag} == false ]]; then
    intermittency=0
fi

if [[ ${zflag} == false ]]; then
    zmin=0.0
fi
if [[ ${Zflag} == false ]]; then
    zmax=$(gmx_get_box_lengths.sh -f ${settings}_out_${system}.gro -z || exit)
    zmax=$(echo "${zmax} * 10" | bc || exit)  # nm -> Angstrom
fi
if [[ ${Wflag} == false ]]; then
    slab_width=1.0
fi
if [[ ${lflag} == true ]]; then
    zmax_tot=${zmax}
fi
if [[ ${kflag} == true ]]; then
    box_length_z=$(gmx_get_box_lengths.sh -f ${settings}_out_${system}.gro -z || exit)
    box_length_z=$(echo "${box_length_z} * 10" | bc || exit)  # nm -> Angstrom
    zmin=$(echo "scale=1; (${box_length_z}-${slab_width})/2" | bc || exit)
    zmax=$(echo "scale=1; (${box_length_z}+${slab_width})/2" | bc || exit)
fi

# Check user input for consistency
zmin=$(printf "%.1f" "${zmin}" || exit)  # Round to 1 decimal place
zmax=$(printf "%.1f" "${zmax}" || exit)
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
   [[ ${analysis_type} != 0 ]] &&\
   [[ ${analysis_type} != 2 ]] &&\
   [[ ${analysis_type} != 3.2 ]] &&\
   [[ ${analysis_type} != *slab-z* ]] &&\
   [[ ${analysis_type} != discrete-hex* ]]; then
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

if [[ ${analysis_type} == 6* ]] ||\
   [[ ${analysis_type} == msd* ]] ||\
   [[ ${analysis_type} == renewal_events* ]]; then
    if [ ! -f ${settings}_out_${system}_pbc_whole_mol_nojump.xtc ]; then
        echo
        echo "${settings}_out_${system}_pbc_whole_mol_nojump.xtc does not exist!"
        exit 1
    fi
else
    if [ ! -f ${settings}_out_${system}_pbc_whole_mol.xtc ]; then
        echo
        echo "${settings}_out_${system}_pbc_whole_mol.xtc does not exist!"
        exit 1
    fi
fi

if [[ ${analysis_type} == 1 ]] ||\
   [[ ${analysis_type} == 3.3 ]] ||\
   [[ ${analysis_type} == 6.2 ]] ||\
   [[ ${analysis_type} == contact_hist_at_pos_change* ]] ||\
   [[ ${analysis_type} == msd_layer* ]] ||\
   [[ ${analysis_type} == discrete-z* ]]; then
    if [ ! -f ${settings}_${system}_Ndens-z_Li_binsA.txt ]; then
        echo
        echo "${settings}_${system}_Ndens-z_Li_binsA.txt does not exist!"
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


scripts_submitted=0

### Start a single script by name ###
for script in ${scripts[@]}; do
    if [[ ${analysis_type} == ${script::-16} ]]; then
        if [[ ${script::-16} == contact_hist_slab-z* ]] &&\
           [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.1f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_short} ${constraint}\
                       --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                       --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${zmin} ${zmax}
                scripts_submitted=$(( ${scripts_submitted} + 1 ))
                zmin=${zmax}
            done
        elif [[ ${script::-16} == contact_hist_slab-z* ]] &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                   --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${zmin} ${zmax}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == contact_hist* ]] &&\
             [[ ${script::-16} != contact_hist_slab-z* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == topo_map* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${li_ix}\
                   --output=${settings}_${system}_${script::-16}_${li_ix}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${li_ix}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == lifetime_autocorr* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${nblocks} ${restart} ${cutoff} ${intermittency}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == msd_at_coord_change* ]] ||\
             [[ ${script::-16} == renewal_events* ]]; then
                sbatch ${account} ${partion_short} ${constraint}\
                       --job-name=${settings:3}_${system}_${script::-16}\
                       --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${intermittency}
                scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == msd* ]] &&\
             [[ ${script::-16} != msd_at_coord_change* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${nblocks} ${restart}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == discrete-z* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == discrete-hex* ]] &&\
             [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.1f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_short} ${constraint}\
                       --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                       --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${every} ${zmin} ${zmax}
                scripts_submitted=$(( ${scripts_submitted} + 1 ))
                zmin=${zmax}
            done
        elif [[ ${script::-16} == discrete-hex* ]] &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                   --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${zmin} ${zmax}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
        analysis_type=-1
        break
    fi
done


### Start multiple scripts by number ###
if [[ ${analysis_type} == 0 ]]; then
    # All scripts
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == contact_hist_slab-z* ]] &&\
           [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.1f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_short} ${constraint}\
                       --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                       --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${zmin} ${zmax}
                scripts_submitted=$(( ${scripts_submitted} + 1 ))
                zmin=${zmax}
            done
        elif [[ ${script::-16} == contact_hist_slab-z* ]] &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                   --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${zmin} ${zmax}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == contact_hist* ]] &&\
             [[ ${script::-16} != contact_hist_slab-z* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == topo_map* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${li_ix}\
                   --output=${settings}_${system}_${script::-16}_${li_ix}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${li_ix}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == lifetime_autocorr* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${nblocks} ${restart} ${cutoff} ${intermittency}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == msd_at_coord_change* ]] ||\
             [[ ${script::-16} == renewal_events* ]]; then
                sbatch ${account} ${partion_short} ${constraint}\
                       --job-name=${settings:3}_${system}_${script::-16}\
                       --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${intermittency}
                scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == msd* ]] &&\
             [[ ${script::-16} != msd_at_coord_change* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${nblocks} ${restart}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == discrete-z* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == discrete-hex* ]] &&\
             [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.1f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_short} ${constraint}\
                       --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                       --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${every} ${zmin} ${zmax}
                scripts_submitted=$(( ${scripts_submitted} + 1 ))
                zmin=${zmax}
            done
        elif [[ ${script::-16} == discrete-hex* ]] &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                   --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${zmin} ${zmax}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
    done
elif [[ ${analysis_type} == 1 ]]; then
    # All scripts analyzing the bulk system
    # (including discrete-z* and *at_pos_change*)
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == contact_hist* ]] &&\
           [[ ${script::-16} != contact_hist_slab-z* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == topo_map* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${li_ix}\
                   --output=${settings}_${system}_${script::-16}_${li_ix}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${li_ix}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == lifetime_autocorr* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${nblocks} ${restart} ${cutoff} ${intermittency}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == msd_at_coord_change* ]] ||\
             [[ ${script::-16} == renewal_events* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${intermittency}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == msd* ]] &&\
             [[ ${script::-16} != msd_at_coord_change* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${nblocks} ${restart}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == discrete-z* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
    done
elif [[ ${analysis_type} == 2 ]]; then
    # All scripts analyzing a slab in xy plane from -z to -Z
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == contact_hist_slab-z* ]] &&\
           [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.1f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_short} ${constraint}\
                       --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                       --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${zmin} ${zmax}
                scripts_submitted=$(( ${scripts_submitted} + 1 ))
                zmin=${zmax}
            done
        elif [[ ${script::-16} == contact_hist_slab-z* ]] &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                   --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${zmin} ${zmax}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        elif [[ ${script::-16} == discrete-hex* ]] &&\
             [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.1f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_short} ${constraint}\
                       --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                       --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${every} ${zmin} ${zmax}
                scripts_submitted=$(( ${scripts_submitted} + 1 ))
                zmin=${zmax}
            done
        elif [[ ${script::-16} == discrete-hex* ]] &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                   --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${zmin} ${zmax}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
    done
elif [[ ${analysis_type} == 3.1 ]]; then
    # All bulk contact histograms
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == contact_hist* ]] &&\
           [[ ${script::-16} != contact_hist_slab-z* ]] &&\
           [[ ${analysis_type} != contact_hist_at_pos_change* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
    done
elif [[ ${analysis_type} == 3.2 ]]; then
    # All slab-z contact histograms
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == contact_hist_slab-z* ]] &&\
           [[ ${lflag} == true ]]; then
            while (( $(echo "${zmin} < ${zmax_tot}" | bc || exit) )); do
                zmax=$(printf "%.1f" "$(echo "${zmin} + ${slab_width}" | bc || exit)" || exit)
                sbatch ${account} ${partion_short} ${constraint}\
                       --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                       --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                       ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${zmin} ${zmax}
                scripts_submitted=$(( ${scripts_submitted} + 1 ))
                zmin=${zmax}
            done
        elif [[ ${script::-16} == contact_hist_slab-z* ]] &&\
             [[ ${lflag} == false ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${zmin}-${zmax}A\
                   --output=${settings}_${system}_${script::-16}_${zmin}-${zmax}A_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${zmin} ${zmax}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
    done
elif [[ ${analysis_type} == 3.3 ]]; then
    # All contact histograms at position change
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == contact_hist_at_pos_change* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
    done
elif [[ ${analysis_type} == 4 ]]; then
    # All topology maps
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == topo_map* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}_${li_ix}\
                   --output=${settings}_${system}_${script::-16}_${li_ix}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${li_ix}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
    done
elif [[ ${analysis_type} == 5 ]]; then
    # All lifetime autocorrelations
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == lifetime_autocorr* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${nblocks} ${restart} ${cutoff} ${intermittency}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
    done
elif [[ ${analysis_type} == 6.1 ]]; then
    # All 'normal' MSDs
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == msd* ]] &&\
           [[ ${script::-16} != msd_layer* ]] &&\
           [[ ${script::-16} != msd_at_coord_change* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${nblocks} ${restart}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
    done
elif [[ ${analysis_type} == 6.2 ]]; then
    # All msd_layer
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == msd_layer* ]]; then
            sbatch ${account} ${partion_long} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${nblocks} ${restart}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
        fi
    done
elif [[ ${analysis_type} == 6.3 ]]; then
    # All MSDs at coordination change
    if [[ ${lflag} == true ]]; then
        echo
        echo "Error: -l flag can only be used for scripts analyzing a"
        echo "  slab in xy plane"
        exit 1
    fi
    for script in ${scripts[@]}; do
        if [[ ${script::-16} == msd_at_coord_change* ]]; then
            sbatch ${account} ${partion_short} ${constraint}\
                   --job-name=${settings:3}_${system}_${script::-16}\
                   --output=${settings}_${system}_${script::-16}_slurm-%j.out\
                   ${script} ${system} ${settings} ${begin} ${end} ${every} ${cutoff} ${intermittency}
            scripts_submitted=$(( ${scripts_submitted} + 1 ))
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
