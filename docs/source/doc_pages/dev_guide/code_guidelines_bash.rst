.. _code-guide-bash-label:

Bash Code Guidelines
====================

.. contents:: Site Contents
    :depth: 2
    :local:


Formatters and Linters
----------------------

When writting Bash code for this project, please

    * Format your code with |shfmt|.

      To format a file :file:`spam.sh` run
      :file:`shfmt -ln=bash -i=4 -ci -sr -w path/to/spam.sh` in a
      terminal.

      shfmt can e.g. be installed as a `snap package
      <https://snapcraft.io/shfmt>`_.  Alternatively, you can install
      the Python package |shfmt-py|, which is anyway listed in
      :file:`requirements-dev.txt`.

    * Lint your code with |shellcheck|.

      To lint a file :file:`spam.sh` run
      :file:`shellcheck path/to/spam.sh` in a terminal.  The settings to
      use are specified in :file:`.shellcheckrc`, which is automatically
      read by shellcheck.

      For many Linux distributions, shellcheck can be install from the
      official repositories.  Alternatively, you can install the Python
      package |shellcheck-py|, which is anyway listed in
      :file:`requirements-dev.txt`.

.. note::

    The listed formatters and linters offer plugins for many popular
    text editors.  When using these plugins, your code is formatted and
    lintted on the fly, so you don't have to run the commands yourself.

.. note::

    If you set up :ref:`pre-commit-label` (strongly recommended), the
    above formatters and linters check your code before every commit.
