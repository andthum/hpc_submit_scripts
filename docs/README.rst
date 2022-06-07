###################
hpcss Documentation
###################

This directory contains the files for building the documentation of
hpcss using Sphinx_.

To build the documentation, the requirements in
``docs/requirements.txt`` must be installed (paths are given relative to
the project's root directory):

.. code-block:: bash

    # Clone the project repository
    git clone https://github.com/andthum/hpc_submit_scripts.git
    # Enter the project directory
    cd hpc_submit_scripts
    # Install/upgrade virtualenv
    python3 -m pip install --user --upgrade virtualenv
    # Create a virtual Python environment called "env"
    python3 -m virtualenv env
    # Activate the virtual Python environment
    source env/bin/activate
    # Upgrade pip, setuptools and wheel
    python3 -m pip install --upgrade pip setuptools wheel
    # Install the requirements to build the docs
    python3 -m pip install --upgrade -r docs/requirements.txt

After installing all requirements, the documentation can be built via

.. code-block:: bash

    cd docs
    # Create the documentation
    make html
    # Check if the code examples in the documentation work as expected
    make doctest
    # Deactivate the virtual Python environment
    deactivate


.. _Sphinx: https://www.sphinx-doc.org/
