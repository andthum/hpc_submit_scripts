.. _code-guide-md-label:

Markdown Code Guidelines
========================

.. contents:: Site Contents
    :depth: 2
    :local:


Formatters and Linters
----------------------

When writting markdown language, please

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
    text editors.  When using these plugins, your code is formatted and
    lintted on the fly, so you don't have to run the commands yourself.

.. note::

    If you set up :ref:`pre-commit-label` (strongly recommended), the
    above formatters and linters check your code before every commit.
