#!/usr/bin/env python3

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst


r"""
Submit |Gromacs| analysis tools for systems containing LiTFSI and linear
poly(ethylene oxides) of arbitrary length (including dimethyl ether) to
the |Slurm| Workload Manager of an HPC cluster.

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
    :bash:`ls path/to/hpc_submit_scripts/analysis/lintf2_ether/gmx/`.

        :0:     All scripts.
        :1:     All scripts analyzing the bulk system (i.e. exclude
                scripts that analyze only a part, e.g. a slab, of the
                system, but still include anisotropic analyses, e.g.
                z-profiles).
        :2:     All scripts analyzing a slab in xy plane.
        :3:     All trjconv scripts.
        :4:     All RDFs (bulk and slab-z).
        :4.1:   All bulk RDFs.
        :4.2:   All slab-z RDFs.
        :5:     All MSDs.
        :6:     All z-profiles (density-z* and potential-z*).
        :7:     All z-densmaps.

Options for Trajectory Reading
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--begin
    First frame (in ps) to read from trajectory.  Default: ``0``.
--end
    Last frame (in ps) to read from trajectory.  Default: Last frame in
    :file:`${settings}_out_${system}.log`.  Reading from |log_file|\s
    compressed with gzip, bzip2, XZ or LZMA is supported.
--every
    Only use frame if t MOD dt == first time (in ps).  Default: ``1``.

Options for MSD Calculation
^^^^^^^^^^^^^^^^^^^^^^^^^^^
--beginfit
    Start lag time for fitting the MSD (in ps), -1 is 10%.  Default:
    ``-1``.
--endfit
    End lag time for fitting the MSD (in ps), -1 is 90%.  Default:
    ``-1``.
--restart
    Time (in ps) between restarting points in trajectory for MSD
    calculation.  Default: ``1000``.

Options for Distance Resolved Quantities (like RDFs)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--binwidth
    Bin width (in nm) for distance resolved quantities.
    Default:  ``0.005``.

Options for Tools That Analyze Slabs in xy Plane
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--zmin
    Lower boundary (in nm) of the slab in xy plane.  Default: ``0``.
--zmax
    Upper boundary (in nm) of the slab in xy plane.  Default: Maximum
    length of the simulation box in z direction (inferred from
    :file:`${settings}_out_${system}.gro`).
--slabwidth
    Slab width (in nm) to use when \--discretize or \--center-slab is
    given.  Default: ``0.1``.
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

Gromacs-Specifig Options
^^^^^^^^^^^^^^^^^^^^^^^^
--gmx-lmod
    If running on a cluster which uses the |Lmod| module system,
    specifiy here which file to source (relative to the :file:`lmod`
    subdirectory of this project) to load Gromacs.  Default:
    ``'palma/2019a/gmx2018-8_foss.sh'``.
--gmx-exe
    Name of the Gromacs executable.  Default: ``'gmx'``.

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
    * [submit.analysis.lintf2_ether.gmx]
    * [sbatch]
    * [sbatch.analysis]
    * [sbatch.analysis.lintf2_ether]
    * [sbatch.analysis.lintf2_ether.gmx]

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
# Third-party libraries
import gmx  # noqa: E402
import opthandler  # noqa: E402
import strng  # noqa: E402


ARG_PREC = 3  # Precision of floats parsed to batch scripts.
BASH_DIR = os.path.abspath(os.path.join(FILE_ROOT, "../../../bash"))
if not os.path.isdir(BASH_DIR):
    raise FileNotFoundError(
        "No such directory: '{}'.  This might happen if you change the"
        " directory structure of this project".format(BASH_DIR)
    )
REQUIRE_EDR = (
    # `${settings}_out_${system}.edr`
    "energy",
)
REQUIRE_NDX = (
    # `${system}.ndx`
    "density-z_charge",
    "density-z_mass",
    "density-z_number",
    "densmap-z_gra",
    "densmap-z_NBT",
    "densmap-z_OBT",
    "densmap-z_OE",
    "msd",
    "msd_electrodes",
    "msd_lateral-z",
    "msd_parallel-z",
    "msd_tensor",
    "polystat",
    "potential-z",
)
REQUIRE_TRR = (
    # `${settings}_out_${system}.trr`
    "densmap-z_gra",
    "densmap-z_Li",
    "densmap-z_NBT",
    "densmap-z_OBT",
    "densmap-z_OE",
    "trjconv_whole",
)
REQUIRE_XTC_WRAPPED = (
    # `${settings}_out_${system}_pbc_whole_mol.xtc`
    "density-z_charge",
    "density-z_mass",
    "density-z_number",
    "polystat",
    "potential-z",
    "rdf_ether-com",
    "rdf_Li",
    "rdf_Li-com",
    "rdf_NBT",
    "rdf_NTf2-com",
    "rdf_OE",
    "rdf_slab-z_Li",
    "rdf_slab-z_NBT",
    "rdf_slab-z_OE",
    "trjconv_nojump",
)
REQUIRE_XTC_UNWRAPPED = (
    # `${settings}_out_${system}_pbc_whole_mol_nojump.xtc`
    "msd",
    "msd_electrodes",
    "msd_lateral-z",
    "msd_parallel-z",
    "msd_tensor",
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
        "densmap-z_gra": posargs_general + posargs_trj + posargs_dist,
        "densmap-z_Li": posargs_general + posargs_trj + posargs_dist,
        "densmap-z_NBT": posargs_general + posargs_trj + posargs_dist,
        "densmap-z_OBT": posargs_general + posargs_trj + posargs_dist,
        "densmap-z_OE": posargs_general + posargs_trj + posargs_dist,
        "rdf_slab-z_Li": posargs_general + posargs_trj + posargs_dist,
        "rdf_slab-z_NBT": posargs_general + posargs_trj + posargs_dist,
        "rdf_slab-z_OE": posargs_general + posargs_trj + posargs_dist,
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
        slab_str = "_{:.{prec}f}-{:.{prec}f}nm".format(
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
        job_script == "msd_electrodes" or job_script == "densmap-z_gra"
    ):
        print(
            "NOTE: '{}' will not be submitted because the system contains no"
            " electrodes".format(job_script)
        )
    elif args["discretize"] and (
        "densmap-z" in job_script or "rdf_slab-z" in job_script
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
            "Submit Gromacs analysis tools for systems containing LiTFSI and"
            " linear poly(ethylene oxides) of arbitrary length (including"
            " dimethyl ether) to the Slurm Workload Manager of an HPC cluster."
            "  For more information, refer to the documetation of this script."
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
            "  0 = All scripts."
            "  1 = All scripts analyzing the bulk system (i.e. exclude scripts"
            " that analyze only a part, e.g. a slab, of the system, but still"
            " include anisotropic analyses, e.g. z-profiles)."
            "  2 = All scripts analyzing a slab in xy plane."
            "  3 = All trjconv scripts."
            "  4 = All RDFs (bulk and slab-z)."
            "  4.1 = All bulk RDFs."
            "  4.2 = All slab-z RDFs."
            "  5 = All MSDs."
            "  6 = All z-profiles (density-z* and potential-z*)."
            "  7 = All z-densmaps."
        ),
    )
    parser_trj_reading = parser.add_argument_group(
        title="Options for Trajectory Reading"
    )
    parser_trj_reading.add_argument(
        "--begin",
        type=float,
        required=False,
        default=0,
        help=(
            "First frame (in ps) to read from trajectory.  Default:"
            " %(default)s."
        ),
    )
    parser_trj_reading.add_argument(
        "--end",
        type=float,
        required=False,
        default=None,
        help=(
            "Last frame (in ps) to read from trajectory.  Default: Last frame"
            " in SETTINGS_out_SYSTEM.log."
        ),
    )
    parser_trj_reading.add_argument(
        "--every",
        type=float,
        required=False,
        default=1,
        help=(
            "Only use frame if t MOD dt == first time (in ps).  Default:"
            " %(default)s."
        ),
    )
    parser_msd = parser.add_argument_group(title="Options for MSD Calculation")
    parser_msd.add_argument(
        "--beginfit",
        type=float,
        required=False,
        default=-1,
        help=(
            "Start lag time for fitting the MSD (in ps), -1 is 10%%.  Default:"
            " %(default)s."
        ),
    )
    parser_msd.add_argument(
        "--endfit",
        type=float,
        required=False,
        default=-1,
        help=(
            "End lag time for fitting the MSD (in ps), -1 is 90%%.  Default:"
            " %(default)s."
        ),
    )
    parser_msd.add_argument(
        "--restart",
        type=float,
        required=False,
        default=1000,
        help=(
            "Time (in ps) between restarting points in trajectory for MSD"
            " calculation.  Default: %(default)s."
        ),
    )
    parser_dist = parser.add_argument_group(
        title="Options for Distance Resolved Quantities (like RDFs)"
    )
    parser_dist.add_argument(
        "--binwidth",
        type=float,
        required=False,
        default=0.005,
        help=(
            "Bin width (in nm) for distance resolved quantities.  Default:"
            " %(default)s."
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
            "Lower boundary (in nm) of the slab in xy plane.  Default:"
            " %(default)s."
        ),
    )
    parser_slab.add_argument(
        "--zmax",
        type=float,
        required=False,
        default=None,
        help=(
            "Upper boundary (in nm) of the slab in xy plane.  Default: Maximum"
            " length of the simulation box in z direction (inferred from"
            " SETTINGS_out_SYSTEM.gro`)."
        ),
    )
    parser_slab.add_argument(
        "--slabwidth",
        type=float,
        required=False,
        default=0.1,
        help=(
            "Slab width (in nm) to use when --discretize or --center-slab is"
            " given.  Default: %(default)s."
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
    parser_gmx = parser.add_argument_group(title="Gromacs-Specifig Options")
    parser_gmx.add_argument(
        "--gmx-lmod",
        type=str,
        required=False,
        default="palma/2019a/gmx2018-8_foss.sh",
        help=(
            "If running on a cluster which uses the Lmod module system,"
            " specifiy here which file to source (relative to the lmod"
            " subdirectory of this project) to load Gromacs.  Default:"
            " %(default)s."
        ),
    )
    parser_gmx.add_argument(
        "--gmx-exe",
        type=str,
        required=False,
        default="gmx",
        help="Name of the Gromacs executable.  Default: %(default)s.",
    )
    opts = opthandler.get_opts(
        argparser=parser,
        secs_known=(
            "submit",
            "submit.analysis",
            "submit.analysis.lintf2_ether",
            "submit.analysis.lintf2_ether.gmx",
        ),
        secs_unknown=(
            "sbatch",
            "sbatch.analysis",
            "sbatch.analysis.lintf2_ether",
            "sbatch.analysis.lintf2_ether.gmx",
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
    LOG_FILE = gmx_outfile_pattern + ".log"
    TRR_FILE = gmx_outfile_pattern + ".trr"
    XTC_FILE_WRAPPED = gmx_outfile_pattern + "_pbc_whole_mol.xtc"
    XTC_FILE_UNWRAPPED = gmx_outfile_pattern + "_pbc_whole_mol_nojump.xtc"
    NDX_FILE = args["system"] + ".ndx"

    print("Processing parsed arguments...")
    if args["end"] is None:
        try:
            log_file = gmx.get_compressed_file(LOG_FILE)
        except FileNotFoundError as err:
            raise FileNotFoundError(
                "Could not get the time of the last frame from the .log file:"
                " {}.  Either make sure that the .log file exists or set --end"
                " manually".format(err)
            )
        args["end"] = gmx.get_last_time_from_log(log_file)
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
            and "densmap-z" not in args["scripts"]
            and "0" not in args["scripts"].split()  # All scripts.
            and "2" not in args["scripts"].split()  # All slab scripts.
            and "4.2" not in args["scripts"].split()  # All slab-z RDFs.
            and "7" not in args["scripts"].split()  # All z-densmaps.
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
    if (
        "density-z" in args["scripts"]
        or "potential-z" in args["scripts"]
        or "0" in args["scripts"].split()  # All scripts.
        or "1" in args["scripts"].split()  # All bulk scripts.
        or "6" in args["scripts"].split()  # All z-profiles.
    ):
        if not os.path.isfile(GRO_FILE):
            raise FileNotFoundError(
                "Could not get the box dimensions from the .gro file.  No such"
                " file: '{}'.".format(GRO_FILE)
            )
        nbins = gmx.get_nbins(GRO_FILE, args["binwidth"])
    else:
        nbins = None

    print("Checking if input files exist...")
    files = {"run input": TPR_FILE}
    for script in args["scripts"].split():
        if script in REQUIRE_EDR:
            files.setdefault("energy", gmx.get_compressed_file(EDR_FILE))
        if script in REQUIRE_NDX:
            files.setdefault("index", NDX_FILE)
        if script in REQUIRE_TRR:
            files.setdefault("full-precision trajectory", TRR_FILE)
        if script in REQUIRE_XTC_WRAPPED:
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        if script in REQUIRE_XTC_UNWRAPPED:
            files.setdefault(
                "unwrapped compressed trajectory", XTC_FILE_UNWRAPPED
            )
        if script == "0" or script == "1":  # All (bulk) scripts.
            files.setdefault("energy", gmx.get_compressed_file(EDR_FILE))
            files.setdefault("full-precision trajectory", TRR_FILE)
        elif script == "2":  # All slab scripts.
            files.setdefault("index", NDX_FILE)
            files.setdefault("full-precision trajectory", TRR_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "3":  # All trjconv scripts.
            files.setdefault("full-precision trajectory", TRR_FILE)
        elif script == "4":  # All RDFs
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "4.1":  # All bulk RDFs.
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "4.2":  # All slab-z RDFs.
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "5":  # All MSDs.
            files["index"] = NDX_FILE
            files.setdefault(
                "unwrapped compressed trajectory", XTC_FILE_UNWRAPPED
            )
        elif script == "6":  # All z-profiles.
            files.setdefault("index", NDX_FILE)
            files.setdefault("wrapped compressed trajectory", XTC_FILE_WRAPPED)
        elif script == "7":  # All z-densmaps.
            files.setdefault("index", NDX_FILE)
            files.setdefault("full-precision trajectory", TRR_FILE)
    for filetype, filename in files.items():
        if not os.path.isfile(filename):
            raise FileNotFoundError(
                "No such file: '{}' ({} file)".format(filename, filetype)
            )

    print("Preparing positional arguments for the slurm job scripts...")
    gmx_lmod = os.path.abspath(
        os.path.join(FILE_ROOT, "../../../lmod/" + args["gmx_lmod"])
    )
    if not os.path.isfile(gmx_lmod):
        raise FileNotFoundError(
            "No such file: '{}'.  This might happen if you change the"
            " directory structure of this project or if you have not given a"
            " source file relative to the lmod directory of this project with"
            " --gmx-lmod".format(gmx_lmod)
        )
    if args["gmx_exe"] is not None:
        args["gmx_exe"] = os.path.expandvars(args["gmx_exe"])
    posargs_general = [
        BASH_DIR,
        gmx_lmod,
        args["gmx_exe"],
        args["system"],
        args["settings"],
    ]
    posargs_trj = [args["begin"], args["end"], args["every"]]
    posargs_msd = [args["beginfit"], args["endfit"], args["restart"]]
    posargs_dist = [args["binwidth"]]
    posargs_slab = [args["zmin"], args["zmax"]]
    # Position arguments must be in the right order for each job script.
    posargs = {
        "density-z_charge": posargs_general + posargs_trj + [nbins],
        "density-z_mass": posargs_general + posargs_trj + [nbins],
        "density-z_number": posargs_general + posargs_trj + [nbins],
        "densmap-z_gra": (
            posargs_general + posargs_trj + posargs_dist + posargs_slab
        ),
        "densmap-z_Li": (
            posargs_general + posargs_trj + posargs_dist + posargs_slab
        ),
        "densmap-z_NBT": (
            posargs_general + posargs_trj + posargs_dist + posargs_slab
        ),
        "densmap-z_OBT": (
            posargs_general + posargs_trj + posargs_dist + posargs_slab
        ),
        "densmap-z_OE": (
            posargs_general + posargs_trj + posargs_dist + posargs_slab
        ),
        "energy": posargs_general + posargs_trj[:2],
        "make_ndx": posargs_general,
        "msd": posargs_general + posargs_trj[:2] + posargs_msd,
        "msd_electrodes": posargs_general + posargs_trj[:2] + posargs_msd,
        "msd_lateral-z": posargs_general + posargs_trj[:2] + posargs_msd,
        "msd_parallel-z": posargs_general + posargs_trj[:2] + posargs_msd,
        "msd_tensor": posargs_general + posargs_trj[:2] + posargs_msd,
        "polystat": posargs_general + posargs_trj,
        "potential-z": posargs_general + posargs_trj + [nbins],
        "rdf_ether-com": posargs_general + posargs_trj + posargs_dist,
        "rdf_Li": posargs_general + posargs_trj + posargs_dist,
        "rdf_Li-com": posargs_general + posargs_trj + posargs_dist,
        "rdf_NBT": posargs_general + posargs_trj + posargs_dist,
        "rdf_NTf2-com": posargs_general + posargs_trj + posargs_dist,
        "rdf_OE": posargs_general + posargs_trj + posargs_dist,
        "rdf_slab-z_Li": (
            posargs_general + posargs_trj + posargs_dist + posargs_slab
        ),
        "rdf_slab-z_NBT": (
            posargs_general + posargs_trj + posargs_dist + posargs_slab
        ),
        "rdf_slab-z_OE": (
            posargs_general + posargs_trj + posargs_dist + posargs_slab
        ),
        "trjconv_nojump": posargs_general + posargs_trj,
        "trjconv_whole": posargs_general + posargs_trj,
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
        # make_ndx
        submit = _assemble_submit_cmd(args_sbatch, "make_ndx")
        job_id_make_ndx = subproc.check_output(shlex.split(submit))
        job_id_make_ndx = strng.extract_ints_from_str(job_id_make_ndx)
        job_id_make_ndx = job_id_make_ndx[0]
        args_sbatch_dep_make_ndx = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep_make_ndx["dependency"] = "afterok:{}".format(
            job_id_make_ndx
        )
        n_scripts_submitted += 1
        # trjconv_whole
        submit = _assemble_submit_cmd(
            args_sbatch_dep_make_ndx, "trjconv_whole"
        )
        job_id_trjconv_whole = subproc.check_output(shlex.split(submit))
        job_id_trjconv_whole = strng.extract_ints_from_str(
            job_id_trjconv_whole
        )
        job_id_trjconv_whole = job_id_trjconv_whole[0]
        args_sbatch_dep_trjconv_whole = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep_trjconv_whole["dependency"] = "afterok:{}".format(
            job_id_trjconv_whole
        )
        n_scripts_submitted += 1
        # trjconv_nojump
        submit = _assemble_submit_cmd(
            args_sbatch_dep_trjconv_whole, "trjconv_nojump"
        )
        job_id_trjconv_nojump = subproc.check_output(shlex.split(submit))
        job_id_trjconv_nojump = strng.extract_ints_from_str(
            job_id_trjconv_nojump
        )
        job_id_trjconv_nojump = job_id_trjconv_nojump[0]
        args_sbatch_dep_trjconv_nojump = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep_trjconv_nojump["dependency"] = "afterok:{}".format(
            job_id_trjconv_nojump
        )
        n_scripts_submitted += 1
        for batch_script in posargs.keys():
            if "0" not in args["scripts"].split() and (
                "densmap-z" in batch_script or "rdf_slab-z" in batch_script
            ):
                # Only bulk scripts.
                continue
            if batch_script in ("make_ndx", "trjconv_whole", "trjconv_nojump"):
                continue
            elif batch_script in REQUIRE_XTC_UNWRAPPED:
                sbatch_opts = args_sbatch_dep_trjconv_nojump
            elif batch_script in REQUIRE_XTC_WRAPPED:
                sbatch_opts = args_sbatch_dep_trjconv_whole
            elif batch_script in REQUIRE_NDX:
                sbatch_opts = args_sbatch_dep_make_ndx
            else:
                sbatch_opts = args_sbatch
            n_scripts_submitted += _submit(sbatch_opts, batch_script)
    if "2" in args["scripts"].split():
        # All slab scripts.
        for batch_script in posargs.keys():
            if "densmap-z" in batch_script or "rdf_slab-z" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "3" in args["scripts"].split():
        # All trjconv scripts.
        # trjconv_whole
        submit = _assemble_submit_cmd(args_sbatch, "trjconv_whole")
        job_id = subproc.check_output(shlex.split(submit))
        job_id = strng.extract_ints_from_str(job_id)[0]
        args_sbatch_dep = copy.deepcopy(args_sbatch_no_dep)
        args_sbatch_dep["dependency"] = "afterok:{}".format(job_id)
        n_scripts_submitted += 1
        # trjconv_nojump
        submit = _assemble_submit_cmd(args_sbatch_dep, "trjconv_nojump")
        subproc.check_output(shlex.split(submit))
        n_scripts_submitted += 1
    if "4" in args["scripts"].split():
        # All RDFs.
        for batch_script in posargs.keys():
            if "rdf" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "4.1" in args["scripts"].split():
        # All bulk RDFs.
        for batch_script in posargs.keys():
            if "rdf" in batch_script and "slab-z" not in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "4.2" in args["scripts"].split():
        # All slab-z RDFs.
        for batch_script in posargs.keys():
            if "rdf_slab-z" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "5" in args["scripts"].split():
        # All MSDs.
        for batch_script in posargs.keys():
            if "msd" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "6" in args["scripts"].split():
        # All z-profiles
        for batch_script in posargs.keys():
            if "density-z" in batch_script or "potential-z" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    if "7" in args["scripts"].split():
        # All z-densmaps.
        for batch_script in posargs.keys():
            if "densmap-z" in batch_script:
                n_scripts_submitted += _submit(args_sbatch, batch_script)
    print("Submitted {} jobs".format(n_scripts_submitted))
    if n_scripts_submitted == 0:
        warnings.warn("No script submitted", UserWarning)

    print("{} done".format(os.path.basename(sys.argv[0])))
