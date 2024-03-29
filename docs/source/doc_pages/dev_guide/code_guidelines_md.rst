.. _code-guide-md-label:

Markdown Code Guidelines
========================

.. contents:: Site Contents
    :depth: 2
    :local:


Formatters and Linters
----------------------

When writing Markdown Language, please

    * Lint your code with |markdownlint|.

      To lint a file :bash:`spam.md` run
      :bash:`mdl path/to/spam.md` in a terminal.  The settings to
      use are specified in :bash:`.mdlrc`, which is automatically
      read by markdownlint.

      markdownlint can e.g. be installed as a
      `snap package <https://snapcraft.io/mdl>`_ (unofficial) or as a
      `RubyGems package <https://rubygems.org/gems/mdl>`_.

.. note::

    The listed formatters and linters offer plugins for many popular
    text editors and integrated development environments (IDEs).  When
    using these plugins, your code is formatted and linted on the fly,
    so you don't have to run the commands yourself.

.. note::

    If you have :ref:`set up pre-commit <set-up-pre-commit-label>`, the
    above formatters and linters check your code before every commit.
