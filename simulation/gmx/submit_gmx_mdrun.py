#!/usr/bin/env python3

# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst


r"""
Start or continue a molecular dynamics (MD) simulation with |Gromacs| on
a computing cluster that uses the |Slurm| Workload Manager.

This script is designed to be used on the |Palma2| HPC cluster of the
University of Münster or on the |Bagheera| HPC cluster of the
|RG_of_Professor_Heuer|.

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
    Name of the file that contains the starting structure in a
    `format that is readable by Gromacs`_.  The starting structure is
    ignored if you continue a previous simulation.  Default: ``None``.
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
    subdirectory before continuing a previous simulation using |rsync|.
    This might take up to a few hours depending on the size of the
    files.  With \--no-backup you can skip this backup, but be aware
    that your trajectory (and other simulation files) might get
    corrupted if the continuation of the simulation fails badly.
--gmx-lmod
    If running on a cluster which uses the |Lmod| module system,
    specifiy here which file to source (relative to the :file:`lmod`
    subdirectory of this project) to load Gromacs.  Default:
    ``'palma/2019a/gmx2018-8_foss.sh'``.
--gmx-exe
    Name of the Gromacs executable.  Default: ``'gmx'``.
--gmx-mpi-exe
    Name of the MPI version of the Gromacs executable.  If provided, the
    simulation will be run using this executable instead of 'gmx mdrun'.
    Must be provided if the (maximum) number of nodes set with \--nodes
    is greater than one.  If given, \--ntasks-per-node must be provided
    to |sbatch|.  Default: ``None``.
--no-guess-threads
    Don't let Gromacs guess the number of thread-MPI ranks and OpenMP
    threads, but set the number of thread-MPI ranks to
    :bash:`${SLURM_NTASKS_PER_NODE}` and the number of OpenMP threads to
    :bash:`${CPUS_PER_TASK}`, which is equivalent to
    :bash:`${SLURM_CPUS_PER_TASK}` (see Notes below).  Note, if
    \--gmx-mpi-exe is provided, the number of MPI ranks is always set to
    :bash:`${SLURM_NTASKS_PER_NODE}` and guessing only affects the
    number of OpenMP threads.  If \--no-guess-threads is given,
    \--ntasks-per-node must be provided to |sbatch|.
--mdrun-flags
    Additional options to parse to the Gromacs 'mdrun' engine, provided
    as one long, enquoted string, e.g. '-npme 12'.  Default:
    ``'-cpt 60'``.
--grompp-flags
    Additional options to parse to the Gromacs preprocessor 'grompp',
    provided as one long, enquoted string, e.g. '-maxwarn 1'.  Is
    ignored if \--continue is 1 or 3.  Default: ``''``.

You can provide arbitrary other options to this script.  All these other
options are parsed directly to the |sbatch| Slurm command without
further introspection or validation.  This means, you can parse any
option to sbatch but you are responsible for providing correct options.

sbatch options with additional meaning in the context of this submit
script:

--cpus-per-task
    Number of CPUs per task (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_cpus-per-task>`__).  This
    specifies the number of OpenMP threads to use to run Gromacs if
    \--no-guess-threads is given.
--ntasks-per-node
    Number of tasks per node (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_ntasks-per-node>`__).
    This specifies the number of thread-MPI ranks to use to run Gromacs
    if \--no-guess-threads is given.  If \--gmx-exe-mpi is given, this
    specifies the number of MPI ranks.  Must be provided if
    \--no-guess-threads and/or \--gmx-exe-mpi is given.
--signal
    You cannot parse \--signal to sbatch, because this option is used
    internally to allow for cleanup steps after the simulation has
    finished.

Config File
-----------
This script reads options from the following sections of a
|config_file|:

    * [submit]
    * [submit.simulation]
    * [sbatch]
    * [sbatch.simulation]

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

    * :bash:`${settings}_${system}.mdp`
    * :bash:`${structure}`
    * :bash:`${system}.top`

The bash variable :bash:`${CPUS_PER_TASK}` is set to
:bash:`${SLURM_CPUS_PER_TASK}` or if :bash:`${SLURM_CPUS_PER_TASK}` is
not specified, it is set to
:bash:`$((SLURM_CPUS_ON_NODE / SLURM_NTASKS_PER_NODE))`.

When continuing a previous simulation, the following command will be
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

    * :bash:`${settings}_${system}.mdp` (to check when the desired
      number of simulation steps is reached)
    * :bash:`${settings}_${system}.tpr`
    * :bash:`${settings}_out_${system}.cpt`

:bash:`${settings}_${system}.mdp` is also required when continuing a
previous simulation, because the maximum number of simulation steps is
read from this file.

If the these files cannot be found, the submission script will terminate
with an error message before submitting the job to the Slurm Workload
Manager.


.. _format that is readable by Gromacs:
    https://manual.gromacs.org/documentation/current/reference-manual/file-formats.html#structure-files
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
import opthandler  # noqa: E402
import strng  # noqa: E402


if __name__ == "__main__":  # noqa: C901
    parser = argparse.ArgumentParser(
        description=(
            "Start or continue a molecular dynamics (MD) simulation with"
            " Gromacs on a computing cluster that uses the Slurm Workload"
            " Manager.  For more information, refer to the documetation of"
            " this script."
        )
    )
    parser.add_argument(
        "--system",
        type=str,
        required=True,
        help=("The name of the system to simulate."),
    )
    parser.add_argument(
        "--settings",
        type=str,
        required=True,
        help=("The simulation settings to use."),
    )
    parser.add_argument(
        "--structure",
        type=str,
        required=False,
        default=None,
        help=(
            "Name of the file that contains the starting structure.  Is"
            " ignored if you continue a previous simulation.  Default:"
            " %(default)s"
        ),
    )
    parser.add_argument(
        "--continue",
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
        required=False,
        default=False,
        action="store_true",
        help=("Skip backup before continuing a previous simulation."),
    )
    parser.add_argument(
        "--gmx-lmod",
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
        type=str,
        required=False,
        default="gmx",
        help=("Name of the Gromacs executable.  Default: %(default)s"),
    )
    parser.add_argument(
        "--gmx-mpi-exe",
        type=str,
        required=False,
        default=None,
        help=(
            "Name of the MPI version of the Gromacs executable.  If provided,"
            " the simulation will be run using this executable instead of"
            " 'gmx mdrun'.  Must be provided if the (maximum) number of nodes"
            " set with --nodes is greater than one.  If given,"
            " --ntasks-per-node must be provided to sbatch.  Default:"
            " %(default)s"
        ),
    )
    parser.add_argument(
        "--no-guess-threads",
        required=False,
        default=False,
        action="store_true",
        help=(
            "Don't let Gromacs guess the number of thread-MPI ranks and OpenMP"
            " threads, but set them to --ntasks-per-node and --cpus-per-task."
            "  If given, --ntasks-per-node must be provided to sbatch."
        ),
    )
    parser.add_argument(
        "--mdrun-flags",
        type=str,
        required=False,
        default="-cpt 60",
        help=(
            "Additional options to parse to Gromacs 'mdrun' engine, provided"
            " as one long, enquoted string.  Default: '%(default)s'"
        ),
    )
    parser.add_argument(
        "--grompp-flags",
        type=str,
        required=False,
        default="",
        help=(
            "Additional options to parse to the Gromacs preprocessor 'grompp',"
            " provided as one long, enquoted string, e.g. '-maxwarn 1'.  Is"
            " ignored if --continue is 1 or 3.  Default: '%(default)s'"
        ),
    )
    opts = opthandler.get_opts(
        argparser=parser,
        secs_known=("submit", "submit.simulation"),
        secs_unknown=("sbatch", "sbatch.simulation"),
    )
    args = opts["submit"]
    args_sbatch = opts["sbatch"]

    print("Checking parsed arguments...")
    if args["nresubmits"] < 0:
        raise ValueError(
            "--nresubmits ({}) must not be negative".format(args["nresubmits"])
        )
    if (
        args["gmx_mpi_exe"] is not None or args["no_guess_threads"]
    ) and "ntasks-per-node" not in args_sbatch:
        raise ValueError(
            "--ntasks-per-node must be provided to sbatch if --gmx-exe-mpi"
            " and/or --no-guess-threads is given"
        )
    if "signal" in args_sbatch:
        raise ValueError(
            "'--signal' is not allowed to be parsed to sbatch, because it is"
            " used internally to allow for cleanup steps"
        )
    if "nodes" in args_sbatch:
        NODES = str(args_sbatch["nodes"])
    elif "N" in args_sbatch:
        NODES = str(args_sbatch["N"])
    else:
        NODES = None
    if NODES is not None:
        if len(NODES.split("-")) not in (1, 2):
            raise ValueError("Invalid format of -N/--nodes ({})".format(NODES))
        MIN_NODES = int(NODES.split("-")[0])
        MAX_NODES = int(NODES.split("-")[-1])
        if MIN_NODES < 0 or MAX_NODES < 0:
            raise ValueError("--nodes ({}) must not be negative".format(NODES))
        if MAX_NODES > 1 and args["gmx_mpi_exe"] is None:
            raise ValueError(
                "--gmx-mpi-exe must be provided if the (maximum) number of"
                " nodes ({}) is greater than one".format(NODES)
            )

    print("Checking if input files exist...")
    if args["continue"] in (0, 2):  # Start a new simulation
        if args["structure"] is None:
            raise ValueError(
                "You must provide a structure file with --structure if you"
                " start a new simulation"
            )
        files = {
            "parameter": args["settings"] + "_" + args["system"] + ".mdp",
            "structure": args["structure"],
            "topology": args["system"] + ".top",
        }
    elif args["continue"] in (1, 3):  # Continue a previous simulation
        files = {
            "parameter": args["settings"] + "_" + args["system"] + ".mdp",
            "run-input": args["settings"] + "_" + args["system"] + ".tpr",
            "checkpoint": args["settings"] + "_out_" + args["system"] + ".cpt",
        }
    else:
        raise ValueError(
            "Invalid choice for --continue" " ({})".format(args["continue"])
        )
    for filetype, filename in files.items():
        if not os.path.isfile(filename):
            raise FileNotFoundError(
                "No such file: '{}' ({} file)".format(filename, filetype)
            )
    ndx_files = glob.glob("*.ndx")
    if len(ndx_files) > 0 and args["system"] + ".ndx" not in ndx_files:
        warnings.warn(
            "Detected .ndx file(s) in the working directory, but no .ndx file"
            " named '{0}.ndx'.  Only an .ndx file named '{0}.ndx' will be"
            " parsed to the Gromacs preprocessor grompp"
            " automatically".format(args["system"]),
            UserWarning,
        )

    print("Constructing the submit command...")
    # Assemble arguments to parse to sbatch
    if "job-name" not in args_sbatch and "J" not in args_sbatch:
        args_sbatch["job-name"] = args["settings"] + "_" + args["system"]
    if "output" not in args_sbatch and "o" not in args_sbatch:
        args_sbatch["output"] = (
            args["settings"] + "_out_" + args["system"] + "_slurm-%j.out"
        )
    sbatch = "sbatch "
    sbatch += opthandler.optdict2str(
        args_sbatch, skiped_opts=("None", "False"), dumped_vals=("True",)
    )
    # Assemble position arguments to parse to the batch script itself
    batch_script = os.path.join(file_root, "gmx_mdrun.sh")
    if not os.path.isfile(batch_script):
        raise FileNotFoundError(
            "No such file: '{}'.  This might happen if you change the"
            " directory structure of this project".format(batch_script)
        )
    bash_dir = os.path.join(file_root, "../../bash")
    if not os.path.isdir(bash_dir):
        raise FileNotFoundError(
            "No such directory: '{}'.  This might happen if you change the"
            " directory structure of this project".format(bash_dir)
        )
    gmx_lmod = os.path.join(file_root, "../../lmod/" + args["gmx_lmod"])
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
    # Position arguments must be in the right order for the batch script
    pos_args_list = [
        bash_dir,
        args["system"],
        args["settings"],
        args["structure"],
        args["continue"],
        nsteps,
        not args["no_backup"],
        gmx_lmod,
        args["gmx_exe"],
        args["gmx_mpi_exe"],
        not args["no_guess_threads"],
        args["mdrun_flags"],
        args["grompp_flags"],
    ]
    # Convert `True` to 1 and `False` to 0
    pos_args_list = [
        int(arg) if isinstance(arg, bool) else arg for arg in pos_args_list
    ]
    pos_args = shlex.join(str(arg) for arg in pos_args_list)

    print("Submitting job(s) to Slurm...")
    submit = sbatch + " " + batch_script + " " + pos_args
    job_id = subproc.check_output(shlex.split(submit))
    if args["continue"] in (2, 3):  # Resubmit
        job_id = strng.extract_ints_from_str(job_id)[0]
        # After the first job submission the following jobs always
        # continue a previous simulation. => The `continue` option of
        # all following jobs must be set to 3.
        pos_args_list[4] = 3  # Set `continue` to 3.
        pos_args = shlex.join(str(arg) for arg in pos_args_list)
        # After the first job submission the following jobs only depend
        # on the respective previous job => Remove possible dependencies
        # that the user specified for the first job.
        sbatch = opthandler.rm_option(sbatch, ("--dependency", "-d"))
        for _ in range(args["nresubmits"]):
            sbatch_dep = sbatch + " --dependency afterok:{}".format(job_id)
            submit = sbatch_dep + " " + batch_script + " " + pos_args
            job_id = subproc.check_output(shlex.split(submit))
            job_id = strng.extract_ints_from_str(job_id)[0]

    print("{} done".format(os.path.basename(sys.argv[0])))
