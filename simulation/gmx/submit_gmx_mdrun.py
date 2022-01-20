#!/usr/bin/env python3

# MIT License
# Copyright (c) 2021  All authors listed in the file AUTHORS.rst


r"""
Start or continue a molecular dynamics (MD) simulation with Gromacs_ on
a computing cluster that uses the `Slurm Workload Manager`_.

This script is designed to be used on the Palma2 HPC cluster of the
University of Münster or on the Bagheera HPC cluster of the research
group of Prof. Heuer.

Options
-------
--system
    The name of the system to simulate, e.g. ``'LiTFSI_PEO_20-1'`` for
    an LiTFSI/PEO electrolyte with an ether-oxygen-to-lithium ratio of
    20:1.  You can give any string here.  See notes below.
--settings
    The simulation settings to use, e.g. ``'pr_npt298_pr_nh'`` for a
    production run in an NPT ensemble at 298 K utilizing a
    Parrinello-Rahman barostat and an Nose-Hoover thermostat.  You can
    give any string here.  See notes below.
--structure
    Name of the file that contains the starting structure in a `format
    that is readable by Gromacs`_.  The starting structure is ignored if
    you continue a previous simulation.  Default: ``0``.
--continue
    {0, 1, 2, 3}

    Continue a previous simulation?

        * 0 = No.
        * 1 = Yes.
        * 2 = Start a new simulation and resubmit it to the Slurm
          Workload Manager as many times as specified with \--nresubmits
          or until it has reached the number of simulation steps given
          in the .mdp file (whatever happens earlier).
        * 3 = Continue a previous simulation and resubmit it to the
          Slurm Workload Manager as many times as specified with
          \--nresubmits or until it has reached the number of simulation
          steps given in the .mdp file (whatever happens earlier).

    Default: ``0``.
--nresubmits
    Number of job resubmissions.  The jobs depend on each other and only
    start if the preceding job has finished successfully.  This is
    useful if your simulation takes longer than the maximum allowed
    simulation time on your computing cluster.  This option is ignored
    if \--continue is set to ``0`` or ``1``.  Default: ``10``.
--no-backup
    By default, old simulation files will be backed up into a
    subdirectory before continuing a previous simulation using rsync_.
    This might take up to a few hours.  With \--no-backup you can skip
    this backup, but be aware that your entire trajectory might get
    corrupted if the continuation of the simulation fails badly.
--gmx-lmod
    If running on a cluster which uses the Lmod_ module system, specifiy
    here which file to source (relative to the :file:`lmod` subdirectory
    of this project) to load Gromacs.  Default:
    ``'palma/2019a/gmx2018-8_foss.sh'``.
--gmx-exe
    Name of the Gromacs executable.  Default: ``'gmx'``.
--gmx-mpi-exe
    Name of the MPI version of the Gromacs executable.  If provided, the
    simulation will be run using this executable instead of 'gmx mdrun'.
    Must be provided if the (maximum) number of nodes set with \--nodes
    is greater than one.  Default: ``0``.
--grompp-flags
    Additional options to parse to the Gromacs preprocessor 'gmx
    grompp', provided as one long, enquoted string, e.g. '--maxwarn 1'.
    Is ignored if \--continue is 1 or 3.  Default: ``''``.

Sbatch_ specific options.  The following options are implented directly
in this submit script, to be able to set specific default values.  All
other possible sbatch options can be parsed to \--sbatch (see below).

--kill-on-invalid-dep
    {"yes", "no"}

    Whether to terminate the job when it has an invalid dependency and
    thus can never run (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_kill-on-invalid-dep>`_).
    Default: ``'yes'``.
--mail-type
    {"NONE", "BEGIN", "END", "FAIL", "REQUEUE", "ALL", "INVALID_DEPEND",
    "STAGE_OUT", "TIME_LIMIT", "TIME_LIMIT_90", "TIME_LIMIT_80",
    "TIME_LIMIT_50", "ARRAY_TASKS"}

    Notify user by email when certain event types occur (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_mail-type>`_).  Default:
    ``'FAIL'``.
--mail-user
    User to receive email notification.  Default: ``None``, which means
    the submitting user.
--nodes
    Number of nodes to allocate (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_nodes>`_).  Default:
    ``'1'``.
--non-exclusive
    Do **not** allocate nodes exclusively, i.e. share nodes with other
    running jobs.  This option turns **off** sbatch's \--exclusive
    option (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_exclusive>`_), which is
    otherwise parsed to sbatch on default by this submission script.
--ntasks-per-node
    Number of tasks per node (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_ntasks-per-node>`_).
    Default: ``1``.
--partition
    Request a specific partition for the resource allocation (`more
    details <https://slurm.schedmd.com/sbatch.html#OPT_partition>`_).
    You can use :bash:`sinfo --summarize` to get a list of all
    partitions available on your computing cluster.  Default:``None``,
    which means the default partition as designated by the cluster
    administrator.
--requeue
    Specifies that the batch job should be eligible for requeuing (`more
    details <https://slurm.schedmd.com/sbatch.html#OPT_requeue>`_).  If
    not set, --no-requeue is parsed to sbatch on default by this
    submission script.
--sbatch
    Additional options to parse to sbatch, provided as one long,
    enquoted string.  Make sure that your additional options do not
    collide with options set above.  See below for possibly useful
    options.  Do not use the \--signal option here, because this is used
    internally to allow for cleanup steps.  Default: ``None``.

List of possibly useful options to parse to sbatch via \--sbatch.  Refer
to the `documetation of sbatch <https://slurm.schedmd.com/sbatch.html>`_
for a full list of all options.  Note that the sbatch options
\--job-name and \--output are set to ``'SETTINGS + "_" + SYSTEM'`` and
``'SETTINGS + "_out_" + SYSTEM + "_slurm-%j.out'`` if they are not
explicitly parsed to \--sbatch.

--account
    Charge resources used by this job to the specified account (`more
    details <ttps://slurm.schedmd.com/sbatch.html#OPT_account>`_).
--begin
    Defer the allocation of the job until the specified time (`more
    details <https://slurm.schedmd.com/sbatch.html#OPT_begin>`_).
--chdir
    Set the working directory of the batch script before it is executed
    (`more details <https://slurm.schedmd.com/sbatch.html#OPT_chdir>`_).
--constraint
    Specify which features are required by this job (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_constraint>`_).  You can
    use :bash:`sinfo --format "%12P | %.15f"` to see which features are
    available on which partition.
--cpus-per-task
    Number of CPUs per task (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_cpus-per-task>`_).  This
    option is ignored if \--non-exclusive is **not** set.
--dependency
    Defer the start of this job until the specified dependencies have
    been satisfied (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_dependency>`_).
--exclude
    Explicitly exclude certain nodes from the resources granted to the
    job (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_exclude>`_).
--extra-node-info
    Restrict node selection to nodes with at least the specified number
    of sockets, cores per socket and/or threads per core (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_extra-node-info>`_).
--gres
    Generic consumable resources (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_gres>`_).  This option is
    ignored if \--non-exclusive is **not** set.
--hold
    Submit the job in a held state (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_hold>`).
--mem
    Memory required per node. (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_mem>`_).
--mincpus
    Minimum number of CPUs per node (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_mincpus>`_).
--nodelist
    Request a specific list of nodes (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_nodelist>`_).
--test-only
    Return an estimate of when a job would be scheduled to run.  No job
    is actually submitted (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_test-only>`_).
--time
    Set a total run time limit (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_time>`_).  You can use
    :bash:`sinfo --summarize` to get the maximum allowed run time limits
    for each partition on your computing cluster.
--time-min
    Set a minimum time limit.  If specified, the job may have its
    \--time limit lowered to a value no lower than \--time-min if doing
    so permits the job to begin execution earlier than otherwise
    possible (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_time-min>`_).

Notes
-----
The \--system and \--settings options allow (or enforces) you to choose
systematic names for the input and output files of your simulations.
Besides a better overview, this enables an easy automation of
preparation and analysis tasks.

When starting a new simulation, the following commands will be launched:

.. code-block:: bash

    ${gmx_exe} grompp \
        -f ${settings}_${system}.mdp \
        -c ${structure} \
        -n ${system}.ndx \  # Optional, only used if present.
        -p ${system}.top \
        -o ${settings}_${system}.tpr \  # Output file
        ${grompp_flags}

    ${gmx_exe} mdrun \
        -ntmpi ${SLURM_NTASKS_PER_NODE} \
        -ntomp ${CPUS_PER_TASK} \
        -cpt 60 \
        -s ${settings}_${system}.tpr \
        -deffnm ${settings}_out_${system}

Therefore, the following files must exist in your working directory:

    * :file:`SETTINGS_SYSTEM.mdp`
    * :file:`STRUCTURE`
    * :file:`SYSTEM.top`

When continuing a previous simulation, the following commands will be
launched:

.. code-block:: bash

    ${gmx_exe} mdrun \
        -ntmpi ${SLURM_NTASKS_PER_NODE} \
        -ntomp ${CPUS_PER_TASK} \
        -cpt 60 \
        -s ${settings}_${system}.tpr \
        -deffnm ${settings}_out_${system} \
        -cpi ${settings}_out_${system}.cpt \
        -append

Therefore, the following files must exist in your working directory:

    * :file:`SETTINGS_SYSTEM.mdp`
    * :file:`SETTINGS_SYSTEM.tpr`
    * :file:`SETTINGS_out_SYSTEM.cpt`

:file:`SETTINGS_SYSTEM.mdp` is also required when continuing a previous
simulation, because the maximum number of simulation steps is read from
this file.

If the these files cannot be found, this submission script will
terminate with an error message before submitting the job to the Slurm
Workload Manager.

You can view your Slurm jobs with :bash:`squeue --user <your_username>`.


.. _Gromacs: https://www.gromacs.org/
.. _Slurm Workload Manager: https://slurm.schedmd.com/
.. _format that is readable by Gromacs: https://manual.gromacs.org/documentation/current/reference-manual/file-formats.html#structure-files
.. _rsync: https://rsync.samba.org/
.. _Lmod: https://lmod.readthedocs.io/en/latest/index.html
.. _Sbatch: https://slurm.schedmd.com/sbatch.html
"""  # noqa: W505,E501


