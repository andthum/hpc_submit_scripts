#!/usr/bin/env python3

# MIT License
# Copyright (c) 2021-2023  All authors listed in the file AUTHORS.rst


r"""
Submit |MDTools| analysis scripts for systems containing LiTFSI and
linear poly(ethylene oxides) of arbitrary length (including dimethyl
ether) to the |Slurm| Workload Manager of an HPC cluster.

This script is designed to be used on the |Palma2| HPC cluster of the
University of Münster or on the |Bagheera| HPC cluster of the
|RG_of_Professor_Heuer|.

Options
-------
Required Arguments
^^^^^^^^^^^^^^^^^^
--system
    The name of the system to analyze, e.g. ``'LiTFSI_PEO_20-1'`` for
    an LiTFSI/PEO electrolyte with an ether-oxygen-to-lithium ratio of
    20:1.  You can give any string here.  See notes below.
--settings
    The used simulation settings, e.g. ``'pr_npt298_pr_nh'`` for a
    production run in an NPT ensemble at 298 K utilizing a
    Parrinello-Rahman barostat and an Nose-Hoover thermostat.  You can
    give any string here.  See notes below.
--scripts
    Select the analysis script(s) to submit.  Either give the name(s) of
    the script(s) (without file extension) or give one of the following
    number options.  If you give multiple script names, provide them
    space-separated as one enquoted string.  To list all possible script
    names type
    :bash:`ls path/to/hpc_submit_scripts/analysis/lintf2_ether/mdt/`.
    Note that scripts that take an |edr_file| or an |trr_file| as input
    are excluded from the number options unless they are explicitly
    mentioned to be included.

        :0:     All scripts.  Note that all lig_change_at_pos_change*
                scripts are excluded.
        :1:     All scripts analyzing the bulk system (i.e. exclude
                scripts that analyze only a part, e.g. a slab, of the
                system, but still include anisotropic analyses, e.g.
                spatially discretized analyses).  Note that all
                lig_change_at_pos_change* scripts are excluded.
        :2:     All scripts analyzing a slab in xy plane.

        :3:     All discrete-z_Li* scripts.
        :4:     All hexagonal discretizations.
        :5:     All density distributions along hexagonal axes.

        :6:     All contact histograms.
        :6.1:   All "normal" bulk contact histograms.
        :6.2:   All slab-z contact histograms.
        :6.3:   All contact histograms at position change.
        :7:     All scripts analyzing coordination changes at position
                changes (lig_change_at_pos_change*).
        :8:     All topological maps.

        :9:     All MSDs.
        :9.1:   All "normal" bulk MSDs.
        :9.2:   All spatially discretized MSDs.
        :9.3:   All MSDs at coordination change.
        :10:    All lifetime autocorrelations.
        :11:    All renewal event analyses.
        :11.1:  All scripts extracting renewal events.
        :11.2:  All scripts working on renewal event trajectories.
        :11.3:  All bulk scripts working on renewal event trajectories.
        :11.4:  All spatially discretized scripts working on renewal
                event trajectories.

        :12:    All scripts that take an |edr_file| or an |trr_file| as
                input.
        :13:    All attribute histograms (attribute_hist*).

Options for Trajectory Reading
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--begin
    First frame to read from the trajectory.  Frame numbering starts at
    zero.  Default: ``0``.
--end
    Last frame to read from the trajectory.  This is exclusive, i.e. the
    last frame read is actually ``END - 1``.  A value of ``-1`` means to
    read the very last frame.  Default: ``-1``.
--every
    Read every n-th frame from the trajectory.  Default: ``1``.
--nblocks
    Number of blocks for scripts that support block averaging.  Default:
    ``1``.
--restart
    Number of frames between restarting points for analyses using the
    sliding widow method (like calculation of mean square displacements
    or autocorrelation functions).  Default: 500"

Options for Distance Resolved Quantities (like RDFs)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--binwidth
    Bin width (in Angstrom) for distance resolved quantities.  Default:
    ``0.05``.

Options for Contact Analyses
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--cutoff
    Cutoff (in Angstrom) up to which two atoms are regarded as being in
    contact.  Default: ``3.0``.

Options for Single Atom Analyses
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--atom-index
    Index of the atom to analyze.  Default: ``0``.

Options for Analyses of Sequences of Discrete States
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--intermittency
    Maximum number of frames a selection compound is allowed to leave a
    certain state whilst still being considered to be inside that state,
    provided that it is indeed again inside this state after the
    intermittent period.  Default: ``0``.
--lag-compare
    Lag time (in trajectory frames) after which to compare the states of
    a selection compound.  Default: ``50``.
--min-block-size
    Minimum block size (in trajectory frames).  Blocks of consecutive
    frames in which a given selection compound stays in the same state
    must comprise at least this many frames in order to be counted as
    valid block.  Default: ``100``.
--max-gap-size
    Maximum gap size (in trajectory frames).  The gap between two
    following valid blocks must not be greater than this many frames in
    order to count a transition between the two valid blocks as valid
    transition.  Default: ``25``.

Options for Tools That Analyze Slabs in xy Plane
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--zmin
    Lower boundary (in Angstrom) of the slab in xy plane.  Default:
    ``0``.
--zmax
    Upper boundary (in Angstrom) of the slab in xy plane.  Default:
    Maximum length of the simulation box in z direction (inferred from
    :file:`${settings}_out_${system}.gro`).
--slabwidth
    Slab width (in Angstrom) to use when \--discretize or \--center-slab
    is given.  Default: ``1.0``.
--discretize
    Divide the simulation box from \--zmin to \--zmax in slabs of width
    \--slabwidth and submit all scripts analyzing slabs in xy plane that
    were selected with \--scripts for each created slab.  Must not be
    used together with \--center-slab.
--center-slab
    Create a slab in xy plane of width \--slabwidth exactly in the
    center of the simulation box (in z direction, inferred from
    :file:`${settings}_out_${system}.gro`) and submit all scripts
    analyzing slabs in xy plane that were selected with \--scripts for
    that slab.  Must not be used together with \--discretize.  If given,
    \--zmin and \--zmax are ignored.

Python-Specific Options
^^^^^^^^^^^^^^^^^^^^^^^
--py-lmod
    If running on a cluster which uses the |Lmod| module system,
    specify here which file to source (relative to the :file:`lmod`
    subdirectory of this project) to load Python.  Default:
    ``'palma/2019a/python3-7-2.sh'``.
--py-exe
    Name of the Python executable.  You can give here e.g. the path to
    the python executable of the |virtual_Python_environment| in which
    MDTools is installed.  Default: ``'python3'``.
--mdt-path
    Path to the *cloned* MDTools repository.  Note that you really need
    to clone MDTools
    (:bash:`git clone https://github.com/andthum/mdtools.git`) and
    install MDTools from the cloned repository.  For the last step refer
    to MDTools' `documentation
    <https://mdtools.readthedocs.io/en/latest/doc_pages/general_docs/installation.html>`_.
    The reason for this is that the Slurm job scripts (that are launched
    by this Python submit script) use the path to MDTools'
    :file:`scripts/` directory to call the MDTools scripts.  Default:
    ``'${HOME}/git/github/mdtools'``.

Sbatch Options
^^^^^^^^^^^^^^
You can provide arbitrary other options to this script.  All these other
options are parsed directly to the |sbatch| Slurm command without
further introspection or validation.  This means, you can parse any
option to sbatch but you are responsible for providing correct options.

Config File
-----------
This script reads options from the following sections of a
|config_file|:

    * [submit]
    * [submit.analysis]
    * [submit.analysis.lintf2_ether]
    * [submit.analysis.lintf2_ether.mdt]
    * [sbatch]
    * [sbatch.analysis]
    * [sbatch.analysis.lintf2_ether]
    * [sbatch.analysis.lintf2_ether.mdt]

Notes
-----
The \--system and \--settings options allow (or enforces) you to choose
systematic names for the input and output files of your simulations.
Besides a better overview, this enables an easy automation of
preparation and analysis tasks.

If input files required for the scripts selected with \--scripts cannot
be found, the submission script will terminate with an error message
before submitting the job(s) to the Slurm Workload Manager.
"""


