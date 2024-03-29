.. _dev-install-label:

Development Installation
========================

.. contents:: Site Contents
    :depth: 2
    :local:


1. Get hpcss
------------

Clone the project repository to any location on your computer:

.. code-block:: bash

    git clone https://github.com/andthum/hpc_submit_scripts.git

.. note::

    If you want to contribute your changes back to the upstream
    repository, you should first create your own fork of the project
    and clone this fork instead of the original repository (see section
    :ref:`step0-label` in :ref:`git-workflow-label`).


.. _set-up-dev-env-label:

2. Set up a Development Environment
-----------------------------------

Create a |virtual_Python_environment|, preferably in the root directory
of the project:

.. code-block:: bash

    # Enter the root directory of the project.
    cd hpc_submit_scripts/
    # Create a virtual environment called ".venv-dev".
    python3 -m venv .venv-dev
    # Activate the virtual environment.
    source .venv-dev/bin/activate
    # Upgrade pip, setuptools and wheel.
    python3 -m pip install --upgrade pip setuptools wheel

Every time you start working on the project, you should first activate
the virtual environment.  After you have finished working on the
project, you can deactivate the virtual environment by typing
:bash:`deactivate`.

The advantage of using a virtual environment is that the development
process is isolated from the rest of your system in the sense that
Python packages that are installed inside the virtual environment do not
interfere with other Python packages installed on your computer.


.. _install-dev-packages-label:

3. Install the Development Packages
-----------------------------------

Install the packages required for developing the project (i.e.
formatters, linters, testing packages, pre-commit, etc.) into the
:ref:`development environment <set-up-dev-env-label>`:

.. code-block:: bash

    python3 -m pip install --upgrade -r requirements-dev.txt


.. _set-up-pre-commit-label:

4. Set up pre-commit
--------------------

This project uses `pre-commit`_ to run several tests on changed files
automatically at every call of :bash:`git commit`.  When you have
installed the :ref:`development packages <install-dev-packages-label>`,
you can install the pre-commit script and the pre-commit git hooks for
this project by typing:

.. code-block:: bash

    pre-commit install --install-hooks

.. note::

    You might need to install
    `markdownlint <https://github.com/markdownlint/markdownlint>`_ (a
    Ruby gem package) in order to get the markdownlint pre-commit hook
    running.

    Software required for installing `RubyGems <https://rubygems.org/>`_
    packages:

    * Ruby developer package
    * `Ruby <https://www.ruby-lang.org/en/>`_
    * `RubyGems <https://rubygems.org/>`_

You can check if pre-commit works properly by running

.. code-block:: bash

    pre-commit run --all-files

(It's ok if not all tests pass as long as pre-commit itself runs without
error.)

Note that all pre-commit hooks are also run automatically every time you
push to the upstream repository as part of our Continuous Integration
(CI) workflow which includes `pre-commit.ci`_.  Your changes might not
be accepted before not all tests that are affected by your changes are
passing.


Uninstall
---------

To uninstall the project, just remove the project directory:

.. code-block:: bash

    # Remove the project directory.
    rm -r path/to/hpc_submit_scripts/


.. _pre-commit: https://pre-commit.com
.. _pre-commit.ci: https://pre-commit.ci