# Add your name if you contribute to this script.  Use a comma separated
# list: "Author 1, Author 2, Author 3".  Authors should be ordered
# alphabetically by their full name.
__author__ = "Andreas Thum"


import argparse
import glob
import os
import shlex
import subprocess as subproc
import sys
import warnings


def gmx_get_nsteps_from_mdp(infile):
    """
    Extract the maximum number of simulation steps of an Gromacs MD
    simulation from the `.mpd file`_.

    Parameters
    ----------
    infile : str
        Name of the .mdp file.

    Returns
    -------
    nsteps : int
        Maximum number of simulation steps specified in the .mdp file.

    Raises
    ------
    ValueError
        If the input file does not contain a line that starts with
        'nsteps' or if 'nsteps' is not followed by an equal (=) sign.

    .. _.mdp file: https://manual.gromacs.org/documentation/current/user-guide/mdp-options.html
    """  # noqa: W505,E501
    with open(infile, "r") as file:
        found_nsteps = False
        for i, line in enumerate(file):
            line = line.strip()
            if line.startswith("nsteps"):
                found_nsteps = True
                line_nsteps = line
                line_num = i + 1
                # nsteps can be defined multiple times in an .mdp file.
                # From
                # https://manual.gromacs.org/documentation/current/reference-manual/file-formats.html#mdp  # noqa: W505,E501
                # "The ordering of the items is not important, but if
                # you enter the same thing twice, the last is used."
                # => Do not break the loop after the first occurence of
                #    'nsteps'.
    if not found_nsteps:
        raise ValueError(
            "Could not fine a line in file '{}' that starts with"
            " 'nsteps'".format(infile)
        )
    if "=" not in line_nsteps:
        raise ValueError(
            "Line {} in file '{}' starts with 'nsteps' but does not contain an"
            " equal (=) sign".format(line_num, infile)
        )
    nsteps = line_nsteps.split("=")[1]
    nsteps = nsteps.split(";")[0]  # Remove potential comments
    return int(nsteps)


