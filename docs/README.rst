###################
hpcss Documentation
###################

This directory contains the files for building the documentation of
hpcss using Sphinx_.

To build the documentation, the dependencies in
``docs/requirements-docs.txt`` must be installed:

.. code-block:: bash

    # Clone the project repository.
    git clone https://github.com/andthum/hpc_submit_scripts.git
    # Enter the docs directory of the project.
    cd hpc_submit_scripts/docs/
    # Create a virtual Python environment called ".venv-docs".
    python3 -m venv .venv-docs
    # Activate the virtual Python environment.
    source .venv-docs/bin/activate
    # Upgrade pip, setuptools and wheel.
    python3 -m pip install --upgrade pip setuptools wheel
    # Install the requirements to build the docs.
    python3 -m pip install --upgrade -r requirements-docs.txt

After installing all requirements, the documentation can be built via

.. code-block:: bash

    # Create the documentation.
    make html
    # Check if the code examples in the documentation work as expected.
    make doctest
    # Deactivate the virtual Python environment.
    deactivate


.. _Sphinx: https://www.sphinx-doc.org/