# Add your name if you contribute to this script.  Use a comma separated
# list: "Author 1, Author 2, Author 3".  Authors should be ordered
# alphabetically by their full name.
__author__ = "Andreas Thum"


# Standard libraries
import argparse
import copy
import os
import shlex
import subprocess as subproc
import sys
import warnings


FILE_ROOT = os.path.abspath(os.path.dirname(__file__))
PYTHON_DIR = os.path.abspath(os.path.join(FILE_ROOT, "../../../python"))
if not os.path.isdir(PYTHON_DIR):
    raise FileNotFoundError(
        "No such directory: '{}'.  This might happen if you change the"
        " directory structure of this project".format(PYTHON_DIR)
    )
sys.path.insert(1, PYTHON_DIR)


# First-party libraries
import gmx  # noqa: E402
import opthandler  # noqa: E402
import strng  # noqa: E402


ARG_PREC = 2  # Precision of floats parsed to batch scripts.
BASH_DIR = os.path.abspath(os.path.join(FILE_ROOT, "../../../bash"))
if not os.path.isdir(BASH_DIR):
    raise FileNotFoundError(
        "No such directory: '{}'.  This might happen if you change the"
        " directory structure of this project".format(BASH_DIR)
    )
REQUIRE_TPR = (
    # `${settings}_${system}.tpr`
    "axial_hex_dist_1nn_Li",
    "axial_hex_dist_1nn_NBT",
    "axial_hex_dist_1nn_OBT",
    "axial_hex_dist_1nn_OE",
    "axial_hex_dist_2nn_Li",
    "axial_hex_dist_2nn_NBT",
    "axial_hex_dist_2nn_OBT",
    "axial_hex_dist_2nn_OE",
    "contact_hist_Li-O",
    "contact_hist_Li-OBT",
    "contact_hist_Li-OE",
    "contact_hist_O-Li",
    "contact_hist_OBT-Li",
    "contact_hist_OE-Li",
    "contact_hist_at_pos_change_Li-OBT",
    "contact_hist_at_pos_change_Li-OE",
    "contact_hist_slab-z_Li-OBT",
    "contact_hist_slab-z_Li-OE",
    "create_mda_universe",
    "discrete-hex_Li",
    "discrete-hex_NBT",
    "discrete-hex_OBT",
    "discrete-hex_OE",
    "discrete-z_Li",
    "lifetime_autocorr_Li-ether",
    "lifetime_autocorr_Li-NTf2",
    "lifetime_autocorr_Li-OBT",
    "lifetime_autocorr_Li-OE",
    "lig_change_at_pos_change_Li-OBT",
    "lig_change_at_pos_change_Li-OE",
    "lig_change_at_pos_change_blocks_Li-OBT",
    "lig_change_at_pos_change_blocks_Li-OE",
    "lig_change_at_pos_change_blocks_hist_Li-OBT",
    "lig_change_at_pos_change_blocks_hist_Li-OE",
    "msd_ether",
    "msd_Li",
    "msd_NBT",
    "msd_NTf2",
    "msd_OBT",
    "msd_OE",
    "msd_layer_ether",
    "msd_layer_Li",
    "msd_layer_NBT",
    "msd_layer_NTf2",
    "msd_layer_OBT",
    "msd_layer_OE",
    "msd_at_coord_change_Li-ether",
    "msd_at_coord_change_Li-NTf2",
    "renewal_events_Li-ether",
    "renewal_events_Li-NTf2",
    "subvolume_charge",
    "topo_map_Li-OBT",
    "topo_map_Li-OE",
)
REQUIRE_EDR = (
    # `${settings}_out_${system}.edr`
    "energy_dist",
)
REQUIRE_TRR = (
    # `${settings}_out_${system}.trr`
    "attribute_hist_ether.py",
    "attribute_hist_Li.py",
    "attribute_hist_NBT.py",
    "attribute_hist_NTf2.py",
    "attribute_hist_OBT.py",
    "attribute_hist_OE.py",
)
REQUIRE_XTC_WRAPPED = (
    # `${settings}_out_${system}_pbc_whole_mol.xtc`
    "axial_hex_dist_1nn_Li",
    "axial_hex_dist_1nn_NBT",
    "axial_hex_dist_1nn_OBT",
    "axial_hex_dist_1nn_OE",
    "axial_hex_dist_2nn_Li",
    "axial_hex_dist_2nn_NBT",
    "axial_hex_dist_2nn_OBT",
    "axial_hex_dist_2nn_OE",
    "contact_hist_Li-O",
    "contact_hist_Li-OBT",
    "contact_hist_Li-OE",
    "contact_hist_O-Li",
    "contact_hist_OBT-Li",
    "contact_hist_OE-Li",
    "contact_hist_at_pos_change_Li-OBT",
    "contact_hist_at_pos_change_Li-OE",
    "contact_hist_slab-z_Li-OBT",
    "contact_hist_slab-z_Li-OE",
    "create_mda_universe",
    "discrete-hex_Li",
    "discrete-hex_NBT",
    "discrete-hex_OBT",
    "discrete-hex_OE",
    "discrete-z_Li",
    "lifetime_autocorr_Li-ether",
    "lifetime_autocorr_Li-NTf2",
    "lifetime_autocorr_Li-OBT",
    "lifetime_autocorr_Li-OE",
    "lig_change_at_pos_change_Li-OBT",
    "lig_change_at_pos_change_Li-OE",
    "lig_change_at_pos_change_blocks_Li-OBT",
    "lig_change_at_pos_change_blocks_Li-OE",
    "lig_change_at_pos_change_blocks_hist_Li-OBT",
    "lig_change_at_pos_change_blocks_hist_Li-OE",
    "subvolume_charge",
    "topo_map_Li-OBT",
    "topo_map_Li-OE",
)
REQUIRE_XTC_UNWRAPPED = (
    # `${settings}_out_${system}_pbc_whole_mol_nojump.xtc`
    "create_mda_universe",
    "msd_ether",
    "msd_Li",
    "msd_NBT",
    "msd_NTf2",
    "msd_OBT",
    "msd_OE",
    "msd_layer_ether",
    "msd_layer_Li",
    "msd_layer_NBT",
    "msd_layer_NTf2",
    "msd_layer_OBT",
    "msd_layer_OE",
    "msd_at_coord_change_Li-ether",
    "msd_at_coord_change_Li-NTf2",
    "renewal_events_Li-ether",
    "renewal_events_Li-NTf2",
)
REQUIRE_DTRJ_DISCRETE_Z = (
    # `${settings}_${system}_discrete-z_Li_dtrj.npy` or `.npz`
    "discrete-z_Li_back_jump_prob_discrete",
    "discrete-z_Li_kaplan_meier_discrete",
    "discrete-z_Li_state_lifetime_discrete",
    "renewal_events_Li-ether_back_jump_prob_discrete",
    "renewal_events_Li-ether_kaplan_meier_discrete",
    "renewal_events_Li-ether_state_lifetime_discrete",
    "renewal_events_Li-NTf2_back_jump_prob_discrete",
    "renewal_events_Li-NTf2_kaplan_meier_discrete",
    "renewal_events_Li-NTf2_state_lifetime_discrete",
)
REQUIRE_DTRJ_RENEWAL_ETHER = (
    # `${settings}_${system}_renewal_events_Li-ether_dtrj.npy` or `.npz`
    "renewal_events_Li-ether_back_jump_prob",
    "renewal_events_Li-ether_back_jump_prob_discrete",
    "renewal_events_Li-ether_kaplan_meier",
    "renewal_events_Li-ether_kaplan_meier_discrete",
    "renewal_events_Li-ether_state_lifetime",
    "renewal_events_Li-ether_state_lifetime_discrete",
)
REQUIRE_DTRJ_RENEWAL_TFSI = (
    # `${settings}_${system}_renewal_events_Li-NTf2_dtrj.npy` or `.npz`
    "renewal_events_Li-NTf2_back_jump_prob",
    "renewal_events_Li-NTf2_back_jump_prob_discrete",
    "renewal_events_Li-NTf2_kaplan_meier",
    "renewal_events_Li-NTf2_kaplan_meier_discrete",
    "renewal_events_Li-NTf2_state_lifetime",
    "renewal_events_Li-NTf2_state_lifetime_discrete",
)
REQUIRE_BIN_FILE = (
    # `${settings}_${system}_density-z_number_Li_binsA.txt.gz`
    "contact_hist_at_pos_change_Li-OBT",
    "contact_hist_at_pos_change_Li-OE",
    "discrete-z_Li",
    "lig_change_at_pos_change_Li-OBT",
    "lig_change_at_pos_change_Li-OE",
    "lig_change_at_pos_change_blocks_Li-OBT",
    "lig_change_at_pos_change_blocks_Li-OE",
    "lig_change_at_pos_change_blocks_hist_Li-OBT",
    "lig_change_at_pos_change_blocks_hist_Li-OE",
    "msd_layer_ether",
    "msd_layer_Li",
    "msd_layer_NBT",
    "msd_layer_NTf2",
    "msd_layer_OBT",
    "msd_layer_OE",
)


