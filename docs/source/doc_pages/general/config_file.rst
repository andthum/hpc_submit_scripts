.. _config-file-label:

Configuration File
==================

You can set default options for the Python submit scripts and for the
|sbatch| command in a configuration file called :file:`hpcssrc.ini`.

.. contents:: Site Contents
    :depth: 2
    :local:


Search Paths
------------

The config file is read by the submit script at run time through the
function :func:`opthandler.read_config`.  This function searches for the
config file in the following order at the following locations:

    1. In the current working directory.
    2. At :file:`${HOME}/.hpcss/hpcssrc.ini` (where :file:`${HOME}`
       is the user's home directory).
    3. In the root directory of the hpc_submit_scripts repository.

As soon as a config file is found, this config file is read and
other locations are not scanned anymore.


Config File Syntax
------------------

The config file must be written in `INI language`_ as supported by the
built-in :mod:`configparser` Python module.

.. note::

    Don't use quotation marks in option values unless you explicitly
    want them to be part of the option value.

Differences to the default behaviour of :mod:`configparser`:

    * The only values that are interpreted as booleans are true and
      false. yes/no and on/off are read as strings.
    * Option names are case-sensitive.
    * Section names are case-insensitive and leading and trailing spaces
      are removed.


Config Sections
---------------

Which sections are recognized by which submit script is stated in the
"Config File" section of each script right below the "Options" section.

Generraly,

    * Options in [submit\*] sections are parsed to Python submit
      scripts.
    * Options in [sbatch\*] sections are parsed to |sbatch|.
    * Options in [\*.simulation\*] subsections are only read by Python
      scripts that submit simulations.
    * Options in [\*.analysis\*] subsections are only read by Python
      scripts that submit analysis tasks.

Options in lower-level sections ([section.subsection.subsubsection...])
overwrite same options in top-level sections ([section]).


Config Options
--------------

Basically, arbitrary option names and values are allowed.  However, the
Python submit scripts only read those options that exactly match their
command-line option names and check their values for validity.

All options listed in [sbatch\*] sections are parsed to |sbatch|.  If
one of these options is unknown to sbatch or has an invalid value,
sbatch will raise an error.


.. _INI language:
    https://docs.python.org/3/library/configparser.html#supported-ini-file-structure
