.. role:: bash(code)
    :language: bash


************
Contributing
************

Thank you for your willingness to contribute to this project!  Any help
is highly appreciated!

Although you certainly want to start right away, please take a while and
get familiar with the style guide this project follows.  Maintaining a
consistent code is much easier and thus more fun than maintaining a
mess.

.. contents:: Site Contents
    :depth: 2


Python Code
===========

Formatters and Linters
----------------------

Formatters and linters automatically enforce a specific code style and
quality.  They help you to focus on your actual task - the coding -
without having to think about the code style.

When writting Python code for this project, please

    * Format your code with Black_ (automatically enforces Python code
      style guide PEP8_).

      To format a file :bash:`spam.py` run
      :bash:`python3 -m black path/to/spam.py` in a terminal.  The
      settings to use are specified in :bash:`.pyproject.toml`, which is
      automatically read by Black.

    * Format import statements with isort_.

      To format a file :bash:`spam.py` run
      :bash:`python3 -m isort path/to/spam.py` in a terminal.  The
      settings to use are specified in :bash:`.pyproject.toml`, which is
      automatically read by isort.

    * Lint your code with Flake8_.

      To lint a file :bash:`spam.py` run
      :bash:`python3 -m flake8 path/to/spam.py` in a terminal.  The
      settings to use are specified in :bash:`.flake8`, which is
      automatically read by Flake8.

.. note::

    The listed formatters and linters offer plugins for many popular
    text editors.  When using these plugins, your code is formatted and
    lintted on the fly, so you don't have to run the commands yourself.

.. note::

    All python packages that are required for the development process
    are listed in :bash:`requirements_dev.txt`, so you can easily
    install them with pip_.  It is recommended to install the packages
    inside a `virtual Python environment`_ within the project directory:

    .. code-block:: bash

        python3 -m pip install --user --upgrade virtualenv
        python3 -m virtualenv env
        source env/bin/activate
        python3 -m pip install --upgrade pip setuptools wheel
        python3 -m pip install --upgrade requirements_dev.txt

    To leave the virtual environment when finishing work on the project
    type :bash:`deactivate`.


Other Python Coding Guidelines
------------------------------

    * Adhere to the Zen of Python (PEP20_).

    * Naming conventions (A comprehensive summary of the following
      naming conventions can be found
      `here <https://github.com/naming-convention/naming-convention-guides/tree/master/python>`_):

        - Use meaningful, descriptive, but not too long names.
        - Too specific names might mean too specific code.
        - Spend time thinking about readability.
        - Package names (i.e. ultimately directory names): ``lowercase``
          (avoid underscores)
        - Module names (i.e. ultimately filenames):
          ``lower_case_with_underscores``
        - Class names: ``CapitalizedWords``
        - Function names: ``lower_case_with_underscores``
        - Variable names: ``lower_case_with_underscores``
        - Constant variable names: ``UPPER_CASE_WITH_UNDERSCORES``
        - Underscores:

            + ``_``: For throwaway varibales, i.e. for variables that
              will never be used.  For instance if a function returns
              two values, but only one is of interest.
            + ``single_trailing_underscore_``: Used by convention to
              avoid conflicts with Python keywords, e.g.
              ``list_ = [0, 1]`` instead of ``list = [0, 1]``
            + ``_single_leading_underscore``: Weak "internal use"
              indicator, comparable to the "private" concept in other
              programming languages, though there is not really such a
              concept in Python.
            + ``__double_leading_underscore``: For name mangling.
            + ``__double_leading_and_trailing_underscore__``: "dunders"
              (double underscores).  "Magic" objects or attributes that
              live in user-controlled namespaces, like ``__init__``.
              Never invent such names, only use them as documented.


Bash Code
=========

Formatters and Linters
----------------------

When writting Bash code for this project, please

    * Format your code with shfmt_.

      To format a file :bash:`spam.sh` run
      :bash:`shfmt -ln bash -i 4 -ci -sr -w path/to/spam.sh` in a
      terminal.

      shfmt can e.g. be installed as a `snap package
      <https://snapcraft.io/shfmt>`_.

    * Lint your code with shellcheck_.

      To lint a file :bash:`spam.sh` run
      :bash:`shellcheck path/to/spam.sh` in a terminal.  The settings to
      use are specified in :bash:`.shellcheckrc`, which is automatically
      read by shellcheck.

      For many Linux distributions, shellcheck can be install from the
      official repositories.  Alternatively, you can install the Python
      package shellcheck-py_.

