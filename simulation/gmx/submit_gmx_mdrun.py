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
    is greater than one.  If given, \--ntasks-per-node must be provided
    via \--sbatch.  Default: ``0``.
--no-guess-threads
    Do not let Gromacs guess the number of thread-MPI ranks and OpenMP
    threads, but set the number of thread-MPI ranks to
    ${SLURM_NTASKS_PER_NODE} and the number of OpenMP threads to
    ${CPUS_PER_TASK}, which is equivalent to ${SLURM_CPUS_PER_TASK} (see
    Notes below).  Note, if \--gmx-mpi-exe is provided, the number of
    MPI ranks is always set to ${SLURM_NTASKS_PER_NODE} and guessing
    only affects the number of OpenMP threads.  If \--no-guess-threads
    is given, \--ntasks-per-node must be provided via \--sbatch.
--mdrun-flags
    Additional options to parse to the Gromacs 'mdrun' engine, provided
    as one long, enquoted string, e.g. '-npme 12'.  Default:
    ``'-cpt 60'``.
--grompp-flags
    Additional options to parse to the Gromacs preprocessor 'grompp',
    provided as one long, enquoted string, e.g. '-maxwarn 1'.  Is
    ignored if \--continue is 1 or 3.  Default: ``''``.

Sbatch_ specific options.  The following options are implented directly
in this submit script, to be able to set specific default values.  All
other possible sbatch options can be parsed to \--sbatch (see below).

--kill-on-invalid-dep
    {"yes", "no"}

    Whether to terminate the job when it has an invalid dependency and
    thus can never run (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_kill-on-invalid-dep>`__).
    Default: ``'yes'``.
--mail-type
    {"NONE", "BEGIN", "END", "FAIL", "REQUEUE", "ALL", "INVALID_DEPEND",
    "STAGE_OUT", "TIME_LIMIT", "TIME_LIMIT_90", "TIME_LIMIT_80",
    "TIME_LIMIT_50", "ARRAY_TASKS"}

    Notify user by email when certain event types occur (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_mail-type>`__).  Default:
    ``'FAIL'``.
--mail-user
    User to receive email notification.  Default: ``None``, which means
    the submitting user.
--nodes
    Number of nodes to allocate (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_nodes>`__).  Default:
    ``'1'``.
--non-exclusive
    Do **not** allocate nodes exclusively, i.e. share nodes with other
    running jobs.  This option turns **off** sbatch's \--exclusive
    option (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_exclusive>`__), which is
    otherwise parsed to sbatch on default by this submission script.
--partition
    Request a specific partition for the resource allocation (`more
    details <https://slurm.schedmd.com/sbatch.html#OPT_partition>`__).
    You can use :bash:`sinfo --summarize` to get a list of all
    partitions available on your computing cluster.  Default:``None``,
    which means the default partition as designated by the cluster
    administrator.
--requeue
    Specifies that the batch job should be eligible for requeuing (`more
    details <https://slurm.schedmd.com/sbatch.html#OPT_requeue>`__).  If
    not set, --no-requeue is parsed to sbatch on default by this
    submission script.
--sbatch
    Additional options to parse to sbatch, provided as one long,
    enquoted string.  Make sure that your additional options do not
    collide with options set above.  See below for possibly useful
    options.  Do not use the \--signal option here, because this is used
    internally to allow for cleanup steps.  Default: ``None``.

List of possibly useful options to parse to sbatch via \--sbatch.  Refer
to the `documetation of sbatch
<https://slurm.schedmd.com/sbatch.html>`__ for a full list of all
options.  Note that the sbatch options \--job-name and \--output are set
to ``'SETTINGS + "_" + SYSTEM'`` and
``'SETTINGS + "_out_" + SYSTEM + "_slurm-%j.out'`` if they are not
explicitly parsed to \--sbatch.

--account
    Charge resources used by this job to the specified account (`more
    details <ttps://slurm.schedmd.com/sbatch.html#OPT_account>`__).
--begin
    Defer the allocation of the job until the specified time (`more
    details <https://slurm.schedmd.com/sbatch.html#OPT_begin>`__).
