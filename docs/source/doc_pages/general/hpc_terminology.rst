.. _hpc-terminology-label:

HPC Terminology
===============

This page contains a non-exhaustive list of terms that are important for
getting a basic understanding of an HPC system and how to use it.

Users of the Palma2 HPC cluster of the University of Münster should also
refer to the `Palma2 Wiki`_.

.. contents:: Site Contents
    :depth: 2


High Performance Computing (HPC)
--------------------------------

Local machine
    Your local desktop or laptop computer.
Cluster
    A group of computers (so-called nodes), connected by a network to
    function as if they were one, large computer with a lot of resources
    (CPU, GPU, RAM, disk space, ...).
Node
    One of the computers of a computer cluster.
Socket
    The slot which hosts the CPU and connects it with the motherboard.
    A single motherboard might have multiple sockets.
CPU
    The Central Processing Unit (CPU), or simply processor, does the
    arithmetic and logic and controls the rest of the computer.
Physical Core
    A physical (i.e. really present) subunit of the CPU.
Logical Core
    A software abstraction that allows you to run multiple threads on
    one physical CPU core.  For instance, with Intel's hyper-threading
    technology you can run two threads on one physical core.  In short,
    the number of logical cores is the number of physical cores times
    the number of threads that each physical core can run
    (quasi-)simultaneously.
Thread
    A set of instructions to be executed by the CPU.
Process
    A running program.
GPU
    The graphics processing unit (GPU) processes the data to be shown on
    a display.  GPUs have hundreds of cores and can therefore be used to
    execute massively parallel programs.
RAM
    Random Access Memory (RAM), or simply memory, is the main memory
    (German "Arbeitsspeicher") of a computer.
Hard Disk Storage
    The storage that holds all your data (German "Festplattenspeicher").


Slurm Workload Manager
----------------------

The |Slurm| (Simple Linux Utility for Resource Management) Workload
Manager is a popular software package that organizes and schedules the
jobs of different users in such a way that the HPC cluster is optimally
used and each user gets a fair amount of computing time.

Core/CPU
    Slurm uses the terms Core and CPU interchangeably depending on the
    context.  For instance, the sbatch option \--cpus-per-task is
    actually specifying the number of cores per task.  Whether these are
    physical or logical cores depends on whether the cluster
    administrator has enabled threading or not.  To get an overview of
    the resources available on your cluster you can run
    :bash:`sinfo --format "%12P | %.22g | %.12l | %.6a | %.15F | %.23C | %.5c | %.8X | %.6Y | %.8Z | %.8m | %.15f | %.15G"`.
Partition
    A waiting line in which you can submit your jobs.  Usually, one or
    more nodes are assigned to a partition.  If you submit a job to a
    partition it will only run on the nodes assigned to this partition.
    However, one and the same node can be assigned to multiple
    partitions.
Job
    A self-contained computation that is submitted to a partition.  A
    job might consist of multiple steps (e.g. a preparation step, the
    actual computation and a clean-up step) which in turn consist of one
    or more tasks that run on one or more CPUs (for an example see
    https://stackoverflow.com/a/46532581).
Step
    A self-contained part of a job.
Task
    A single run of a single program.


Parallel Computing
------------------

Terms that you will probably come across when you perform computations
on multiple CPUs:

Distributed-Memory System
    A computer with mutliple processors in which each processor has its
    own private memory.  Processors cannot access the memory of other
    processors.
Shared-Memory System
    A computer with mutliple processors that all share the same memory.
MPI
    The Message Passing Interface (MPI) is a message-passing standard
    that allows multiple processes that run in separate memory spaces to
    exchange information.  Hence, MPI allows you to run a program in
    parallel on different CPUs in a distributed-memory system.  It can
    also be used on shared-memory systems but usually this causes some
    overhead compared to using OpenMP.
OpenMP
    Open Multi-Processing (OpenMP) is an Application Programming
    Interface (API) that allows you to run a program in parallel on one
    or more CPUs in a shared-memory system.

Usually, all CPUs on one node share the same memory but different nodes
have different memory spaces.  Hence, if you want to run your program on
multiple nodes, you *must* use MPI for communication between processes
on different nodes and you *can* use OpenMP for communication between
processes/threads on the same node (this would be a so-called hybrid
MPI-OpenMP job).

MPI ranks can be identified with Slurm tasks and OpenMP threads
correspond to the number of cores per task (sbatch's \--cpus-per-task
option).  But this is just a rule of thumb.  There exists no strict
connection.


.. _Palma2 Wiki:
    https://confluence.uni-muenster.de/display/HPC/High+Performance+Computing
