.. _code-guide-bash-label:

Bash Code Guidelines
====================

.. contents:: Site Contents
    :depth: 2
    :local:


Formatters and Linters
----------------------

When writing Bash code for this project, please

    * Format your code with |shfmt|.

      To format a file :file:`spam.sh` run
      :file:`shfmt -ln=bash -i=4 -ci -sr -w path/to/spam.sh` in a
      terminal.

    * Lint your code with |shellcheck|.

      To lint a file :file:`spam.sh` run
      :file:`shellcheck path/to/spam.sh` in a terminal.  The settings to
      use are specified in :file:`.shellcheckrc`, which is automatically
      read by shellcheck.

.. note::

    The listed formatters and linters offer plugins for many popular
    text editors and integrated development environments (IDEs).  When
    using these plugins, your code is formatted and linted on the fly,
    so you don't have to run the commands yourself.

.. note::

    If you have :ref:`set up pre-commit <set-up-pre-commit-label>`, the
    above formatters and linters check your code before every commit.
