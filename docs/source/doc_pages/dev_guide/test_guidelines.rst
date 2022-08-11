.. _test-guide-label:

Test Guidelines
===============

.. warning::

    Currently, the code is only partially tested via doctests.  However,
    tests are very important to ensure that the code is working as
    expected.  Without full test suites we cannot leave the alpha state
    of development.

.. contents:: Site Contents
    :depth: 2
    :local:


.. _writing-tests-label:

Writing Tests
-------------

Consistency Checks at Runtime
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Implement consistency checks in your code that check at runtime whether
the input and output of scripts, functions and other objects is
sensible.


Unit Tests
^^^^^^^^^^


Integration Tests
^^^^^^^^^^^^^^^^^


Regression Tests
^^^^^^^^^^^^^^^^


Performance Tests
^^^^^^^^^^^^^^^^^


.. _running-tests-label:

Running Tests
-------------

Tests are automatically run as `GitHub Actions`_ when pushing changes
to the upstream repository.  However, sometimes it is also useful to run
them locally.


Doctests
^^^^^^^^

We use :mod:`doctest` to check whether the code examples given in the
documentation work as expected.  Sphinx already brings a convient
`extension
<https://www.sphinx-doc.org/en/master/usage/extensions/doctest.html>`__
to run doctest on all our example codes.  Simply do:

.. code-block:: bash

    cd path/to/mdtools/docs/
    make doctest

Note that you have to install the requirements in
:file:`docs/requirements-docs.txt` to be able to run the above command
(see :ref:`build-docs-label`).


Unit Tests
^^^^^^^^^^

We plan to use |pytest| to run unit tests.  The tests can then be run
via

.. code-block:: bash

    cd path/to/mdtools/
    python3 -m pytest .


Integration Tests
^^^^^^^^^^^^^^^^^


Regression Tests
^^^^^^^^^^^^^^^^


Performance Tests
^^^^^^^^^^^^^^^^^


.. _GitHub Actions: https://docs.github.com/en/actions