def extract_ints_from_str(str):
    """
    Extract all integers from a string.

    Parameters
    ----------
    str : str
        The input string.

    Returns
    -------
    ints : list
        List of integers in `str`.

    Examples
    --------
    >>> extract_ints_from_str("I have 2 apples and 4 pears")
    [2, 4]
    >>> extract_ints_from_str("I have 0.5 apples and 4 pears")
    [4]
    >>> extract_ints_from_str("I have no apples and no pears")
    []
    """
    ints = [int(i) for i in str.split() if i.isdigit()]
    return ints


if __name__ == "__main__":  # noqa: C901
    parser = argparse.ArgumentParser(
        description=(
            "Start or continue a molecular dynamics (MD) simulation with"
            " Gromacs on a computing cluster that uses the Slurm Workload"
            " Manager.  For more information, refer to the docstring of this"
            " script."
        )
    )
    parser.add_argument(
        "--system",
        dest="SYSTEM",
        type=str,
        required=True,
        help=("The name of the system to simulate."),
    )
    parser.add_argument(
        "--settings",
        dest="SETTINGS",
        type=str,
        required=True,
        help=("The simulation settings to use."),
    )
    parser.add_argument(
        "--structure",
        dest="STRUCTURE",
        type=str,
        required=False,
        default=0,
        help=(
            "Name of the file that contains the starting structure.  Is"
            " ignored if you continue a previous simulation.  Default:"
            " %(default)s"
        ),
    )
    parser.add_argument(
        "--continue",
        dest="CONTINUE",
        type=int,
        required=False,
        choices=(0, 1, 2, 3),
        default=0,
        help=(
            "Continue a previous simulation?  0 = No.  1 = Yes."
            "  2 = Start a new simulation and resubmit it to the Slurm"
            " Workload Manager as many times as specified with --nresubmits or"
            " until it has reached the number of simulation steps given in the"
            " .mdp file (whatever happens earlier)."
            "  3 = Continue a previous simulation and resubmit it to the Slurm"
            " Workload Manager as many times as specified with --nresubmits or"
            " until it has reached the number of simulation steps given in the"
            " .mdp file (whatever happens earlier).  Default: %(default)s"
        ),
    )
    parser.add_argument(
        "--nresubmits",
        dest="NRESUBMITS",
        type=int,
        required=False,
        default=10,
        help=(
            "Number of job resubmissions.  Ignored if --continue is 0 or 1."
            "  Default: %(default)s"
        ),
    )
    parser.add_argument(
        "--no-backup",
        dest="NO_BACKUP",
        required=False,
        default=False,
        action="store_true",
        help=("Skip backup before continuing a previous simulation."),
    )
    parser.add_argument(
        "--gmx-lmod",
        dest="GMX_LMOD",
        type=str,
        required=False,
        default="palma/2019a/gmx2018-8_foss.sh",
        help=(
            "If running on a cluster which uses the Lmod module system,"
            " specifiy here which file to source (relative to the lmod"
            " subdirectory of this project) to load Gromacs.  Default:"
            " %(default)s"
        ),
    )
    parser.add_argument(
        "--gmx-exe",
        dest="GMX_EXE",
        type=str,
        required=False,
        default="gmx",
        help=("Name of the Gromacs executable.  Default: %(default)s"),
    )
    parser.add_argument(
        "--gmx-mpi-exe",
        dest="GMX_MPI_EXE",
        type=str,
        required=False,
        default=0,
        help=(
            "Name of the MPI version of the Gromacs executable.  If provided,"
            " the simulation will be run using this executable instead of"
            " 'gmx mdrun'.  Must be provided if the (maximum) number of nodes"
            " set with --nodes is greater than one.  Default: %(default)s"
        ),
    )
    parser.add_argument(
        "--grompp-flags",
        dest="GMX_GROMPP_FLAGS",
        type=str,
        required=False,
        default="",
        help=(
            "Additional options to parse to the Gromacs preprocessor 'gmx"
            " grompp', provided as one long, enquoted string, e.g."
            " '--maxwarn 1'.  Is ignored if --continue is 1 or 3.  Default:"
            " '%(default)s'"
        ),
    )
    # Sbatch specific options in alphabetical order.
    # Arguments whose `dest` keyword starts with "SBATCH_" are directly
    # parsed to sbatch after removing the "SBATCH_" prefix.  Therefore,
    # everything after "SBATCH_" must match exactly the corresponding
    # sbatch option.
    sbatch_prefix = "SBATCH_"
    parser.add_argument(
        "--kill-on-invalid-dep",
        dest=sbatch_prefix + "kill-on-invalid-dep",
        type=str,
        required=False,
        choices=("yes", "no"),
        default="yes",
        help=(
            "Whether to terminate the job when it has an invalid dependency"
            " and thus can never run.  Default: %(default)s"
        ),
    )
    parser.add_argument(
        "--mail-type",
        dest=sbatch_prefix + "mail-type",
        type=str,
        required=False,
        choices=(
            "NONE",
            "BEGIN",
            "END",
            "FAIL",
            "REQUEUE",
            "ALL",
            "INVALID_DEPEND",
            "STAGE_OUT",
            "TIME_LIMIT",
            "TIME_LIMIT_90",
            "TIME_LIMIT_80",
            "TIME_LIMIT_50",
            "ARRAY_TASKS",
        ),
        default="FAIL",
        help=(
            "Notify user by email when certain event types occur.  Default:"
            " %(default)s"
        ),
    )
    parser.add_argument(
        "--mail-user",
        dest=sbatch_prefix + "mail-user",
        type=str,  # Might be min-max, which is why it is type str and not int
        required=False,
        default=None,
        help=("User to receive email notification.  Default: %(default)s"),
    )
    parser.add_argument(
        "--nodes",
        dest=sbatch_prefix + "nodes",
        type=str,  # Might be min-max, which is why it is type str and not int
        required=False,
        default="1",
        help=("Number of nodes to allocate.  Default: %(default)s"),
    )
    parser.add_argument(
        "--non-exclusive",
        dest="NON_EXCLUSIVE",
        required=False,
        default=False,
        action="store_true",
        help=(
            "Do not allocate nodes exclusively.  This option turns off"
            " sbatch's --exclusive option."
        ),
    )
    parser.add_argument(
        "--ntasks-per-node",
        dest=sbatch_prefix + "ntasks-per-node",
        type=int,
        required=False,
        default=1,
        help=("Number of tasks per node.  Default: %(default)s"),
    )
    parser.add_argument(
        "--partition",
        dest=sbatch_prefix + "partition",
        type=str,
        required=False,
        default=None,
        help=("Request a specific partition.  Default: %(default)s"),
    )
    parser.add_argument(
        "--requeue",
        dest="REQUEUE",
        required=False,
        default=False,
        action="store_true",
        help=(
            "Specifies that the batch job should be eligible for requeuing."
            "  If not set, --no-requeue is parsed to sbatch."
        ),
    )
    parser.add_argument(
        "--sbatch",
        dest="SB_OPTIONS",
        type=str,
        required=False,
        default=None,
        help=(
            "Additional options to parse to sbatch, provided as one long,"
            " enquoted string.  Make sure that your additional options do not"
            " collide with options set above.  Do not use the --signal option"
            " here.  Default: %(default)s"
        ),
    )
    args = parser.parse_args()
    if args.NRESUBMITS < 0:
        raise ValueError(
            "--nresubmits ({}) must not be negative".format(args.NRESUBMITS)
        )
    NODES = vars(args)[sbatch_prefix + "nodes"]
    MIN_NODES = int(NODES.split("-")[0])
    MAX_NODES = int(NODES.split("-")[-1])
    if MIN_NODES < 0 or MAX_NODES < 0:
        raise ValueError("--nodes ({}) must not be negative".format(NODES))
    if MAX_NODES > 1 and (args.GMX_MPI_EXE is None or args.GMX_MPI_EXE == 0):
        raise ValueError(
            "--gmx-mpi-exe must be provided if the (maximum) number of nodes"
            " ({}) is greater than one".format(NODES)
        )
    NTASKS_PER_NODE = vars(args)[sbatch_prefix + "ntasks-per-node"]
    if NTASKS_PER_NODE < 0:
        raise ValueError(
            "--ntasks-per-node ({}) must not be"
            " negative".format(NTASKS_PER_NODE)
        )
    # The existence of the Gromacs (MPI) executable cannot be checked
    # within this script, because the Gromacs (MPI) executable might
    # only be available after loading the corresponding modules.

    print("Checking if input files exist...")
    if args.CONTINUE in (0, 2):  # Start a new simulation
        if args.STRUCTURE is None or args.STRUCTURE == 0:
            raise ValueError(
                "You must provide a structure file with --structure if you"
                " start a new simulation"
            )
        files = (
            args.SETTINGS + "_" + args.SYSTEM + ".mdp",
            args.STRUCTURE,
            args.SYSTEM + ".top",
        )
    elif args.CONTINUE in (1, 3):  # Continue a previous simulation
        files = (
            args.SETTINGS + "_" + args.SYSTEM + ".mdp",
            args.SETTINGS + "_" + args.SYSTEM + ".tpr",
            args.SETTINGS + "_out_" + args.SYSTEM + ".cpt",
        )
    else:
        raise ValueError(
            "Invalid choice for --continue ({})".format(args.CONTINUE)
        )
    for file in files:
        if not os.path.isfile(file):
            raise FileNotFoundError("No such file: '{}'".format(file))
    ndx_files = glob.glob("*.ndx")
    if len(ndx_files) > 0 and args.SYSTEM + ".ndx" not in ndx_files:
        warnings.warn(
            "Detected .ndx file(s) in the working directory, but no .ndx file"
            " called '{0}.ndx'.  Only an .ndx file called '{0}.ndx' will be"
            " parsed to the Gromacs preprocessor grompp".format(args.SYSTEM)
        )

    print("Constructing the submit command...")
    # Assemble arguments to parse to sbatch
    sbatch = "sbatch"
    for arg, val in vars(args).items():
        if arg.startswith(sbatch_prefix) and val is not None:
            sbatch += " --" + arg[len(sbatch_prefix) :]
            if isinstance(val, (list, tuple)):
                # `val` is a list if the `nargs` option of argparse's
                # `ArgumentParser.add_argument` method was changed.
                for item in val:
                    sbatch += " " + str(val)
            else:
                sbatch += " " + str(val)
    job_name = " --job-name " + args.SETTINGS + "_" + args.SYSTEM
    output = (
        " --output " + args.SETTINGS + "_out_" + args.SYSTEM + "_slurm-%j.out"
    )
    if args.SB_OPTIONS is None or args.SB_OPTIONS == "":
        sbatch += job_name + output
        if not args.NON_EXCLUSIVE:
            sbatch += " --exclusive"
        if args.REQUEUE:
            sbatch += " --requeue"
        else:
            sbatch += " --no-requeue"
    else:
        if "--job-name" not in args.SB_OPTIONS and "-J" not in args.SB_OPTIONS:
            sbatch += job_name
        if "--output" not in args.SB_OPTIONS and "-o" not in args.SB_OPTIONS:
            sbatch += output
        if not args.NON_EXCLUSIVE and "--exclusive" not in args.SB_OPTIONS:
            sbatch += " --exclusive"
        elif args.NON_EXCLUSIVE and "--exclusive" in args.SB_OPTIONS:
            raise ValueError(
                "Conflicting options: You set --non-exclusive but parsed"
                " '--exclusive' to --sbatch"
            )
        if args.REQUEUE and "--requeue" not in args.SB_OPTIONS:
            sbatch += " --requeue"
        elif args.REQUEUE and "--no-requeue" in args.SB_OPTIONS:
            raise ValueError(
                "Conflicting options: You set --requeue but parsed"
                " '--no-requeue' to --sbatch"
            )
        elif not args.REQUEUE and "--no-requeue" not in args.SB_OPTIONS:
            sbatch += " --no-requeue"
        elif not args.REQUEUE and "--requeue" in args.SB_OPTIONS:
            raise ValueError(
                "Conflicting options: You did no set --requeue but parsed"
                " '--requeue' to --sbatch"
            )
        if "--signal" in args.SB_OPTIONS:
            raise ValueError(
                "'--signal' is not allowed to be parsed to --sbatch, because"
                " it is used internally to allow for cleanup steps"
            )
        for option in shlex.split(args.SB_OPTIONS):
            if option.startswith("-"):
                if "=" in option:
                    option = option.split("=")[0]
                if option in sbatch:
                    raise ValueError(
                        "The option '{}' parsed to --sbtach is already set by"
                        " the submission script".format(option)
                    )
        sbatch += " " + args.SB_OPTIONS
    # Assemble position arguments to parse to the batch script itself
    file_root = os.path.abspath(os.path.dirname(__file__))
    batch_script = os.path.join(file_root, "./gmx_mdrun.sh")
    if not os.path.isfile(batch_script):
        raise FileNotFoundError(
            "No such file: '{}'.  This might happen if you change the"
            " directory structure of this project".format(batch_script)
        )
    bash_dir = os.path.join(file_root, "./../../bash")
    if not os.path.isdir(bash_dir):
        raise FileNotFoundError(
            "No such directory: '{}'.  This might happen if you change the"
            " directory structure of this project".format(bash_dir)
        )
    gmx_lmod = os.path.join(file_root, "./../../lmod/" + args.GMX_LMOD)
    if not os.path.isfile(gmx_lmod):
        raise FileNotFoundError(
            "No such file: '{}'.  This might happen if you change the"
            " directory structure of this project or if you have not given a"
            " source file relative to the lmod directory of this project with"
            " --gmx-lmod".format(gmx_lmod)
        )
    nsteps = gmx_get_nsteps_from_mdp(
        args.SETTINGS + "_" + args.SYSTEM + ".mdp"
    )
    if args.NO_BACKUP:
        backup = "0"
    else:
        backup = "1"
    pos_args_list = [
        bash_dir,
        args.SYSTEM,
        args.SETTINGS,
        str(args.STRUCTURE),
        str(args.CONTINUE),
        str(nsteps),
        backup,
        gmx_lmod,
        args.GMX_EXE,
        str(args.GMX_MPI_EXE),
        "'{}'".format(args.GMX_GROMPP_FLAGS),
    ]
    pos_args = " ".join(pos_args_list)

    print("Submitting job(s) to Slurm...")
    submit = sbatch + " " + batch_script + " " + pos_args
    job_id = subproc.check_output(shlex.split(submit))
    job_id = extract_ints_from_str(job_id)[0]
    if args.CONTINUE in (2, 3):  # Resubmit
        # After the first job submission the following jobs always
        # continue a previous simulation. => The `continue` option of
        # all following jobs must be set to '3'.
        pos_args_list[4] = "3"  # Set `continue` to '3'
        pos_args = " ".join(pos_args_list)
        for i in range(args.NRESUBMITS):
            sbatch_dep = sbatch + " --dependency=afterok:{}".format(job_id)
            submit = sbatch_dep + " " + batch_script + " " + pos_args
            job_id = subproc.check_output(shlex.split(submit))
            job_id = extract_ints_from_str(job_id)[0]

    print("{} done".format(os.path.basename(sys.argv[0])))