--chdir
    Set the working directory of the batch script before it is executed
    (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_chdir>`__).
--constraint
    Specify which features are required by this job (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_constraint>`__).  You can
    use :bash:`sinfo --format "%12P | %.15f"` to see which features are
    available on which partition.
--cpus-per-task
    Number of CPUs per task (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_cpus-per-task>`__).  This
    option is ignored if \--non-exclusive is **not** set.  The option
    specifies the number of OpenMP threads to use to run Gromacs,
    if \--no-guess-threads is given.
--dependency
    Defer the start of this job until the specified dependencies have
    been satisfied (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_dependency>`__).  If
    multiple jobs are submitted with --nresubmits, the given dependency
    only applies to the first job and the other jobs depend on each
    other.
--exclude
    Explicitly exclude certain nodes from the resources granted to the
    job (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_exclude>`__).
--extra-node-info
    Restrict node selection to nodes with at least the specified number
    of sockets, cores per socket and/or threads per core (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_extra-node-info>`__).
--gres
    Generic consumable resources (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_gres>`__).  This option
    is ignored if \--non-exclusive is **not** set.
--hold
    Submit the job in a held state (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_hold>`__).
--ntasks-per-node
    Number of tasks per node (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_ntasks-per-node>`__).
    This specifies the number of thread-MPI ranks to use to run Gromacs,
    if \--no-guess-threads is given.  If \--gmx-exe-mpi is given, this
    specifies the number of MPI ranks.  Must be provided via \--sbatch
    if \--no-guess-threads and/or \--gmx-exe-mpi is given.
--mem
    Memory required per node. (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_mem>`__).
--mincpus
    Minimum number of CPUs per node (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_mincpus>`__).
--nodelist
    Request a specific list of nodes (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_nodelist>`__).
--test-only
    Return an estimate of when a job would be scheduled to run.  No job
    is actually submitted (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_test-only>`__).
--time
    Set a total run time limit (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_time>`__).  You can use
    :bash:`sinfo --summarize` to get the maximum allowed run time limits
    for each partition on your computing cluster.