.. note::

    The listed formatters and linters offer plugins for many popular
    text editors.  When using these plugins, your code is formatted and
    lintted on the fly, so you don't have to run the commands yourself.


Markdown
========

Formatters and Linters
----------------------

When writting markdown language, please

    * Lint your code with markdownlint_.

      To lint a file :bash:`spam.md` run
      :bash:`mdl path/to/spam.md` in a terminal.  The settings to
      use are specified in :bash:`.mdlrc`, which is automatically
      read by markdownlint.

      markdownlint can e.g. be installed as a
      `snap package <https://snapcraft.io/mdl>`_ (unofficial) or as a
      `RubyGems package <https://rubygems.org/gems/mdl>`_.

.. important::

    You must install the ruby development package for your system in
    order to make the markdownlint pre-commit hook work (see
    "`Pre-Commit`_" below for more information about pre-commit hooks).

.. note::

    The listed formatters and linters offer plugins for many popular
    text editors.  When using these plugins, your code is formatted and
    lintted on the fly, so you don't have to run the commands yourself.


Documentation
=============

Comment and document your code!  Code without or with poor documentation
will probably never be used by someone else.  Ask yourself, would you
use code you don't know what it is good for or how to use it?  Probably
not.


Documentation Content
---------------------

If you are new to writing documentation and you are not sure what makes
a good documentation, you might want to read
`A beginner's guide to writing documentation
<https://www.writethedocs.org/guide/writing/beginners-guide-to-docs/>`_.
In short:

    * Use comments to explain *why* you have written the code the way
      you did (implementation details).

      Comments are intended to be read by other developers and by your
      future-you.  Think about what you would like to know if you run
      over your code in a year from now.

    * Use docstrings to explain *what* the code does and *how to use*
      it.

      Documentation is inteded to be read by users that don't
      necessarily know anything about programming.  Especially, they
      don't want to read the source code.  Think about what you would
      like to know when using the code from someone else.


