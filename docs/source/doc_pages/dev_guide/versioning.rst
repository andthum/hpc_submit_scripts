.. _versioning-label:

Versioning
==========

.. contents:: Site Contents
    :depth: 2
    :local:


Versioning Scheme
-----------------

This project uses `semantic versioning`_.  Given a version number
MAJOR.MINOR.PATCH, we increment the

    1. **MAJOR** version when we make **incompatible API changes**,
    2. **MINOR** version when we **add functionality** in a
       **backwards-compatible** manner, and
    3. **PATCH** version when we make backwards-compatible
       **bug fixes**.

Additionally, pre-release, post-release and developmental release
specifiers can be appended.

.. note::

    As long as the **MAJOR** number is 0 (i.e. the API has not
    stabilized), even **MINOR** increases *may* introduce incompatible
    API changes.

.. contents:: Site Contents
    :depth: 2
    :local:


.. _publishing-release-label:

Publishing a New Release
------------------------

.. note::

    New versions can only be released by project maintainers that have
    write access to the upstream repository.

Follow these steps when publishing a new release.


1. Update the Version Number
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Create a new branch out of ``main`` named
``chore/release/vMAJOR.MINOR.PATCH``.

.. code:: bash

    git checkout main
    git checkout -b chore/release/vMAJOR.MINOR.PATCH

Update :file:`AUTHORS.rst` to list all authors that have contributed to
the new release and commit the changes to the new branch.

Add authors that have contributed for the first time to the list of
authors in the :file:`pyproject.toml` file and commit the changes to the
new branch.

Update the version number in :file:`pyproject.toml` to the new
MAJOR.MINOR.PATCH version and commit the changes to the new branch.

Push the branch to the upstream repository.

.. code:: bash

    git push --set-upstream origin chore/release/vMAJOR.MINOR.PATCH

Open the upstream repository in GitHub, create a pull request and merge
the branch into ``main`` when all tests passed successfully.

Pull the changes to your remote repository.

.. code:: bash

    git checkout main
    git pull


1. Create a New Tag
^^^^^^^^^^^^^^^^^^^

On the ``main`` branch, create a new tag that contains the new
MAJOR.MINOR.PATCH version number prefixed with a "v":

.. code-block:: bash

    git checkout main
    git tag -a vMAJOR.MINOR.PATCH

As tag message enter:

.. code-block:: text

    HPCSS version MAJOR.MINOR.PATCH

    Release notes at https://github.com/andthum/hpc_submit_scripts/releases

Push the tag to the upstream repository.

.. important::

    First push, then push \--tags!

.. code-block:: bash

    git push
    git push --tags


3. Create a New Release
^^^^^^^^^^^^^^^^^^^^^^^

Open the upstream repository in GitHub and follow the steps outlined in
the GitHub doc page
`Creating automatically generated release notes for a new release
<https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes#creating-automatically-generated-release-notes-for-a-new-release>`_.
When selecting a tag, use the tag you just created in the previous step.
Carefully check the automatically generated release notes and make
changes if necessary.


.. _semantic versioning: https://semver.org/
