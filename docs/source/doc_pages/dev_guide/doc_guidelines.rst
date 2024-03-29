.. _doc-guide-label:

Documentation Guidelines
========================

Comment and document your code!  Code without or with poor documentation
will probably never be used by someone else.  Ask yourself, would you
use code you don't know what it is good for or how to use it?  Probably
not.

.. contents:: Site Contents
    :depth: 2
    :local:


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

      Documentation is intended to be read by users that don't
      necessarily know anything about programming.  Especially, they
      don't want to read the source code.  Think about what you would
      like to know when using the code from someone else.


Documentation Style
-------------------

    * The documentation of this project is built with |Sphinx| and
      hosted on |RTD|.  Hence, the language for *docstrings* in Python
      scripts and modules is |RST| (*comments* are not part of the
      documentation and are thus written in plain text).
    * Please write text-only files, like README's, in reStructuredText,
      too, instead of markdown.
    * Give every function, class or whatever object a docstring!
    * Follow the general style guide :pep:`257`.
    * For docstrings follow the special |NumPy_docstring_convention|.
    * Contrary to what is mentioned in the |NumPy_docstring_convention|,
      the "Examples" section serves also as code test via
      :mod:`doctest`, as long as we have not implemented extensive test
      suites using |pytest|.
    * Limit the line length of docstrings and comments to 72 characters.
    * Because text editors usually use a mono-spaced font, put two
      spaces after sentence-ending periods (except when no other
      sentence is following).
    * Python scripts get a complete docstring at the module level (that
      means before the import statements) such that the script's
      documentation can be auto-generated with `sphinx.ext.autodoc`_.
      The docstring convention for scripts is similar to the
      `docstring convention for functions`_.  However, some changes
      apply:

        - The "Parameters" section is replaced by an "Options" section.
        - In the "Options" section, use an |RST_option_list| to list the
          options with which the script can/must be called and their
          meaning.
        - The "Options" sections is followed by a "Config File" section
          stating which sections from a |config_file| are read by the
          script.
        - Note that you will have to repeat parts of your docstring
          (especially the summary and a potentially abbreviated version
          of the "Options" section) when implementing the command-line
          interface with :mod:`argparse`.


Convention for Section Levels in the Documentation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    * Parts: Over- and underlined with ``#``
    * Chapters: Over- and underlined with ``*``
    * Sections: Underlined with ``=``
    * Subsections: Underlined with ``-`` (also used as section marker in
      docstrings.  See the |NumPy_docstring_convention|)
    * Subsubsections: Underlined with ``^``
    * Paragraphs: Underlined with ``"``
    * Subparagraphs: Underlined with ``'``


Order of Characters in Nested `Bullet Lists`_
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    * Top level: ``*``

        - 2nd level: ``-``

            + 3rd level: ``+``

                * Afterwards start again with ``*``


.. _sphinx.ext.autodoc:
    https://www.sphinx-doc.org/en/master/usage/extensions/autodoc.html
.. _docstring convention for functions:
    https://numpydoc.readthedocs.io/en/latest/format.html#sections
.. _Bullet Lists:
    https://docutils.sourceforge.io/docs/ref/rst/restructuredtext.html#bullet-lists