Documentation Style
-------------------

    * This project is a mixed Python and Bash project.  The standard
      language for Python docstrings is reStructuredText_, which we also
      use for docstrings within Python files.  Because we might build an
      HTML documentation in the future with Sphinx_, please use
      reStructuredText in text-only files (like README's), too, instead
      of markdown.
    * Give every function, class or whatever object a docstring!
    * Follow the general style guide PEP257_.
    * For Python docstrings follow the special
      `NumPy docstring convention`_.
    * Limit line length to 72 characters.
    * Because text editors usually use a mono-spaced font, put two
      spaces after sentence-ending periods (except when no other
      sentence is following).


Convention for Section Levels in the Documentation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    * Parts: Over- and underlined with ``#``
    * Chapters: Over- and underlined with ``*``
    * Sections: Underlined with ``=``
    * Subsections: Underlined with ``-`` (also used as section marker in
      docstrings.  See the `NumPy docstring convention`_)
    * Subsubsections: Underlined with ``^``
    * Paragraphs: Underlined with ``"``
    * Subparagraphs: Underlined with ``'``


Order of Characters in Nested `Bullet Lists`_
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    * Top level: "*"

        - 2nd level: "-"

            + 3rd level: "+"

                * Afterwards start again with "*"


Git-Workflow
============

This project uses Git_ as version control system (VCS).  If you are new
to Git, you might want to read the first three (or more) chapters of the
`Git Book`_.

The `project repository`_ is hosted on GitHub_.  Newcomers to GitHub
should take a look at the `GitHub Quickstart Guide`_.

To keep things simple, we *follow the* `GitHub Flow`_ in our development
process.  In this workflow, the only hard rule that must always be
obeyed is that *anything in the* ``main`` *branch must be stable*.  This
means before you make any changes to the code (e.g. implement a new
feature, fix a bug, add a docstring/comment, etc.), create a new branch
out of ``main``.  Your branch name should be descriptive, so that others
can see what is being worked on (see "`2. Create a new Topic Branch`_",
below).  Only after your code was tested, has no known bugs and works
stable, it can be merged back into the ``main`` branch.

The following demonstrates an example workflow that can be used as
reference.

See also:

    * Git Book chapter `Contributing to a Project`_.
    * GitHub Docs `Contributing to projects`_.


0. Fork the Project
-------------------

If you want to contribute to this project, you should first create your
own copy of the project (a.k.a. fork_).  This step must be done only
once (as long as you don't delete your fork).  If you already have your
own fork of this project, go ahead to "`1. Get up to Date`_".

Go to the `project repository`_ on GitHub and press the Fork button in
the top-right corner (note that you need a GitHub account for
this).  Afterwards, clone your forked repository to your local computer:

.. code-block:: bash

    git clone https://github.com/<YOUR-USERNAME>/hpc_submit_scripts.git

You should `configure a remote`_ that points to the original (so-called
upstream) repository:

.. code-block:: bash

    cd hpc_submit_scripts
    git remote add upstream https://github.com/andthum/hpc_submit_scripts.git

In this way you can fetch the latest changes directly from the upstream
repository (see "`1. Get up to Date`_").


1. Get up to Date
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


2. Create a new Topic Branch
----------------------------

Create a new `topic branch`_ (usually out of the ``main`` branch).

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
      *not* name your branch ``feat/issue/15``.  Otherwise,
      tab-expansion might get confused with SHA1 commit hashes.


3. Work on Your Topic Branch
----------------------------

Add your changes to the project.

Don't forget to write unit tests for your code ;-)


4. Format and Lint Your Code
----------------------------

Check your code quality by using the above mentioned formatters and
linters.

.. note::

    Many editors offer to load the above code formatters and linters as
    plugins.  These plugins format and lint the code on the fly as you
    type or on each save.  When using the corresponding plugins, you can
    skip this step.


5. Run Tests
------------

No tests implemented, yet.  Skip this step (unless you have implemented
tests).


6. Stage and Commit Your Changes
--------------------------------

`Record your changes to the repository`_:

.. code-block:: bash

    git add changed/files
    git commit

Commit conventions:

    * Each commit should be a single logical change.  Don't make several
      logical changes in one commit.  Go back to
      "`3. Work on Your Topic Branch`_" as often as needed.
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
      has been changed or don't name the file at all.
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


7. Tidy up Your Topic Branch
----------------------------

If your topic branch does not fulfill the commit conventions above, tidy
up your commits by reordering_, squashing_ and/or splitting_.


8. Rebase Onto the Target Branch
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


9. Push Your Commits to Your Fork on GitHub
-------------------------------------------

Immediatly after rebasing, push your changes to your fork's remote
repository:

.. code-block:: bash

    git push origin topic/branch


10. Create a Pull Request
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
"`3. Work on Your Topic Branch`_" and incorporate the requested changes.


Pre-Commit
==========

We use pre-commit_ to run several tests on changed files (including the
above mentioned formatters and linters) automatically at every call of
:bash:`git commit`.  When you installed all packages listed in
:bash:`requirements_dev.txt` (see "`Python Code`" above), the only thing
you have to do to enable the pre-commit hooks is to install the
pre-commit script and the pre-commit git hooks once for this project via

.. code-block:: bash

    pre-commit install
    pre-commit install-hooks

You can check if pre-commit is working properly by running

.. code-block:: bash

    pre-commit run --all-files

.. note::

    You might have to install the ruby development package for your
    system in order to make the markdownlint pre-commit hook work.


Publish a new Release
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


1. Create a new Tag
-------------------

Create a new tag that contains the new MAJOR.MINOR.PATCH version number
prefixed with a "v":

.. code-block:: bash

    git checkout main
    git tag -m "Release Description" vMAJOR.MINOR.PATCH

As tag message use the change log of the new release.


2. Push the Tag to the Upstream Repository
------------------------------------------

.. important::

    First push, then push \--tags!

.. code-block:: bash

    git push
    git push --tags


.. _Black: https://github.com/psf/black
.. _PEP8: https://www.python.org/dev/peps/pep-0008/
.. _isort: https://pycqa.github.io/isort/
.. _Flake8: https://flake8.pycqa.org/en/latest/
.. _pip: https://pip.pypa.io/en/stable/
.. _virtual Python environment:
    https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/
.. _PEP20: https://www.python.org/dev/peps/pep-0020/

.. _shfmt: https://github.com/mvdan/sh#shfmt
.. _shellcheck: https://github.com/koalaman/shellcheck
.. _shellcheck-py: https://github.com/shellcheck-py/shellcheck-py

.. _markdownlint: https://github.com/markdownlint/markdownlint

.. _reStructuredText: https://docutils.sourceforge.io/rst.html
.. _Sphinx: https://www.sphinx-doc.org
.. _PEP257: https://peps.python.org/pep-0257/
.. _Numpy docstring convention: https://numpydoc.readthedocs.io/en/latest/format.html
.. _Bullet Lists: https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html#bullet-lists

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

.. _pre-commit: https://pre-commit.com/

.. _semantic versioning: http://semver.org/