--time-min
    Set a minimum time limit.  If specified, the job may have its
    \--time limit lowered to a value no lower than \--time-min if doing
    so permits the job to begin execution earlier than otherwise
    possible (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_time-min>`__).

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
        -p ${system}.top \
        -o ${settings}_${system}.tpr \
        ${grompp_flags[@]} \
        -n ${system}.ndx  # Only if present

    ${gmx_exe} mdrun \
        -s ${settings}_${system}.tpr \
        -deffnm ${settings}_out_${system} \
        ${mdrun_flags[@]} \
        -ntmpi ${SLURM_NTASKS_PER_NODE} \  # Only if not guessed
        -ntomp ${CPUS_PER_TASK}  # Only if not guessed

Therefore, the following files must exist in your working directory:

    * :file:`SETTINGS_SYSTEM.mdp`
    * :file:`STRUCTURE`
    * :file:`SYSTEM.top`

The bash variable ${CPUS_PER_TASK} is set to ${SLURM_CPUS_PER_TASK} or
if ${SLURM_CPUS_PER_TASK} is not specified, it is set to
:bash:`$((SLURM_CPUS_ON_NODE / SLURM_NTASKS_PER_NODE))`.

When continuing a previous simulation, the following commands will be
launched:

.. code-block:: bash

    ${gmx_exe} mdrun \
        -s ${settings}_${system}.tpr \
        -deffnm ${settings}_out_${system} \
        ${mdrun_flags[@]} \
        -ntmpi ${SLURM_NTASKS_PER_NODE} \  # Only if not guessed
        -ntomp ${CPUS_PER_TASK} \  # Only if not guessed
        -cpi ${settings}_out_${system}.cpt \
        -append

Therefore, the following files must exist in your working directory:

    * :file:`SETTINGS_SYSTEM.mdp` (to check when the desired number of
      simulation steps is reached)
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


# Standard libraries
import argparse
import glob
import os
import shlex
import subprocess as subproc
import sys
import warnings


def rm_option(cmd, option):
    """
    Remove an option from a command string.

    Parameters
    ----------
    cmd : str
        The command from which to remove the given option(s).
    option : str or list or tuple
        The option(s) to remove.

    Returns
    -------
    cmd_new : str
        The command without the given option(s).

    Examples
    --------
    >>> cmd = "--job-name=Test -o out.log --dependency afterok:12 -c 4"
    >>> options = ("--dependency", "-d")
    >>> rm_option(cmd, options)
    --job-name=Test -o out.log -c 4
    >>> cmd = "--job-name=Test -o out.log --dependency=afterok:12 -c 4"
    >>> rm_option(cmd, options)
    --job-name=Test -o out.log -c 4
    >>> cmd = "--job-name=Test -o out.log -d afterok:12 -c 4"
    >>> rm_option(cmd, options)
    --job-name=Test -o out.log -c 4
    >>> cmd = "--job-name=Test -o out.log -d=afterok:12 -c 4"
    >>> rm_option(cmd, options)
    --job-name=Test -o out.log -c 4
    >>> cmd = "-o out.log --dependency afterok:12 -d afterok:14 -c 4"
    >>> rm_option(cmd, options)
    -o out.log -c 4
    >>> rm_option(cmd, "--dependency")
    -o out.log -d afterok:14 -c 4
    >>> rm_option(cmd, "--dep")
    -o out.log -d afterok:14 -c 4
    >>> rm_option(cmd, "-d")
    -o out.log --dependency afterok:12 -c 4
    >>> cmd = "-o out.log -d afterok:12 -n 2 -d afterok:14 -c 4"
    >>> rm_option(cmd, "-d")
    -o out.log -n 2 -c 4
    """
    if isinstance(option, (list, tuple)):
        for opt in option:
            cmd = rm_option(cmd, opt)
    elif option in cmd:
        cmd_list = shlex.split(cmd)
        opt_ix = [
            i for i, o in enumerate(cmd_list) if o.startswith(option.strip())
        ]
        for ix in opt_ix:
            # Remove the option.
            popped = cmd_list.pop(ix)
            # NOTE: `shlex.split` does not split at '=' but at spaces.
            if "=" not in popped:
                # Remove the corresponding option value.
                cmd_list.pop(ix)
        cmd = " ".join(cmd_list)
    return cmd
file_root = os.path.abspath(os.path.dirname(__file__))
python_dir = os.path.join(file_root, "../../python")
if not os.path.isdir(python_dir):
    raise FileNotFoundError(
        "No such directory: '{}'.  This might happen if you change the"
        " directory structure of this project".format(python_dir)
    )
sys.path.insert(1, python_dir)
# Third-party libraries
import gmx  # noqa: E402
import strng  # noqa: E402


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
            " set with --nodes is greater than one.  If given,"
            " --ntasks-per-node must be provided via --sbatch.  Default:"
            " %(default)s"
        ),
    )
    parser.add_argument(
        "--no-guess-threads",
        dest="NO_GUESS_THREADS",
        required=False,
        default=False,
        action="store_true",
        help=(
            "Do not let Gromacs guess the number of thread-MPI ranks and"
            " OpenMP threads, but set them to --ntasks-per-node and"
            " --cpus-per-task.  If given, --ntasks-per-node must be provided"
            " via --sbatch."
        ),
    )
    parser.add_argument(
        "--mdrun-flags",
        dest="GMX_MDRUN_FLAGS",
        type=str,
        required=False,
        default="-cpt 60",
        help=(
            "Additional options to parse to Gromacs 'mdrun' engine, provided"
            " as one long, enquoted string, e.g. '-npme 12'.  Default:"
            " '%(default)s'"
        ),
    )
    parser.add_argument(
        "--grompp-flags",
        dest="GMX_GROMPP_FLAGS",
        type=str,
        required=False,
        default="",
        help=(
            "Additional options to parse to the Gromacs preprocessor 'grompp',"
            " provided as one long, enquoted string, e.g. '-maxwarn 1'.  Is"
            " ignored if --continue is 1 or 3.  Default: '%(default)s'"
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
    if len(NODES.split("-")) not in (1, 2):
        raise ValueError("Invalid format of --nodes ({})".format(NODES))
    MIN_NODES = int(NODES.split("-")[0])
    MAX_NODES = int(NODES.split("-")[-1])
    if MIN_NODES == "" or MAX_NODES == "" or MIN_NODES < 0 or MAX_NODES < 0:
        raise ValueError("--nodes ({}) must not be negative".format(NODES))
    if MAX_NODES > 1 and (args.GMX_MPI_EXE is None or args.GMX_MPI_EXE == 0):
        raise ValueError(
            "--gmx-mpi-exe must be provided if the (maximum) number of nodes"
            " ({}) is greater than one".format(NODES)
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
            " parsed to the Gromacs preprocessor grompp"
            " automatically".format(args.SYSTEM),
            UserWarning,
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
                    sbatch += " " + str(item)
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
        if args.NO_GUESS_THREADS or (
            args.GMX_MPI_EXE is not None and args.GMX_MPI_EXE != 0
        ):
            raise ValueError(
                "--ntasks-per-node must be provided via --sbatch if"
                " --no-guess-threads and/or --gmx-exe-mpi is given"
            )
    else:
        if (
            "--job-name" not in args.SB_OPTIONS
            and "-J " not in args.SB_OPTIONS
            and "-J=" not in args.SB_OPTIONS
        ):
            sbatch += job_name
        if (
            "--output" not in args.SB_OPTIONS
            and "-o " not in args.SB_OPTIONS
            and "-o=" not in args.SB_OPTIONS
        ):
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
        if (
            args.NO_GUESS_THREADS
            or (args.GMX_MPI_EXE is not None and args.GMX_MPI_EXE != 0)
        ) and "--ntasks-per-node" not in args.SB_OPTIONS:
            raise ValueError(
                "--ntasks-per-node must be provided via --sbatch if"
                " --no-guess-threads and/or --gmx-exe-mpi is given"
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
                        "The option '{}' parsed to --sbatch is already set by"
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
    nsteps = gmx.get_nsteps_from_mdp(
        args["settings"] + "_" + args["system"] + ".mdp"
    )
    pos_args_list = [
        bash_dir,
        args.SYSTEM,
        args.SETTINGS,
        str(args.STRUCTURE),
        str(args.CONTINUE),
        str(nsteps),
        str(int(not args.NO_BACKUP)),
        gmx_lmod,
        args.GMX_EXE,
        str(args.GMX_MPI_EXE),
        str(int(not args.NO_GUESS_THREADS)),
        "'{}'".format(args.GMX_MDRUN_FLAGS),
        "'{}'".format(args.GMX_GROMPP_FLAGS),
    ]
    pos_args = " ".join(pos_args_list)

    print("Submitting job(s) to Slurm...")
    submit = sbatch + " " + batch_script + " " + pos_args
    job_id = subproc.check_output(shlex.split(submit))
    if args.CONTINUE in (2, 3):  # Resubmit
        job_id = strng.extract_ints_from_str(job_id)[0]
        # After the first job submission the following jobs always
        # continue a previous simulation. => The `continue` option of
        # all following jobs must be set to '3'.
        pos_args_list[4] = "3"  # Set `continue` to '3'
        pos_args = " ".join(pos_args_list)
        # After the first job submission the following jobs only depend
        # on the respective previous job => Remove possible dependencies
        # that the user specified for the first job.
        sbatch = rm_option(sbatch, ("--dependency", "-d"))
        for _ in range(args.NRESUBMITS):
            sbatch_dep = sbatch + " --dependency afterok:{}".format(job_id)
            submit = sbatch_dep + " " + batch_script + " " + pos_args
            job_id = subproc.check_output(shlex.split(submit))
            job_id = strng.extract_ints_from_str(job_id)[0]

    print("{} done".format(os.path.basename(sys.argv[0])))
