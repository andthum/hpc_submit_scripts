************
Contributing
************

Thank you for your willingness to contribute to this project!  Any help
is highly appreciated!

Please adhere to the following rules when contributing to this project.

.. contents:: Contents
    :depth: 2


Documentation
=============

Comment and document your code!  Use comments to explain *why* you have
written the code the way you did.  In the documentation explain *what*
the code does and *how to use* it.

If you are new to writing documentation, you might want to read `A
beginner's guide to writing documentation
<https://www.writethedocs.org/guide/writing/beginners-guide-to-docs/>`_.

When writing documentation, please

    * Use reStructuredText_.
    * Limit line length to 72 characters.
    * Use 4 spaces for indents.
    * Because text editors usually use a mono-spaced font, put two
      spaces between the end of a sentence and the beginning of a new
      sentence.

Convention for section levels in the documentation:

    * Parts: Over- and underlined with ``#``
    * Chapters: Over- and underlined with ``*``
    * Sections: Underlined with ``=``
    * Subsections: Underlined with ``-``
    * Subsubsections: Underlined with ``^``
    * Paragraphs: Underlined with ``"``
    * Subparagraphs: Underlined with ``'``

Order of characters in nested `bullet lists`_: ``*``, ``-``, ``+``
(afterwards start again with ``*``).


Python
======

When writting Python code, please

    * Adhere to the Zen of Python (PEP20_).
    * Follow style guide PEP8_ for source code (you don't need to worry
      about PEP8_ if you format your code with black_, see below).
    * Follow the `NumPy docstring convention`_ for docstrings.
    * Format your code with black_ (automatically enforces PEP8_).
    * Use flake8_ and flake8-docstrings_ to check your code and
      documentation.


Bash
====

When writting Bash code, please

    * Limit line length of code to 79 characters.
    * Limit line length of comments and docstrings to 72 characters.
    * Format your code with shfmt_ and use 4 spaces for indents.
    * Use shellcheck_ to check your code.


Git-Workflow
============

This project uses Git_ as version control system (VCS).  If you are new
to Git, you might want to read the first three (or more) chapters of the
`Git Book`_.

The `project repository`_ is hosted on GitHub_.  Newcomers to GitHub
should take a look at the `GitHub Quickstart Guide`_.

To keep things simple, we **follow the** `GitHub Flow`_ in our
development process.  In this workflow, the only hard rule that must
always be obeyed is that **anything in the** ``main`` **branch must be
stable**.  This means before you make any changes to the code (e.g.
implement a new feature, fix a bug, add a docstring/comment, etc.),
create a new branch off of ``main``.  Your branch name should be
descriptive, so that others can see what is being worked on (see
"`2. Create a new topic branch`_", below).  Only after your code was
tested, has no known bugs and works stable, it can be merged back into
the ``main`` branch.

The following demonstrates an example workflow that can be used as
reference.

See also:

    * Git Book chapter `Contributing to a Project`_.
    * GitHub Docs `Contributing to projects`_.


0. Fork the project
-------------------

