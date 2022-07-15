.. _sbatch-options-label:

Useful sbatch Options
=====================

Usually, you can parse arbitrary additional options to Python submit
scripts (additional to the script's own options).  These options will be
parsed to the |sbatch| command that submits the Slurm job scripts.

This page contains a subset of sbatch options you might consider useful.
Refer to the `documetation of sbatch
<https://slurm.schedmd.com/sbatch.html>`__ for a full list of all
options.

You can set defaults for all sbatch options in the |config_file|.  This
is especially useful for options like \--account, \--mail-type,
\--mail-user or \--partition.

--account
    Charge resources used by this job to the specified account (`more
    details <https://slurm.schedmd.com/sbatch.html#OPT_account>`__).
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
    <https://slurm.schedmd.com/sbatch.html#OPT_cpus-per-task>`__).
--dependency
    Defer the start of this job until the specified dependencies have
    been satisfied (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_dependency>`__).  If a
    submit script submits multiple jobs that depend on each other, the
    given dependency only applies to the top-level job and the sub-level
    jobs only depend on the top-level job.
--exclude
    Explicitly exclude certain nodes from the resources granted to the
    job (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_exclude>`__).
--exclusive
    Don't share nodes with other jobs (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_exclusive>`__).
--extra-node-info
    Restrict node selection to nodes with at least the specified number
    of sockets, cores per socket and/or threads per core (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_extra-node-info>`__).
--gres
    Generic consumable resources (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_gres>`__).
--hold
    Submit the job in a held state (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_hold>`__).
--job-name
    Specify a name for the job allocation (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_job-name>`__).
--kill-on-invalid-dep
    {"yes", "no"}

    Whether to terminate the job when it has an invalid dependency and
    thus can never run (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_kill-on-invalid-dep>`__).
--mail-type
    {"NONE", "BEGIN", "END", "FAIL", "REQUEUE", "ALL", "INVALID_DEPEND",
    "STAGE_OUT", "TIME_LIMIT", "TIME_LIMIT_90", "TIME_LIMIT_80",
    "TIME_LIMIT_50", "ARRAY_TASKS"}

    Notify user by email when certain event types occur (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_mail-type>`__).
--mail-user
    User to receive email notification (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_mail-user>`__).
--mem
    Memory required per node. (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_mem>`__).
--mincpus
    Minimum number of CPUs per node (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_mincpus>`__).
--no-requeue
    Specifies that the batch job should never be requeued under any
    circumstances (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_no-requeue>`__).
--nodes
    Number of nodes to allocate (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_nodes>`__).
--nodelist
    Request a specific list of nodes (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_nodelist>`__).
--ntasks-per-node
    Number of tasks per node (`more details
    <https://slurm.schedmd.com/sbatch.html#OPT_ntasks-per-node>`__).
--output
    The file to which to write the batch script's standard output (`more
    details <https://slurm.schedmd.com/sbatch.html#OPT_output>`__).
--partition
    Request a specific partition for the resource allocation (`more
    details <https://slurm.schedmd.com/sbatch.html#OPT_partition>`__).
    You can use :bash:`sinfo --summarize` to get a list of all
    partitions available on your computing cluster.
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