def _assemble_submit_cmd(sbatch_opts, job_script):
    """
    Assemble a |Slurm| submit command.

    Parameters
    ----------
    sbatch_opts : dict
        Dictionary containing options to parse to |sbatch|.
    job_script : str
        The job script to submit.

    Returns
    -------
    submit_cmd : str
        The submit command as one string.

    Notes
    -----
    This function relies on global variables!
    """
    sbatch = "sbatch "
    sbatch += opthandler.optdict2str(
        sbatch_opts, skiped_opts=("None", "False"), dumped_vals=("True",)
    )
    submit = sbatch
    if "job-name" not in sbatch_opts and "J" not in sbatch_opts:
        sbatch_jobname = " --job-name " + gmx_infile_pattern + "_"
        submit += sbatch_jobname + job_script
    if "output" not in sbatch_opts and "o" not in sbatch_opts:
        sbatch_output = " --output " + gmx_infile_pattern + "_"
        submit += sbatch_output + job_script + "_slurm-%j.out"
    submit += " " + job_script + ".sh " + posargs[job_script]
    return submit


def _submit_discretized(sbatch_opts, job_script, bins):
    r"""
    Submit a |Slurm| job script for each bin in `bins`.

    This function implements the \--discretize option of this submit
    script.

    Parameters
    ----------
    sbatch_opts : dict
        Dictionary containing options to parse to |sbatch|.
    job_script : str
        The job script which should be submitted for each bin in `bins`.
        The job script must analyze a slab in xy plane.
    bins : list or tuple
        List containing the bin edges.

    Returns
    -------
    n_jobs_submitted : int
        The number of submitted jobs.

    Notes
    -----
    This function relies on global variables!
    """
    posargs = {
        "axial_hex_dist_1nn_Li": posargs_general + posargs_trj[:3],
        "axial_hex_dist_1nn_NBT": posargs_general + posargs_trj[:3],
        "axial_hex_dist_1nn_OBT": posargs_general + posargs_trj[:3],
        "axial_hex_dist_1nn_OE": posargs_general + posargs_trj[:3],
        "axial_hex_dist_2nn_Li": posargs_general + posargs_trj[:3],
        "axial_hex_dist_2nn_NBT": posargs_general + posargs_trj[:3],
        "axial_hex_dist_2nn_OBT": posargs_general + posargs_trj[:3],
        "axial_hex_dist_2nn_OE": posargs_general + posargs_trj[:3],
        "contact_hist_slab-z_Li-OBT": (
            posargs_general + posargs_trj[:3] + posargs_contact
        ),
        "contact_hist_slab-z_Li-OE": (
            posargs_general + posargs_trj[:3] + posargs_contact
        ),
        "discrete-hex_Li": posargs_general + posargs_trj,
        "discrete-hex_NBT": posargs_general + posargs_trj,
        "discrete-hex_OBT": posargs_general + posargs_trj,
        "discrete-hex_OE": posargs_general + posargs_trj,
    }
    if job_script not in posargs.keys():
        raise ValueError(
            "Invalid job script: '{}'.  The script does not analyze a slab in"
            " xy plane".format(job_script)
        )

    sbatch = "sbatch "
    sbatch += opthandler.optdict2str(
        sbatch_opts, skiped_opts=("None", "False"), dumped_vals=("True",)
    )
    submit = sbatch

    n_jobs_submitted = 0
    for i, zmax in enumerate(bins[1:], 1):
        slab = [bins[i - 1], zmax]
        slab_str = "_{:.{prec}f}-{:.{prec}f}A".format(
            slab[0], slab[1], prec=ARG_PREC
        )
        if "job-name" not in sbatch_opts and "J" not in sbatch_opts:
            sbatch_jobname = " --job-name " + gmx_infile_pattern + "_"
            submit += sbatch_jobname + job_script + slab_str
        if "output" not in sbatch_opts and "o" not in sbatch_opts:
            sbatch_output = " --output " + gmx_infile_pattern + "_"
            submit += sbatch_output + job_script + slab_str + "_slurm-%j.out"
        posargs_tmp = opthandler.posargs2str(
            posargs[job_script] + slab, prec=ARG_PREC
        )
        submit += " " + job_script + ".sh " + posargs_tmp
        subproc.check_output(shlex.split(submit))
        n_jobs_submitted += 1
    return n_jobs_submitted


def _submit(sbatch_opts, job_script):
    """
    Submit job scripts to the |Slurm| Workload Manager.

    Parameters
    ----------
    sbatch_opts : dict
        Dictionary containing options to parse to |sbatch|.
    job_script : str
        The job script to submit.

    Returns
    -------
    n_jobs_submitted : int
        The number of submitted jobs.

    Notes
    -----
    This function relies on global variables!
    """
    n_jobs_submitted = 0
    if "gra" not in args["system"] and (
        "axial_hex_dist" in job_script or "discrete-hex" in job_script
    ):
        print(
            "NOTE: '{}' will not be submitted because the system contains no"
            " electrodes".format(job_script)
        )
    elif args["discretize"] and (
        "axial_hex_dist" in job_script
        or "contact_hist_slab-z" in job_script
        or "discrete-hex" in job_script
    ):
        n_jobs_submitted += _submit_discretized(
            sbatch_opts, job_script, bin_edges
        )
    else:
        submit = _assemble_submit_cmd(sbatch_opts, job_script)
        subproc.check_output(shlex.split(submit))
        n_jobs_submitted += 1
    return n_jobs_submitted