If you want to contribute to this project, you should first create your
own copy of the project (a.k.a. fork_).  This step must be done only
once (as long as you don't delete your fork).  If you already have your
own fork of this project, go ahead to "`1. Get up to date`_".

Go to the `project repository`_ on GitHub and press the Fork button in
the top-right corner (note that you need a GitHub account for
this).  Afterwards clone your forked repository to your local computer:

.. code-block:: bash

    git clone https://github.com/<YOUR-USERNAME>/hpc_submit_scripts.git

You should `configure a remote`_ that points to the original (so-called
upstream) repository:

.. code-block:: bash

    cd hpc_submit_scripts
    git remote add upstream https://github.com/andthum/hpc_submit_scripts.git

In this way you can fetch the latest changes directly from the upstream
repository (see "`1. Get up to date`_").


1. Get up to date
-----------------

`Get the latest changes`_ from the remote repository.

.. code-block:: bash

    git fetch upstream
    git checkout main
    git merge upstream/main

As long as you have not commited anything to the ``main`` branch of your
fork, Git will perform a so-called fast-forward merge (see the Git Book
chapter `Basic Branching and Merging`_).  If you want to keep your
fork's ``main`` branch in sync with the upstream ``main`` branch, you
should never commit anything directly to your fork's ``main`` branch,
but only fetch and merge the upstream ``main`` branch into your fork's
``main`` branch.


2. Create a new topic branch
----------------------------

Create a new `topic branch`_ (usually out off the ``main`` branch).

.. code-block:: bash

    git checkout main
    git checkout -b topic/branch

Topic branch naming conventions:

    * Use short and descriptive, lowercase names.
    * Do *not* name your topic branch simply ``main``, ``master``,
      ``develop``, ``devel``, ``dev``, ``stable``, ``stab``, ``wip``,
      ``release``, ``rel``, ``fix``, ``hotfix``, ``bug``, ``feature``,
      ``feat``, ``refactor``, ``ref``, ``documentation``, ``docs``,
      ``doc``, because these are commonly used names for special
      branches or branch groups.
    * Use slashes to sparate parts of your branch name.  However, be
      aware of the following limitation:  If a branch ``spam`` exists,
      no branch named ``spam/eggs`` can be created.  Likewise, if a
      branch ``spam/eggs`` exists, no branch named ``spam`` can be
      created (but ``spam/spam`` is possible).  The reason is that
      branches are implemented as paths.  You cannot create a directory
      ``spam`` if a file ``spam`` already exsits and the other way
      round.  This means, once you started branch naming without a
      sub-token, you cannot add a sub-token later.  This is the reason
      why you should never name your branches simply ``fix``, ``feat``,
      ``ref`` or ``doc``.
    * Use hyphens to separate words.
    * Use group tokens at the beginning of your branch names:

        - ``fix/<possible-sub-token>/<description>`` for bug fixes.
        - ``feat/<possible-sub-token>/<description>`` for new features.
        - ``ref/<possible-sub-token>/<description>`` for refactoring.
        - ``doc/<possible-sub-token>/<description>`` for
          documentation-only branches.

    * Use sub-tokens where applicable and meaningful.
    * If you adress a specific issue or feature request, reference this
      in your branch name, e.g. ``feat/issue/n15``, but
    * Do *not* use bare numbers as one part of your branch name, e.g. do
      *not* name your branch ``feat/issue/15``.


3. Work on your topic branch
----------------------------

Add your changes to the project.

Don't forget to write unit tests for your code.


4. Format and lint your code
----------------------------

Check your code quality by using code formatters and linters.

For Python code:

.. code-block:: bash

    python3 -m black changed/python/scripts.sh --line-length 79
    python3 -m flake8 changed/python/scripts.sh

For Bash code:

.. code-block:: bash

    shfmt -ln bash -i 4 -ci -d changed/bash/scripts.sh
    shellcheck changed/bash/scripts.sh

.. note::

    You must install the above tools on your local machine.  Refer to
    the documentation of black_, flake8_, shfmt_ and shellcheck_ for
    installation instructions.

.. note::

    Many editors offer to load the above code formatters and linters as
    plugins.  These plugins format and lint the code on the fly as you
    type or on each save.  When using the corresponding plugins, you can
    skip this step.


5. Run tests
------------

No tests implemented, yet.  Skip this step (unless you have implemented
tests).


6. Stage and commit your changes
--------------------------------

`Record your changes to the repository`_:

.. code-block:: bash

    git add changed/files
    git commit

Commit conventions:

    * Each commit should be a single logical change.  Don't make several
      logical changes in one commit.  Go back to
      "`3. Work on your topic branch`_" as often as needed.
    * On the other hand, don't split a single logical change into
      several commits.
    * Commit early and often.  Small, self-contained commits are easier
      to understand and revert when something goes wrong.
    * Commits should be ordered logically.  If commit X depends on
      changes done in commit Y, then commit Y should come before commit
      X.

Commit message conventions:

    * See Tim Pope's `note about Git commit messages`_.
    * The summary line (i.e. the first line of the message) should be
      descriptive yet succinct.  It should be no longer than 50
      characters.  It should be capitalized and written in imperative
      present tense.  It should not end with a period.
    * Start the summary line with "[Path]: Change", e.g.
      "[lmod/palma/README.rst]: Fix typo".  In this way other developers
      and maintainers immediatly know which file has been changed.  If
      you have a complex commit affecting several files, break it down
      into smaller commits (also see above).  If the path is too long to
      get the summary line within 50 characters, only name the file that
      has been changed.
    * After that should come a blank line followed by a more thorough
      description.  It should be wrapped to 72 characters and explain
      what changes were made and especially why they were made.  Think
      about what you would need to know if you run across the commit in
      a year from now.
    * If a commit A depends on commit B, the dependency should be stated
      in the message of commit A.  Use the SHA1 when referring to
      commits.
    * Similarly, if commit A solves a bug introduced by commit B, it
      should also be stated in the message of commit A.


7. Tidy up your topic branch
----------------------------

If your topic branch does not fulfill the commit conventions above, tidy
up your commits by reordering_, squashing_ and/or splitting_.


8. Rebase onto the target branch
--------------------------------

While you were working on your topic branch, the upstream repository
might have changed.  To avoid merge conflicts and to have an (almost)
linear history, pull the latest changes from the upstream repository and
rebase_ your topic branch onto the target branch (which is usually the
``main`` branch):

.. code-block:: bash

   # Get latest changes
   git fetch upstream
   git checkout main
   git merge upstream/main
   # Rebase the topic branch onto the target branch
   git checkout topic/branch
   git rebase main


9. Push your commits to your fork on GitHub
-------------------------------------------

Immediatly after rebasing, push your changes to your fork's remote
repository:

.. code-block:: bash

    git push origin topic/branch


10. Create a pull request
-------------------------

In order to get your changes merged in the upstream repository, you have
to `open a pull request from your fork`_.

Go to the repository of your fork on GitHub.  GitHub should notice that
you pushed a new topic branch and provide you with a button in the
top-right corner to open a pull request to the upstream repository.
Click that button and fill out the provided pull request template.  Give
the pull request a meaningful title and description that explains what
changes you have done and why you have done them.

Either your pull request is merged directly into the upstream
repository, your pull request is rejected or you are asked to make some
changes.  In the latter case, please go back to
"`3. Work on your topic branch`_" and incorporate the requested changes.


Publish a new release
=====================

New versions can only be released by project maintainers that have write
access to the upstream repository.

This project uses `semantic versioning`_.  Given a version number
MAJOR.MINOR.PATCH, we increment the

    1. **MAJOR** version when we make **incompatible API changes**,
    2. **MINOR** version when we **add functionality** in a
       **backwards-compatible** manner, and
    3. **PATCH** version when we make backwards-compatible
       **bug fixes**.

Additionally, pre-release, post-release and developmental release
specifiers can be appended.


1. Create a new tag
-------------------

.. code-block:: bash

    git checkout main
    git tag -m "Release Description" vMAJOR.MINOR.PATCH


2. Push the tag to the upstream repository
------------------------------------------

.. important::

    First push, then push \--tags!

.. code-block:: bash

    git push
    git push --tags


.. _reStructuredText: https://docutils.sourceforge.io/rst.html
.. _bullet lists: https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html#bullet-lists
.. _PEP20: https://www.python.org/dev/peps/pep-0020/
.. _PEP8: https://www.python.org/dev/peps/pep-0008/
.. _Numpy docstring convention: https://numpydoc.readthedocs.io/en/latest/format.html
.. _black: https://github.com/psf/black
.. _flake8: https://flake8.pycqa.org/en/latest/
.. _flake8-docstrings: https://pypi.org/project/flake8-docstrings/
.. _shfmt: https://github.com/mvdan/sh#shfmt
.. _shellcheck: https://github.com/koalaman/shellcheck
.. _Git: https://git-scm.com/
.. _Git Book: https://git-scm.com/book/
.. _project repository: https://github.com/andthum/hpc_submit_scripts
.. _GitHub: https://github.com/
.. _GitHub Quickstart Guide: https://docs.github.com/en/get-started/quickstart
.. _GitHub Flow: https://docs.github.com/en/get-started/quickstart/github-flow
.. _Contributing to a Project: https://git-scm.com/book/en/v2/GitHub-Contributing-to-a-Project
.. _Contributing to projects: https://docs.github.com/en/get-started/quickstart/contributing-to-projects
.. _fork: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-forks
.. _configure a remote: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/configuring-a-remote-for-a-fork
.. _Get the latest changes: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork
.. _Basic Branching and Merging: https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging
.. _topic branch: https://git-scm.com/book/en/v2/Git-Branching-Branching-Workflows#_topic_branch
.. _Record your changes to the repository: https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository
.. _note about Git commit messages: https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
.. _reordering: https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History#_reordering_commits
.. _squashing: https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History#_squashing
.. _splitting: https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History#_splitting_a_commit
.. _rebase: https://git-scm.com/book/en/v2/Git-Branching-Rebasing
.. _open a pull request from your fork: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request-from-a-fork
.. _semantic versioning: http://semver.org/
