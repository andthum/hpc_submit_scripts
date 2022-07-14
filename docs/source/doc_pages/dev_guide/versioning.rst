.. _versioning-label:

Versioning
==========

.. note::

    New versions can only be released by project maintainers that have
    write access to the upstream repository.

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

Follow these steps when publishing a new release.


1. Update the Change Log
^^^^^^^^^^^^^^^^^^^^^^^^

.. todo::

    Establish a change log.  See https://keepachangelog.com/ for some
    useful guidelines.


2. Create a New Tag
^^^^^^^^^^^^^^^^^^^

Create a new tag that contains the new MAJOR.MINOR.PATCH version number
prefixed with a "v":

.. code-block:: bash

    git checkout main
    git tag -m "Release Description" vMAJOR.MINOR.PATCH

As tag message use the change log of the new release.


3. Push the Tag to the Upstream Repository
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. important::

    First push, then push \--tags!

.. code-block:: bash

    git push
    git push --tags


.. _semantic versioning: http://semver.org/