if __name__ == "__main__":  # noqa: C901
    parser = argparse.ArgumentParser(
        description=(
            "Submit MDTools analysis scripts for systems containing LiTFSI and"
            " linear poly(ethylene oxides) of arbitrary length (including"
            " dimethyl ether) to the |Slurm| Workload Manager of an HPC"
            " cluster.  For more information, refer to the documentation of"
            " this script."
        )
    )
    parser_required = parser.add_argument_group(title="Required Arguments")
    parser_required.add_argument(
        "--system",
        type=str,
        required=True,
        help="The name of the system to analyze.",
    )
    parser_required.add_argument(
        "--settings",
        type=str,
        required=True,
        help="The used simulation settings.",
    )
    parser_required.add_argument(
        "--scripts",
        type=str,
        required=True,
        help=(
            "The analysis script(s) to submit."
            ""
            "  0 = All scripts.  Note that all lig_change_at_pos_change*"
            " scripts are excluded."
            "  1 = All scripts analyzing the bulk system (i.e. exclude scripts"
            " that analyze only a part, e.g. a slab, of the system, but still"
            " include anisotropic analyses, e.g. spatially discretized"
            " analyses).  Note that all lig_change_at_pos_change* scripts are"
            " excluded."
            "  2 = All scripts analyzing a slab in xy plane."
            ""
            "  3 = All discrete-z_Li* scripts."
            "  4 = All hexagonal discretizations."
            "  5 = All density distributions along hexagonal axes."
            ""
            "  6 = All contact histograms."
            "  6.1 = All 'normal' bulk contact histograms."
            "  6.2 = All slab-z contact histograms."
            "  6.3 = All contact histograms at position change."
            "  7 = All scripts analyzing coordination changes at position"
            " changes."
            "  8 = All topological maps."
            ""
            "  9 = All MSDs."
            "  9.1 = All 'normal' bulk MSDs."
            "  9.2 = All spatially discretized MSDs."
            "  9.3 = All MSDs at coordination change."
            "  10 = All lifetime autocorrelations."
            "  11 = All renewal event analyses."
            "  11.1 = All scripts extracting renewal events."
            "  11.2 = All scripts working on renewal event trajectories."
            "  11.3 = All bulk scripts working on renewal event trajectories."
            "  11.4 = All spatially discretized scripts working on renewal"
            " event trajectories."
            ""
            "  12 =   All scripts that take an |edr_file| or an |trr_file| as"
            " input."
            "  13 =   All attribute histograms (attribute_hist*)."
        ),
    )
    parser_trj_reading = parser.add_argument_group(
        title="Options for Trajectory Reading"
    )
    parser_trj_reading.add_argument(
        "--begin",
        type=int,
        required=False,
        default=0,
        help=(
            "First frame to read from the trajectory.  Frame numbering starts"
            " at zero.  Default: %(default)s."
        ),
    )
    parser_trj_reading.add_argument(
        "--end",
        type=int,
        required=False,
        default=-1,
        help=(
            "Last frame to read from the trajectory (exclusive).  Default:"
            " %(default)s."
        ),
    )
    parser_trj_reading.add_argument(
        "--every",
        type=int,
        required=False,
        default=1,
        help=(
            "Read every n-th frame from the trajectory.  Default: %(default)s."
        ),
    )
    parser_trj_reading.add_argument(
        "--nblocks",
        type=int,
        required=False,
        default=1,
        help=(
            "Number of blocks for scripts that support block averaging."
            "  Default: %(default)s."
        ),
    )
    parser_trj_reading.add_argument(
        "--restart",
        type=int,
        required=False,
        default=500,
        help=(
            "Number of frames between restarting points for analyses using the"
            " sliding widow method.  Default: %(default)s."
        ),
    )
    parser_dist = parser.add_argument_group(
        title="Options for Distance Resolved Quantities (like RDFs)"
    )
    parser_dist.add_argument(
        "--binwidth",
        type=float,
        required=False,
        default=0.05,
        help=(
            "Bin width (in Angstrom) for distance resolved quantities."
            "  Default: %(default)s."
        ),
    )
    parser_contact = parser.add_argument_group(
        title="Options for Contact Analyses"
    )
    parser_contact.add_argument(
        "--cutoff",
        type=float,
        required=False,
        default=3.0,
        help=(
            "Cutoff (in Angstrom) up to which two atoms are regarded as being"
            " in contact.  Default: %(default)s."
        ),
    )
    parser_atom = parser.add_argument_group(
        title="Options for Single Atom Analyses"
    )
    parser_atom.add_argument(
        "--atom-index",
        type=int,
        required=False,
        default=0,
        help="Index of the atom to analyze.  Default: %(default)s.",
    )
    parser_discrete = parser.add_argument_group(
        title="Options for Analyses of Sequences of Discrete States"
    )
    parser_discrete.add_argument(
        "--intermittency",
        type=int,
        required=False,
        default=0,
        help=(
            "Maximum number of frames a selection compound is allowed to leave"
            " a certain state whilst still being considered to be inside that"
            " state, provided that it is indeed again inside this state after"
            " the intermittent period.  Default: %(default)s."
        ),
    )
    parser_discrete.add_argument(
        "--lag-compare",
        type=int,
        required=False,
        default=250,
        help=(
            "Lag time (in trajectory frames) after which to compare the states"
            " of a selection compound.  Default: %(default)s."
        ),
    )
    parser_discrete.add_argument(
        "--min-block-size",
        type=int,
        required=False,
        default=500,
        help=(
            "Minimum block size (in trajectory frames).  Blocks of consecutive"
            " frames in which a given selection compound stays in the same"
            " state must comprise at least this many frames in order to be"
            " counted as valid block.  Default: %(default)s."
        ),
    )
    parser_discrete.add_argument(
        "--max-gap-size",
        type=int,
        required=False,
        default=50,
        help=(
            "Maximum gap size (in trajectory frames).  The gap between two"
            " following valid blocks must not be greater than this many frames"
            " in order to count a transition between the two valid blocks as"
            " valid transition.  Default: %(default)s."
        ),
    )
    parser_slab = parser.add_argument_group(
        title="Options for Tools That Analyze Slabs in xy Plane"
    )
    parser_slab.add_argument(
        "--zmin",
        type=float,
        required=False,
        default=0,
        help=(
            "Lower boundary (in Angstrom) of the slab in xy plane.  Default:"
            " %(default)s."
        ),
    )
    parser_slab.add_argument(
        "--zmax",
        type=float,
        required=False,
        default=None,
        help=(
            "Upper boundary (in Angstrom) of the slab in xy plane.  Default:"
            " Maximum length of the simulation box in z direction (inferred"
            " from SETTINGS_out_SYSTEM.gro`)."
        ),
    )
    parser_slab.add_argument(
        "--slabwidth",
        type=float,
        required=False,
        default=1.0,
        help=(
            "Slab width (in Angstrom) to use when --discretize or"
            " --center-slab is given.  Default: %(default)s."
        ),
    )
    parser_slab_exclusive = parser_slab.add_mutually_exclusive_group()
    parser_slab_exclusive.add_argument(
        "--discretize",
        required=False,
        default=False,
        action="store_true",
        help=(
            "Divide the simulation box from --zmin to --zmax in slabs of width"
            " --slabwidth and submit all scripts analyzing slabs in xy plane"
            " that were selected with --scripts for each created slab."
        ),
    )
    parser_slab_exclusive.add_argument(
        "--center-slab",
        required=False,
        default=False,
        action="store_true",
        help=(
            "Create a slab in xy plane of width --slabwidth exactly in the"
            " center of the simulation box and submit all scripts analyzing"
            " slabs in xy plane that were selected with --scripts for that"
            " slab.  If given, --zmin and --zmax are ignored."
        ),
    )
    parser_py = parser.add_argument_group(title="Python-Specific Options")
    parser_py.add_argument(
        "--py-lmod",
        type=str,
        required=False,
        default="palma/2019a/python3-7-2.sh",
        help=(
            "If running on a cluster which uses the Lmod module system,"
            " specify here which file to source (relative to the lmod"
            " subdirectory of this project) to load Python.  Default:"
            " %(default)s."
        ),
    )
    parser_py.add_argument(
        "--py-exe",
        type=str,
        required=False,
        default="gmx",
        help="Name of the Python executable.  Default: %(default)s.",
    )
    parser_py.add_argument(
        "--mdt-path",
        type=str,
        required=False,
        default="${HOME}/git/github/mdtools",
        help="Path to the cloned MDTools repository.  Default: %(default)s.",
    )
    opts = opthandler.get_opts(
        argparser=parser,
        secs_known=(
            "submit",
            "submit.analysis",
            "submit.analysis.lintf2_ether",
            "submit.analysis.lintf2_ether.mdt",
        ),
        secs_unknown=(
            "sbatch",
            "sbatch.analysis",
            "sbatch.analysis.lintf2_ether",
            "sbatch.analysis.lintf2_ether.mdt",
        ),
    )
    args = opts["submit"]
    args_sbatch = opts["sbatch"]
    args_sbatch_no_dep = copy.deepcopy(args_sbatch)
    args_sbatch_no_dep.pop("dependency", None)
    args_sbatch_no_dep.pop("d", None)

    gmx_infile_pattern = args["settings"] + "_" + args["system"]
    gmx_outfile_pattern = args["settings"] + "_out_" + args["system"]
    TPR_FILE = gmx_infile_pattern + ".tpr"
    EDR_FILE = gmx_outfile_pattern + ".edr"
    GRO_FILE = gmx_outfile_pattern + ".gro"
    TRR_FILE = gmx_outfile_pattern + ".trr"
    XTC_FILE_WRAPPED = gmx_outfile_pattern + "_pbc_whole_mol.xtc"
    XTC_FILE_UNWRAPPED = gmx_outfile_pattern + "_pbc_whole_mol_nojump.xtc"
    DTRJ_DISCRETE_Z_FILE = gmx_infile_pattern + "_discrete-z_Li_dtrj.npy"
    DTRJ_RENEWAL_ETHER_FILE = (
        gmx_infile_pattern + "_renewal_events_Li-ether_dtrj.npy"
    )
    DTRJ_RENEWAL_TFSI_FILE = (
        gmx_infile_pattern + "_renewal_events_Li-NTf2_dtrj.npy"
    )
    BIN_FILE = gmx_infile_pattern + "_density-z_number_Li_binsA.txt.gz"

    print("Processing parsed arguments...")
    if args["binwidth"] <= 0:
        raise ValueError(
            "--binwidth ({}) must be greater than"
            " zero".format(args["binwidth"])
        )
    if args["slabwidth"] <= 0:
        raise ValueError(
            "--slabwidth ({}) must be greater than"
            " zero".format(args["slabwidth"])
        )
    if args["center_slab"]:
        if not os.path.isfile(GRO_FILE):
            raise FileNotFoundError(
                "Could not get the box dimensions from the .gro file.  No such"
                " file: '{}'.".format(GRO_FILE)
            )
        box_z = gmx.get_box_from_gro(GRO_FILE)[2]
        args["zmin"] = 0.5 * (box_z - args["slabwidth"])
        args["zmax"] = 0.5 * (box_z + args["slabwidth"])
    elif args["zmax"] is None:
        if not os.path.isfile(GRO_FILE):
            raise FileNotFoundError(
                "Could not get the box dimensions from the .gro file.  No such"
                " file: '{}'.  Either provide the .gro file or set --zmax"
                " manually".format(GRO_FILE)
            )
        args["zmax"] = gmx.get_box_from_gro(GRO_FILE)[2]
    if args["zmax"] <= args["zmin"]:
        raise ValueError(
            "zmax ({}) must be greater than zmin"
            " ({})".format(args["zmax"], args["zmin"])
        )
    if args["discretize"]:
        if args["zmax"] - args["zmin"] < args["slabwidth"]:
            raise ValueError(
                "If --discretize is given, zmax-zmin ({}-{}) must be less than"
                " --slabwidth ({})".format(
                    args["zmax"], args["zmin"], args["slabwidth"]
                )
            )
        if (
            "slab-z" not in args["scripts"]
            and "axial_hex_dist" not in args["scripts"]
            and "discrete-hex" not in args["scripts"]
            and "0" not in args["scripts"].split()  # All scripts.
            and "2" not in args["scripts"].split()  # All slab scripts.
            and "4" not in args["scripts"].split()  # All discrete-hex.
            and "5" not in args["scripts"].split()  # All axial_hex_dist.
            and "6" not in args["scripts"].split()  # All contact_hist.
            and "6.2" not in args["scripts"].split()  # All contact_hist_slab-z
        ):
            raise ValueError(
                "--discretize can only be used in conjunction with scripts"
                " that analyze a slab in xy plane."
            )
        edge = args["zmin"]
        bin_edges = [edge]
        while edge < args["zmax"]:
            edge += args["slabwidth"]
            bin_edges.append(edge)

    print("Checking if input files exist...")
    files = {}
    for script in args["scripts"].split():
        if script in REQUIRE_TPR:
            files.setdefault("run input", TPR_FILE)
        if script in REQUIRE_EDR:
            files.setdefault("energy", gmx.get_compressed_file(EDR_FILE))
        if script in REQUIRE_TRR:
            files.setdefault("full-precision trajectory", TRR_FILE)
        if script in REQUIRE_XTC_WRAPPED:
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        if script in REQUIRE_XTC_UNWRAPPED:
            files.setdefault(
                "unwrapped compressed trajectory", XTC_FILE_UNWRAPPED
            )
        if script in REQUIRE_DTRJ_DISCRETE_Z:
            files.setdefault(
                "discretized trajectory (spatial z)", DTRJ_DISCRETE_Z_FILE
            )
        if script in REQUIRE_DTRJ_RENEWAL_ETHER:
            files.setdefault(
                "discretized trajectory (renewal Li-ether)",
                DTRJ_RENEWAL_ETHER_FILE,
            )
        if script in REQUIRE_DTRJ_RENEWAL_TFSI:
            files.setdefault(
                "discretized trajectory (renewal Li-TFSI)",
                DTRJ_RENEWAL_TFSI_FILE,
            )
        if script in REQUIRE_BIN_FILE:
            files.setdefault("bin", BIN_FILE)
        if script == "0" or script == "1":  # All (bulk) scripts.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
            files.setdefault(
                "unwrapped compressed trajectory", XTC_FILE_UNWRAPPED
            )
            files.setdefault("bin", BIN_FILE)
        elif script == "2":  # All slab scripts.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "3":  # All discrete-z_Li* scripts.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
            files.setdefault("bin", BIN_FILE)
        elif script == "4":  # All hexagonal discretizations.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "5":  # All axial_hex_dist*.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "6":  # All contact histograms.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
            files.setdefault("bin", BIN_FILE)
        elif script == "6.1":  # All "normal" bulk contact histograms.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "6.2":  # All slab-z contact histograms.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "6.3":  # All contact_hist_at_pos_change*.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
            files.setdefault("bin", BIN_FILE)
        elif script == "7":  # All lig_change_at_pos_change*.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
            files.setdefault("bin", BIN_FILE)
        elif script == "8":  # All topological maps.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "9":  # All MSDs.
            files.setdefault("run input", TPR_FILE)
            files.setdefault(
                "unwrapped compressed trajectory", XTC_FILE_UNWRAPPED
            )
            files.setdefault("bin", BIN_FILE)
        elif script == "9.1":  # All "normal" bulk MSDs.
            files.setdefault("run input", TPR_FILE)
            files.setdefault(
                "unwrapped compressed trajectory", XTC_FILE_UNWRAPPED
            )
        elif script == "9.2":  # All spatially discretized MSDs.
            files.setdefault("run input", TPR_FILE)
            files.setdefault(
                "unwrapped compressed trajectory", XTC_FILE_UNWRAPPED
            )
            files.setdefault("bin", BIN_FILE)
        elif script == "9.3":  # All MSDs at coordination change.
            files.setdefault("run input", TPR_FILE)
            files.setdefault(
                "unwrapped compressed trajectory", XTC_FILE_UNWRAPPED
            )
        elif script == "10":  # All lifetime autocorrelations.
            files.setdefault("run input", TPR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "11":  # All renewal event analyses.
            files.setdefault("run input", TPR_FILE)
            files.setdefault(
                "unwrapped compressed trajectory", XTC_FILE_UNWRAPPED
            )
            files.setdefault(
                "discretized trajectory (spatial z)", DTRJ_DISCRETE_Z_FILE
            )
        elif script == "11.1":  # All scripts extracting renewal events.
            files.setdefault("run input", TPR_FILE)
            files.setdefault(
                "unwrapped compressed trajectory", XTC_FILE_UNWRAPPED
            )
        elif script == "11.2":  # All scripts working on renewal trj.
            files.setdefault(
                "discretized trajectory (spatial z)", DTRJ_DISCRETE_Z_FILE
            )
            files.setdefault(
                "discretized trajectory (renewal Li-ether)",
                DTRJ_RENEWAL_ETHER_FILE,
            )
            files.setdefault(
                "discretized trajectory (renewal Li-TFSI)",
                DTRJ_RENEWAL_TFSI_FILE,
            )
        elif script == "11.3":  # All bulk scripts working on renew trj.
            files.setdefault(
                "discretized trajectory (renewal Li-ether)",
                DTRJ_RENEWAL_ETHER_FILE,
            )
            files.setdefault(
                "discretized trajectory (renewal Li-TFSI)",
                DTRJ_RENEWAL_TFSI_FILE,
            )
        elif script == "11.4":  # All spatial scripts working on ren trj
            files.setdefault(
                "discretized trajectory (spatial z)", DTRJ_DISCRETE_Z_FILE
            )
            files.setdefault(
                "discretized trajectory (renewal Li-ether)",
                DTRJ_RENEWAL_ETHER_FILE,
            )
            files.setdefault(
                "discretized trajectory (renewal Li-TFSI)",
                DTRJ_RENEWAL_TFSI_FILE,
            )
    for filetype, filename in files.items():
        if not os.path.isfile(filename):
            fname, extension = os.path.splitext(filename)
            if extension == ".npy" and os.path.isfile(fname + ".npz"):
                # A compressed version of the file exists.
                continue
            else:
                # Neither the file itself nor a compressed version
                # exists.
                raise FileNotFoundError(
                    "No such file: '{}' ({} file)".format(filename, filetype)
                )

    print("Preparing positional arguments for the slurm job scripts...")
    py_lmod = os.path.abspath(
        os.path.join(FILE_ROOT, "../../../lmod/" + args["py_lmod"])
    )
    if not os.path.isfile(py_lmod):
        raise FileNotFoundError(
            "No such file: '{}'.  This might happen if you change the"
            " directory structure of this project or if you have not given a"
            " source file relative to the lmod directory of this project with"
            " --py-lmod".format(py_lmod)
        )
    mdt_path = os.path.abspath(os.path.expandvars(args["mdt_path"]))
    if not os.path.isdir(mdt_path):
        raise FileNotFoundError("No such directory: '{}'.".format(mdt_path))
    if args["py_exe"] is not None:
        args["py_exe"] = os.path.expandvars(args["py_exe"])
    posargs_general = [
        BASH_DIR,
        py_lmod,
        args["py_exe"],
        mdt_path,
        args["system"],
        args["settings"],
    ]
    posargs_trj = [
        args["begin"],
        args["end"],
        args["every"],
        args["nblocks"],
        args["restart"],
    ]
    posargs_dist = [args["binwidth"]]
    posargs_contact = [args["cutoff"]]
    posargs_discrete = [
        args["intermittency"],
        args["lag_compare"],
        args["min_block_size"],
        args["max_gap_size"],
    ]
    posargs_atom = [args["atom_index"]]
    posargs_slab = [args["zmin"], args["zmax"]]
    # Position arguments must be in the right order for each job script.
    posargs = {
        "attribute_hist_ether": posargs_general + posargs_trj[:3],
        "attribute_hist_Li": posargs_general + posargs_trj[:3],
        "attribute_hist_NBT": posargs_general + posargs_trj[:3],
        "attribute_hist_NTf2": posargs_general + posargs_trj[:3],
        "attribute_hist_OBT": posargs_general + posargs_trj[:3],
        "attribute_hist_OE": posargs_general + posargs_trj[:3],
        "axial_hex_dist_1nn_Li": (
            posargs_general + posargs_trj[:3] + posargs_slab
        ),
        "axial_hex_dist_1nn_NBT": (
            posargs_general + posargs_trj[:3] + posargs_slab
        ),
        "axial_hex_dist_1nn_OBT": (
            posargs_general + posargs_trj[:3] + posargs_slab
        ),
        "axial_hex_dist_1nn_OE": (
            posargs_general + posargs_trj[:3] + posargs_slab
        ),
        "axial_hex_dist_2nn_Li": (
            posargs_general + posargs_trj[:3] + posargs_slab
        ),
        "axial_hex_dist_2nn_NBT": (
            posargs_general + posargs_trj[:3] + posargs_slab
        ),
        "axial_hex_dist_2nn_OBT": (
            posargs_general + posargs_trj[:3] + posargs_slab
        ),
        "axial_hex_dist_2nn_OE": (
            posargs_general + posargs_trj[:3] + posargs_slab
        ),
        "contact_hist_Li-O": (
            posargs_general + posargs_trj[:3] + posargs_contact
        ),
        "contact_hist_Li-OBT": (
            posargs_general + posargs_trj[:3] + posargs_contact
        ),
        "contact_hist_Li-OE": (
            posargs_general + posargs_trj[:3] + posargs_contact
        ),
        "contact_hist_O-Li": (
            posargs_general + posargs_trj[:3] + posargs_contact
        ),
        "contact_hist_OBT-Li": (
            posargs_general + posargs_trj[:3] + posargs_contact
        ),
        "contact_hist_OE-Li": (
            posargs_general + posargs_trj[:3] + posargs_contact
        ),
        "contact_hist_at_pos_change_Li-OBT": (
            posargs_general + posargs_trj[:3] + posargs_contact
        ),
        "contact_hist_at_pos_change_Li-OE": (
            posargs_general + posargs_trj[:3] + posargs_contact
        ),
        "contact_hist_slab-z_Li-OBT": (
            posargs_general + posargs_trj[:3] + posargs_contact + posargs_slab
        ),
        "contact_hist_slab-z_Li-OE": (
            posargs_general + posargs_trj[:3] + posargs_contact + posargs_slab
        ),
        "create_mda_universe": posargs_general[:3] + posargs_general[4:],
        "discrete-hex_Li": posargs_general + posargs_trj + posargs_slab,
        "discrete-hex_NBT": posargs_general + posargs_trj + posargs_slab,
        "discrete-hex_OBT": posargs_general + posargs_trj + posargs_slab,
        "discrete-hex_OE": posargs_general + posargs_trj + posargs_slab,
        "discrete-z_Li": posargs_general + posargs_trj[:3],
        "discrete-z_Li_back_jump_prob_discrete": posargs_general,
        "discrete-z_Li_kaplan_meier_discrete": posargs_general,
        "discrete-z_Li_state_lifetime_discrete": (
            posargs_general + [posargs_trj[4]]
        ),
        "energy_dist": posargs_general + posargs_trj[:3],
        "lifetime_autocorr_Li-ether": (
            posargs_general
            + posargs_trj
            + posargs_contact
            + [posargs_discrete[0]]
        ),
        "lifetime_autocorr_Li-NTf2": (
            posargs_general
            + posargs_trj
            + posargs_contact
            + [posargs_discrete[0]]
        ),
        "lifetime_autocorr_Li-OBT": (
            posargs_general
            + posargs_trj
            + posargs_contact
            + [posargs_discrete[0]]
        ),
        "lifetime_autocorr_Li-OE": (
            posargs_general
            + posargs_trj
            + posargs_contact
            + [posargs_discrete[0]]
        ),
        "lig_change_at_pos_change_Li-OBT": (
            posargs_general
            + posargs_trj[:3]
            + posargs_contact
            + [posargs_discrete[1]]
        ),
        "lig_change_at_pos_change_Li-OE": (
            posargs_general
            + posargs_trj[:3]
            + posargs_contact
            + [posargs_discrete[1]]
        ),
        "lig_change_at_pos_change_blocks_Li-OBT": (
            posargs_general
            + posargs_trj[:3]
            + posargs_contact
            + posargs_discrete[1:]
        ),
        "lig_change_at_pos_change_blocks_Li-OE": (
            posargs_general
            + posargs_trj[:3]
            + posargs_contact
            + posargs_discrete[1:]
        ),
        "lig_change_at_pos_change_blocks_hist_Li-OBT": (
            posargs_general
            + posargs_trj[:3]
            + posargs_contact
            + posargs_discrete[1:]
        ),
        "lig_change_at_pos_change_blocks_hist_Li-OE": (
            posargs_general
            + posargs_trj[:3]
            + posargs_contact
            + posargs_discrete[1:]
        ),
        "msd_ether": posargs_general + posargs_trj,
        "msd_Li": posargs_general + posargs_trj,
        "msd_NBT": posargs_general + posargs_trj,
        "msd_NTf2": posargs_general + posargs_trj,
        "msd_OBT": posargs_general + posargs_trj,
        "msd_OE": posargs_general + posargs_trj,
        "msd_layer_ether": posargs_general + posargs_trj,
        "msd_layer_Li": posargs_general + posargs_trj,
        "msd_layer_NBT": posargs_general + posargs_trj,
        "msd_layer_NTf2": posargs_general + posargs_trj,
        "msd_layer_OBT": posargs_general + posargs_trj,
        "msd_layer_OE": posargs_general + posargs_trj,
        "msd_at_coord_change_Li-ether": (
            posargs_general
            + posargs_trj[:3]
            + posargs_contact
            + [posargs_discrete[0]]
        ),
        "msd_at_coord_change_Li-NTf2": (
            posargs_general
            + posargs_trj[:3]
            + posargs_contact
            + [posargs_discrete[0]]
        ),
        "renewal_events_Li-ether": (
            posargs_general
            + posargs_trj[:3]
            + posargs_contact
            + [posargs_discrete[0]]
        ),
        "renewal_events_Li-ether_back_jump_prob": (posargs_general),
        "renewal_events_Li-ether_back_jump_prob_discrete": (posargs_general),
        "renewal_events_Li-ether_kaplan_meier": (posargs_general),
        "renewal_events_Li-ether_kaplan_meier_discrete": (posargs_general),
        "renewal_events_Li-ether_state_lifetime": (
            posargs_general + posargs_trj[3:]
        ),
        "renewal_events_Li-ether_state_lifetime_discrete": (
            posargs_general + [posargs_trj[4]]
        ),
        "renewal_events_Li-NTf2": (
            posargs_general
            + posargs_trj[:3]
            + posargs_contact
            + [posargs_discrete[0]]
        ),
        "renewal_events_Li-NTf2_back_jump_prob": (posargs_general),
        "renewal_events_Li-NTf2_back_jump_prob_discrete": (posargs_general),
        "renewal_events_Li-NTf2_kaplan_meier": (posargs_general),
        "renewal_events_Li-NTf2_kaplan_meier_discrete": (posargs_general),
        "renewal_events_Li-NTf2_state_lifetime": (
            posargs_general + posargs_trj[3:]
        ),
        "renewal_events_Li-NTf2_state_lifetime_discrete": (
            posargs_general + [posargs_trj[4]]
        ),
        "subvolume_charge": (posargs_general + posargs_trj[:3] + posargs_dist),
        "topo_map_Li-OBT": (
            posargs_general + posargs_trj[:3] + posargs_contact + posargs_atom
        ),
        "topo_map_Li-OE": (
            posargs_general + posargs_trj[:3] + posargs_contact + posargs_atom
        ),
    }
    posargs = {
        k: opthandler.posargs2str(v, prec=ARG_PREC) for k, v in posargs.items()
    }

    print("Submitting job(s) to Slurm...")
    n_scripts_submitted = 0
    # Submit single scripts by name.
    for batch_script in posargs.keys():
        if batch_script in args["scripts"].split():
            n_scripts_submitted += _submit(args_sbatch, batch_script)
    # Submit multiple scripts by number.
    if "0" in args["scripts"].split() or "1" in args["scripts"].split():
        # All scripts (0) or All bulk scripts (1).
        # create_mda_universe
        submit = _assemble_submit_cmd(args_sbatch, "create_mda_universe")
        job_id_mda_universe = subproc.check_output(shlex.split(submit))
        job_id_mda_universe = strng.extract_ints_from_str(job_id_mda_universe)
        job_id_mda_universe = job_id_mda_universe[0]
        args_sbatch_dep_mda_universe = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep_mda_universe["dependency"] = "afterok:{}".format(
            job_id_mda_universe
        )
        n_scripts_submitted += 1
        # discrete-z_Li
        submit = _assemble_submit_cmd(
            args_sbatch_dep_mda_universe, "discrete-z_Li"
        )
        job_id_discrete_z_li = subproc.check_output(shlex.split(submit))
        job_id_discrete_z_li = strng.extract_ints_from_str(
            job_id_discrete_z_li
        )
        job_id_discrete_z_li = job_id_discrete_z_li[0]
        args_sbatch_dep_discrete_z_li = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep_discrete_z_li["dependency"] = "afterok:{}".format(
            job_id_discrete_z_li
        )
        n_scripts_submitted += 1
        # renewal_events_Li-ether
        submit = _assemble_submit_cmd(
            args_sbatch_dep_discrete_z_li, "renewal_events_Li-ether"
        )
        job_id_renewal_ether = subproc.check_output(shlex.split(submit))
        job_id_renewal_ether = strng.extract_ints_from_str(
            job_id_renewal_ether
        )
        job_id_renewal_ether = job_id_renewal_ether[0]
        args_sbatch_dep_renewal_ether = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep_renewal_ether["dependency"] = "afterok:{}".format(
            job_id_renewal_ether
        )
        n_scripts_submitted += 1
        # renewal_events_Li-NTf2
        submit = _assemble_submit_cmd(
            args_sbatch_dep_discrete_z_li, "renewal_events_Li-NTf2"
        )
        job_id_renewal_tfsi = subproc.check_output(shlex.split(submit))
        job_id_renewal_tfsi = strng.extract_ints_from_str(job_id_renewal_tfsi)
        job_id_renewal_tfsi = job_id_renewal_tfsi[0]
        args_sbatch_dep_renewal_tfsi = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep_renewal_tfsi["dependency"] = "afterok:{}".format(
            job_id_renewal_tfsi
        )
        n_scripts_submitted += 1
        for batch_script in posargs.keys():
            if "0" not in args["scripts"].split() and (
                "axial_hex_dist" in batch_script
                or "contact_hist_slab-z" in batch_script
                or "discrete-hex" in batch_script
            ):
                # Submit only bulk scripts.
                continue
            if batch_script in (
                "create_mda_universe",
                "discrete-z_Li",
                "renewal_events_Li-ether",
                "renewal_events_Li-NTf2",
            ):
                # Scripts have already been submitted above.
                continue
            if batch_script == "energy_dist":
                # Exclude all scripts that take an .edr file as input.
                continue
            if "attribute_hist" in batch_script:
                # Exclude all scripts that take an .trr file as input.
                continue
            if "lig_change_at_pos_change" in batch_script:
                # Exclude all lig_change_at_pos_change* scripts.
                continue
            elif batch_script in REQUIRE_DTRJ_RENEWAL_ETHER:
                sbatch_opts = args_sbatch_dep_renewal_ether
            elif batch_script in REQUIRE_DTRJ_RENEWAL_TFSI:
                sbatch_opts = args_sbatch_dep_renewal_tfsi
            elif batch_script in REQUIRE_DTRJ_DISCRETE_Z:
                sbatch_opts = args_sbatch_dep_discrete_z_li
            else:
                sbatch_opts = args_sbatch_dep_mda_universe
            n_scripts_submitted += _submit(sbatch_opts, batch_script)
    if "2" in args["scripts"].split():
        # All slab scripts.
        for batch_script in posargs.keys():
            if (
                "axial_hex_dist" in batch_script
                or "contact_hist_slab-z" in batch_script
                or "discrete-hex" in batch_script
            ):
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "3" in args["scripts"].split():
        # All discrete-z_Li* scripts.
        # discrete-z_Li
        submit = _assemble_submit_cmd(args_sbatch, "discrete-z_Li")
        job_id = subproc.check_output(shlex.split(submit))
        job_id = strng.extract_ints_from_str(job_id)[0]
        args_sbatch_dep = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep["dependency"] = "afterok:{}".format(job_id)
        n_scripts_submitted += 1
        for batch_script in posargs.keys():
            if "discrete-z_Li_" in batch_script:
                submit = _assemble_submit_cmd(args_sbatch_dep, batch_script)
                subproc.check_output(shlex.split(submit))
                n_scripts_submitted += 1
    if "4" in args["scripts"].split():
        # All hexagonal discretizations.
        for batch_script in posargs.keys():
            if "discrete-hex" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "5" in args["scripts"].split():
        # All axial_hex_dist*.
        for batch_script in posargs.keys():
            if "axial_hex_dist" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "6" in args["scripts"].split():
        # All contact histograms.
        for batch_script in posargs.keys():
            if "contact_hist" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "6.1" in args["scripts"].split():
        # All "normal" bulk contact histograms.
        for batch_script in posargs.keys():
            if (
                "contact_hist" in batch_script
                and "contact_hist_at_pos_change" not in batch_script
                and "contact_hist_slab-z" not in batch_script
            ):
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "6.2" in args["scripts"].split():
        # All slab-z contact histograms.
        for batch_script in posargs.keys():
            if "contact_hist_slab-z" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "6.3" in args["scripts"].split():
        # All contact_hist_at_pos_change*.
        for batch_script in posargs.keys():
            if "contact_hist_at_pos_change" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "7" in args["scripts"].split():
        # All lig_change_at_pos_change*.
        for batch_script in posargs.keys():
            if "lig_change_at_pos_change" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "8" in args["scripts"].split():
        # All topological maps.
        for batch_script in posargs.keys():
            if "topo_map" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "9" in args["scripts"].split():
        # All MSDs.
        for batch_script in posargs.keys():
            if "msd" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "9.1" in args["scripts"].split():
        # All "normal" bulk MSDs.
        for batch_script in posargs.keys():
            if (
                "msd" in batch_script
                and "msd_at_coord_change" not in batch_script
                and "msd_layer" not in batch_script
            ):
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "9.2" in args["scripts"].split():
        # All spatially discretized MSDs.
        for batch_script in posargs.keys():
            if "msd_layer" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "9.3" in args["scripts"].split():
        # All MSDs at coordination change.
        for batch_script in posargs.keys():
            if "msd_at_coord_change" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "10" in args["scripts"].split():
        # All lifetime autocorrelations.
        for batch_script in posargs.keys():
            if "lifetime_autocorr" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "11" in args["scripts"].split():
        # All renewal event analyses.
        # renewal_events_Li-ether
        submit = _assemble_submit_cmd(args_sbatch, "renewal_events_Li-ether")
        job_id_renewal_ether = subproc.check_output(shlex.split(submit))
        job_id_renewal_ether = strng.extract_ints_from_str(
            job_id_renewal_ether
        )
        job_id_renewal_ether = job_id_renewal_ether[0]
        args_sbatch_dep_renewal_ether = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep_renewal_ether["dependency"] = "afterok:{}".format(
            job_id_renewal_ether
        )
        n_scripts_submitted += 1
        # renewal_events_Li-NTf2
        submit = _assemble_submit_cmd(args_sbatch, "renewal_events_Li-NTf2")
        job_id_renewal_tfsi = subproc.check_output(shlex.split(submit))
        job_id_renewal_tfsi = strng.extract_ints_from_str(job_id_renewal_tfsi)
        job_id_renewal_tfsi = job_id_renewal_tfsi[0]
        args_sbatch_dep_renewal_tfsi = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep_renewal_tfsi["dependency"] = "afterok:{}".format(
            job_id_renewal_tfsi
        )
        n_scripts_submitted += 1
        for batch_script in posargs.keys():
            if batch_script in (
                "renewal_events_Li-ether",
                "renewal_events_Li-NTf2",
            ):
                # Scripts have already been submitted above.
                continue
            if "renewal_events" in batch_script:
                if batch_script in REQUIRE_DTRJ_RENEWAL_ETHER:
                    sbatch_opts = args_sbatch_dep_renewal_ether
                elif batch_script in REQUIRE_DTRJ_RENEWAL_TFSI:
                    sbatch_opts = args_sbatch_dep_renewal_tfsi
                else:
                    raise LookupError(
                        "'{}' is neither in REQUIRE_DTRJ_RENEWAL_ETHER nor in"
                        " REQUIRE_DTRJ_RENEWAL_TFSI.  This should not have"
                        " happened".format(batch_script)
                    )
                n_scripts_submitted += _submit(sbatch_opts, batch_script)
    if "11.1" in args["scripts"].split():
        # All scripts extracting renewal events.
        for batch_script in posargs.keys():
            if batch_script in (
                "renewal_events_Li-ether",
                "renewal_events_Li-NTf2",
            ):
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "11.2" in args["scripts"].split():
        # All scripts working on renewal event trajectories.
        for batch_script in posargs.keys():
            if batch_script in (
                "renewal_events_Li-ether",
                "renewal_events_Li-NTf2",
            ):
                continue
            if "renewal_events" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "11.3" in args["scripts"].split():
        # All bulk scripts working on renewal event trajectories.
        for batch_script in posargs.keys():
            if batch_script in (
                "renewal_events_Li-ether",
                "renewal_events_Li-NTf2",
            ):
                continue
            if (
                "renewal_events" in batch_script
                and "discrete" not in batch_script
            ):
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "11.4" in args["scripts"].split():
        # All spatially discretized scripts working on renew ev trj.
        for batch_script in posargs.keys():
            if batch_script in (
                "renewal_events_Li-ether",
                "renewal_events_Li-NTf2",
            ):
                continue
            if "renewal_events" in batch_script and "discrete" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "12" in args["scripts"].split():
        # All scripts that take an .edr file or an .trr file as input.
        for batch_script in posargs.keys():
            if (
                batch_script == "energy_dist"
                or "attribute_hist" in batch_script
            ):
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "13" in args["scripts"].split():
        # All attribute histograms (attribute_hist*).
        for batch_script in posargs.keys():
            if "attribute_hist" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    print("Submitted {} jobs".format(n_scripts_submitted))
    if n_scripts_submitted == 0:
        warnings.warn("No script submitted", UserWarning, stacklevel=2)

    print("{} done".format(os.path.basename(sys.argv[0])))
