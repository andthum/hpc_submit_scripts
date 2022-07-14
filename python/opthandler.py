# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst


"""
Python functions to parse and handle command-line and config-file
options.
"""


# Standard libraries
import configparser
import copy
import os
import re
import shlex
import sys


if sys.version_info.major < 3 or sys.version_info.minor < 8:
    # shlex.join was introduced in version 3.8
    raise SystemError(
        "The minimum required Python version is 3.8 but you have"
        " {}".format(sys.version)
    )


def configparser2dict(
    config, sections=None, create_missing_secs=False, convert=False, **kwargs
):
    """
    Create a dictionary from a :class:`~configparser.ConfigParser`.

    Parameters
    ----------
    config : configparser.ConfigParser
        The :class:`~configparser.ConfigParser` instance from which to
        create the dictionary.
    sections : iterable or str or None, optional
        The sections of `config` to use for creating the dictionary.  If
        ``None``, use all sections.
    create_missing_secs : bool, optional
        If ``True``, don't raise an exception if a given section is not
        contained in `config` but instead create a key for this section
        that holds as value an empty sub-dictionary.
    convert : bool, optional
        If ``True``, apply :func:`convert_str` to the **values** of the
        returned dictionary.  This will convert strings to their
        corresponding Python data types.
    kwargs : dict, optional
        Keyword arguments to parse to :func:`convert_str`.

    Returns
    -------
    options : dict of dict
        A dictionary containing the entries of the input
        :class:`~configparser.ConfigParser` as a dictionary of
        dictionaries.  Every section name becomes a key that holds as
        value a sub-dictionary with the options as keys and the option
        values as values.

    Examples
    --------
    .. testsetup::

        from opthandler import configparser2dict

    >>> import configparser
    >>> config = configparser.ConfigParser()
    >>> config['Monty'] = {'spam': 'no!', 'eggs': '2'}
    >>> config['Python'] = {'foo': 'fighter', 'bar': 'baz'}
    >>> configparser2dict(config)
    {'Monty': {'spam': 'no!', 'eggs': '2'}, \
'Python': {'foo': 'fighter', 'bar': 'baz'}}
    """
    if sections is None:
        sections = config.sections()
    elif isinstance(sections, str):
        sections = (sections,)
    options = {}
    for sec in sections:
        if not config.has_section(sec) and create_missing_secs:
            options[sec] = {}
            continue
        if convert:
            options[sec] = {
                k: convert_str(v, **kwargs) for k, v in config.items(sec)
            }
        else:
            options[sec] = dict(config[sec])
    return options


def configparser_check_options(
    config,
    known_options,
    sections=None,
    skip_missing_sec=False,
    case_sensitive=True,
    hyphens_are_underscores=False,
):
    """
    Check if the options of a :class:`~configparser.ConfigParser` are
    contained in a list of known options.

    Parameters
    ----------
    config : configparser.ConfigParser
        The :class:`~configparser.ConfigParser` instance whose options
        should be checked.
    known_options : iterable
        The list of known options.  Note that the options of all given
        `sections` are checked against this list of known options.
    sections : iterable or str or None, optional
        The sections of `config` whose options should be checked.  If
        ``None``, check all sections.
    skip_missing_sec : bool, optional
        If ``True``, don't raise an exception if a given section is not
        contained in `config` but instead simply skip this section.
    case_sensitive : bool, optional
        If ``True``, respect the case (upper, lower, mixed) when
        comparing the options in `config` with the options in
        `known_options`.
    hyphens_are_underscores : bool, optional
        If ``True``, don't distinguish between hyphens (``'-'``) and
        underscores (``'_'``).

    Raises
    ------
    KeyError
        If any section of `config` contains options that are not
        contained in `known_options`.
    """
    if not case_sensitive:
        known_options = (opt.lower() for opt in known_options)
    if hyphens_are_underscores:
        known_options = (opt.replace("-", "_") for opt in known_options)
    # `known_options` must not be a generator, because it might be
    # iterated multiple times.
    known_options = set(known_options)
    if sections is None:
        sections = config.sections()
    elif isinstance(sections, str):
        sections = (sections,)
    for sec in sections:
        if not config.has_section(sec) and skip_missing_sec:
            continue
        if not case_sensitive:
            options = (opt.lower() for opt in config.options(sec))
        if hyphens_are_underscores:
            options = (opt.replace("-", "_") for opt in config.options(sec))
        else:
            options = config.options(sec)
        if not set(options).issubset(known_options):
            raise KeyError(
                "The section '{}' contains unknown options:"
                " {}".format(sec, set(options).difference(known_options))
            )


def conv_argparse_opts(args, converter):
    """
    Convert the option names in an :class:`argparse.Namespace`.

    Parameters
    ----------
    args: argparse.Namespace
        The :class:`~argparse.Namespace` whose option names should be
        converted.
    converter : callable
        A callable that defines the conversion.  Must take a single
        string as argument.

    Returns
    -------
    args_converted : argparse.Namespace
        The input :class:`~argparse.Namespace` with converted option
        names.

    See Also
    --------
    :func:`conv_configparser_opts` :
        Convert the option names of a
        :class:`~configparser.ConfigParser`

    Examples
    --------
    .. testsetup::

        from opthandler import conv_argparse_opts

    >>> import argparse
    >>> parser = argparse.ArgumentParser()
    >>> action = parser.add_argument('--spam', type=int)
    >>> action = parser.add_argument('--EGGS', type=int)
    >>> action = parser.add_argument('--FOO-bar', type=str)
    >>> args = parser.parse_args(
    ...     ['--spam', '0', '--EGGS', '2', '--FOO-bar', 'baz']
    ... )
    >>> sorted(vars(args).items())
    [('EGGS', 2), ('FOO_bar', 'baz'), ('spam', 0)]
    >>> args = conv_argparse_opts(args, str.lower)
    >>> sorted(vars(args).items())
    [('eggs', 2), ('foo_bar', 'baz'), ('spam', 0)]
    """
    # `args` cannot be changed in-place, otherwise you get
    # "RuntimeError: dictionary keys changed during iteration"
    args_converted = copy.deepcopy(args)
    for key, val in vars(args).items():
        delattr(args_converted, key)
        setattr(args_converted, converter(key), val)
    return args_converted


def conv_configparser_opts(
    config, converter, sections=None, skip_missing_sec=False
):
    """
    Convert the option names of a :class:`~configparser.ConfigParser`.

    Parameters
    ----------
    config: configparser.ConfigParser
        The :class:`~configparser.ConfigParser` whose option names
        should be converted.
    converter : callable
        A callable that defines the conversion.  Must take a single
        string as argument.
    sections : iterable or str or None, optional
        The sections of `config` whose option names should be converted.
        If ``None``, convert the option names in all sections.
    skip_missing_sec : bool, optional
        If ``True``, don't raise an exception if a given section is not
        contained in `config` but instead simply skip this section.

    Returns
    -------
    config_converted : configparser.ConfigParser
        The input :class:`~configparser.ConfigParser` with converted
        option names.

    See Also
    --------
    :func:`conv_configparser_vals` :
        Convert the values of a :class:`~configparser.ConfigParser`
    :func:`conv_argparse_opts` :
        Convert the option names in an :class:`argparse.Namespace`

    Examples
    --------
    .. testsetup::

        from opthandler import conv_configparser_opts

    >>> import configparser
    >>> config = configparser.ConfigParser()
    >>> config["Monty"] = {'spam': 'no!', 'eggs': '2'}
    >>> config["Python"] = {'foo': 'fighter', 'bar': 'baz'}
    >>> for sec in config.sections():
    ...     print(sec)
    ...     for opt, val in config.items(sec):
    ...         print(opt, val)
    Monty
    spam no!
    eggs 2
    Python
    foo fighter
    bar baz
    >>> config = conv_configparser_opts(config, converter=str.upper)
    >>> for sec in config.sections():
    ...     print(sec)
    ...     for opt, val in config.items(sec):
    ...         print(opt, val)
    Monty
    SPAM no!
    EGGS 2
    Python
    FOO fighter
    BAR baz
    """
    config_converted = copy.deepcopy(config)
    config_converted.optionxform = str
    if sections is None:
        sections = config.sections()
    elif isinstance(sections, str):
        sections = (sections,)
    for sec in sections:
        if not config.has_section(sec) and skip_missing_sec:
            continue
        for opt, val in config.items(sec):
            config_converted.remove_option(sec, opt)
            config_converted.set(sec, converter(opt), val)
    return config_converted


def conv_configparser_vals(
    config, converter, sections=None, skip_missing_sec=False
):
    """
    Convert the values of a :class:`~configparser.ConfigParser`.

    Parameters
    ----------
    config: configparser.ConfigParser
        The :class:`~configparser.ConfigParser` whose values should be
        converted.
    converter : callable
        A callable that defines the conversion.  Must take a single
        string as argument.
    sections : iterable or str or None, optional
        The sections of `config` whose option names should be converted.
        If ``None``, convert the option names in all sections.
    skip_missing_sec : bool, optional
        If ``True``, don't raise an exception if a given section is not
        contained in `config` but instead simply skip this section.

    Returns
    -------
    config_converted : configparser.ConfigParser
        The input :class:`~configparser.ConfigParser` with converted
        option names.

    See Also
    --------
    :func:`conv_configparser_opts` :
        Convert the option names of a
        :class:`~configparser.ConfigParser`

    Examples
    --------
    .. testsetup::

        from opthandler import conv_configparser_vals

    >>> import configparser
    >>> config = configparser.ConfigParser()
    >>> config["Monty"] = {'spam': 'no!', 'eggs': '2'}
    >>> config["Python"] = {'foo': 'fighter', 'bar': 'baz'}
    >>> for sec in config.sections():
    ...     print(sec)
    ...     for opt, val in config.items(sec):
    ...         print(opt, val)
    Monty
    spam no!
    eggs 2
    Python
    foo fighter
    bar baz
    >>> config = conv_configparser_vals(config, converter=str.upper)
    >>> for sec in config.sections():
    ...     print(sec)
    ...     for opt, val in config.items(sec):
    ...         print(opt, val)
    Monty
    spam NO!
    eggs 2
    Python
    foo FIGHTER
    bar BAZ
    """
    config_converted = copy.deepcopy(config)
    if sections is None:
        sections = config.sections()
    elif isinstance(sections, str):
        sections = (sections,)
    for sec in sections:
        if not config.has_section(sec) and skip_missing_sec:
            continue
        for opt, val in config.items(sec):
            config_converted[sec][opt] = converter(val)
    return config_converted


def convert_str(
    s,
    strip=True,
    case_sensitive=False,
    empty_none=False,
    extended_bool=False,
    bool_01=False,
):
    """
    Convert the input to its corresponding type.

    Convert the input to NoneType, boolean, integer or float depending
    on its content.  If a conversion in the aforementioned types is not
    possible, the input is returned as is.

    Parameters
    ----------
    s : str_like
        The input.  Can be anything that can be converted to a string.
    strip : bool, optional
        Whether to strip leading and trailing spaces before processing
        the input string.
    case_sensitive : bool, optional
        Whether to be case sensitive.  If ``True``, only upper case
        strings are convertet to their corresponding types.
    empty_none : bool, optional
        If ``True``, convert the empty string ``''`` to the NoneType
        ``None``.
    extended_bool : bool, optional
        If ``True``, also convert ``'Yes'``/``'No'`` and
        ``'On'``/``'Off'`` to ``True``/``False``.
    bool_01 : bool, optional
        If ``True``, also convert ``0``/``1`` to ``True``/``False``.

    Returns
    -------
    result : None or bool or int or float or str
        The converted string or the input as is.

    See Also
    --------
    :func:`str2none` :
        Convert the string ``'None'`` to the NoneType ``None``

    Examples
    --------
    .. testsetup::

        from opthandler import convert_str

    Conversion to NoneType ``None``:

    >>> convert_str('None')  # Returns None
    >>> convert_str('none')  # Returns None
    >>> convert_str('none', case_sensitive=True)
    'none'
    >>> convert_str('')
    ''
    >>> convert_str('', empty_none=True)  # Returns None

    Conversion to boolean ``True``:

    >>> convert_str('True')
    True
    >>> convert_str('true')
    True
    >>> convert_str('true', case_sensitive=True)
    'true'
    >>> convert_str('Yes')
    'Yes'
    >>> convert_str('Yes', extended_bool=True)
    True
    >>> convert_str('yes', extended_bool=True)
    True
    >>> convert_str('yes', extended_bool=True, case_sensitive=True)
    'yes'
    >>> convert_str('On')
    'On'
    >>> convert_str('On', extended_bool=True)
    True
    >>> convert_str('on', extended_bool=True)
    True
    >>> convert_str('on', extended_bool=True, case_sensitive=True)
    'on'
    >>> convert_str('1')
    1
    >>> convert_str('1', bool_01=True)
    True

    Conversion to boolean ``False``:

    >>> convert_str('False')
    False
    >>> convert_str('false')
    False
    >>> convert_str('false', case_sensitive=True)
    'false'
    >>> convert_str('No')
    'No'
    >>> convert_str('No', extended_bool=True)
    False
    >>> convert_str('no', extended_bool=True)
    False
    >>> convert_str('no', extended_bool=True, case_sensitive=True)
    'no'
    >>> convert_str('Off')
    'Off'
    >>> convert_str('Off', extended_bool=True)
    False
    >>> convert_str('off', extended_bool=True)
    False
    >>> convert_str('off', extended_bool=True, case_sensitive=True)
    'off'
    >>> convert_str('0')
    0
    >>> convert_str('0', bool_01=True)
    False

    Conversion to integer:

    >>> convert_str('123')
    123
    >>> convert_str(' 123 ')  # Regardless if strip is True or False
    123
    >>> convert_str('a123')
    'a123'

    Conversion to float:

    >>> convert_str('123.456')
    123.456
    >>> convert_str(' 123.456 ')  # Regardless if strip is True or False
    123.456
    >>> convert_str('a123.456')
    'a123.456'

    No conversion (input returned as is):

    >>> # strip has no effect if no conversion takes place.
    >>> convert_str(' a string ', strip=False)
    ' a string '
    >>> convert_str(' a string ', strip=True)
    ' a string '
    >>> # case_sensitive has no effect if no conversion takes place.
    >>> convert_str('A sTrInG', case_sensitive=False)
    'A sTrInG'
    >>> convert_str('A sTrInG', case_sensitive=True)
    'A sTrInG'
    """
    input_str = str(s)
    if strip:
        input_str = input_str.strip()
    eval_none = ["None"]
    eval_true = ["True"]
    eval_false = ["False"]
    if empty_none:
        eval_none += [""]
    if extended_bool:
        eval_true += ["Yes", "On"]
        eval_false += ["No", "Off"]
    if bool_01:
        eval_true += ["1"]
        eval_false += ["0"]
    if not case_sensitive:
        input_str = input_str.lower()
        eval_none = [item.lower() for item in eval_none]
        eval_true = [item.lower() for item in eval_true]
        eval_false = [item.lower() for item in eval_false]
    if input_str in eval_none:
        return None
    elif input_str in eval_true:
        return True
    elif input_str in eval_false:
        return False
    else:
        try:
            return int(input_str)
        except ValueError:
            try:
                return float(input_str)
            except ValueError:
                return s


def get_opts(
    argparser,
    conf_file="hpcssrc.ini",
    secs_known=None,
    secs_unknown="sbatch",
    create_missing_secs=True,
    ignore_unknown_opts=True,
    convert=True,
    **kwargs,
):
    """
    Gather all options from command line and |config_file|.

    Gather all options given via the command-line interface and via a
    config file, merge them and return them in one dictionary.

    Options explicitly given via the command-line interface take
    precedence over options specified in the config file.  Options
    specified in the config file take precedence over default values of
    the command-line interface.

    Parameters
    ----------
    argparser : argparse.ArgumentParser
        The :class:`~argparse.ArgumentParser` instance that implements
        the command-line interface.  Note: All possible command-line
        arguments must be contained in the :class:`~argparse.Namespace`,
        i.e. not-given arguments must not be suppressed with
        :attr:`argparse.SUPPRESS`.
    conf_file : str, optional
        The name of the |config_file|.
    secs_known : list or tuple or str or None, optional
        Sections of the config file that contain options that can also
        be specified via the command-line interface ("known" to
        `argparser`).  If ``None``, use all sections.  The options of
        all known sections will be merged into one sub-dictionary.
        Options that are given in multiple sections take precedence over
        each other in reverse order as they appear in `secs_known`.
        This means, options in the last given section have the highest
        preference and options in the first given section have the
        lowest preference.
    secs_unknown : list or tuple or str or None, optional
        Sections of the config file that contain options that cannot be
        specified via the command-line interface ("unknown" to
        `argparser`), but that should still be parsed to the calling
        script.  If you don't have such sections, set `secs_unknown` to
        ``None``.  The options of all unknown sections will be merged
        into one sub-dictionary.  Options that are given in multiple
        sections take precedence over each other in reverse order as
        they appear in `secs_unknown` (see `secs_known`).
    create_missing_secs : bool, optional
        If ``True``, don't raise an exception if a given section is not
        contained in the config file but instead create the section (and
        leave it empty).
    ignore_unknown_opts : bool, optional
        If ``True``, don't raise an exception if any option in the given
        known sections (`secs_known`) is unknown to `argparser`, but
        instead simply ignore it.
    convert : bool, optional
        If ``True``, apply :func:`convert_str` to the values of all
        config-file options and all unknown options.  This will convert
        strings to their corresponding Python data types.  If ``False``,
        all config-file options and all unknown options will be parsed
        as strings.
    kwargs : dict, optional
        Keyword arguments to parse to :func:`convert_str`.

    Returns
    -------
    options : dict of dict
        A dictionary of two dictionaries.  The first key (given by the
        first known section in `sections`) contains as value a
        sub-dictionary of all known options and their respective values.
        The second key (given by `sec_unknown`) contains as value a
        dictionary of all unknown options and their respective values.

    See Also
    --------
    :meth:`argparse.ArgumentParser.parse_known_args` :
        Get known and unknown options from the command-line interface

    Notes
    -----
    Known options
        Options that can also be parsed via the command-line interface
        (i.e. options that are known to the input
        :class:`~argparse.ArgumentParser`).
    Unknown options
        Options that are not contained in the
        :class:`~argparse.Namespace` of the input
        :class:`~argparse.ArgumentParser` (i.e. options that are unknown
        to the input :class:`~argparse.ArgumentParser`).
    """
    config = read_config(conf_file)

    if secs_known is None:
        secs_known = config.sections()
    elif isinstance(secs_known, str):
        secs_known = (secs_known,)
    else:
        secs_known = tuple(secs_known)
    if len(secs_known) != len(set(secs_known)):
        raise ValueError("'secs_known' contains duplicate sections")

    if isinstance(secs_unknown, str):
        secs_unknown = (secs_unknown,)
    elif secs_unknown is not None:
        secs_unknown = tuple(secs_unknown)
    if secs_unknown is not None:
        if len(secs_unknown) != len(set(secs_unknown)):
            raise ValueError("'secs_unknown' contains duplicate sections")
        if not set(secs_known).isdisjoint(secs_unknown):
            raise ValueError(
                "'secs_known' and 'secs_unknown' share same sections:"
                " {}".format(set(secs_known).intersection(secs_unknown))
            )

    # Convert hyphens in known config-file option names to underscores
    # to be consistent with argparse option names.
    config = conv_configparser_opts(
        config,
        converter=lambda s: str.replace(s, "-", "_"),
        sections=secs_known,
        skip_missing_sec=create_missing_secs,
    )

    # Convert configparser.ConfigParser to dictionary.
    options = configparser2dict(
        config=config,
        sections=secs_known + secs_unknown,
        create_missing_secs=create_missing_secs,
        convert=convert,
        **kwargs,
    )

    # Overwrite top-level config-file options with lower-level options.
    sec_known = secs_known[0]
    for sec in secs_known[:0:-1]:
        options[sec_known].update(options[sec])
        options.pop(sec)
    if secs_unknown is not None:
        sec_unknown = secs_unknown[0]
        for sec in secs_unknown[:0:-1]:
            options[sec_unknown].update(options[sec])
            options.pop(sec)

    # Overwrite default (known) command-line options with (known)
    # config-file options.
    # NOTE: `argparser.set_defaults` does not check the parsed options
    # for validity.  It even does not check whether the parsed options
    # are allowed (known) or not (unknown).
    argparser.set_defaults(**options[sec_known])

    # Get all command-line options and convert them to dictionaries.
    args_known, args_unknown = argparser.parse_known_args()
    args_known = vars(args_known)
    args_unknown = optlist2dict(args_unknown, convert=convert, **kwargs)

    # Parse `args_known` again to check the options for validity,
    # because `argparser.set_defaults` does not check for validity.
    args = {
        k.replace("_", "-"): v
        for k, v in args_known.items()
        if v not in (None, True, False, "")
    }
    if ignore_unknown_opts:
        # Ignore unknown options in `options[sec_known]` that were
        # parsed to `argparser.set_defaults`.  Note however, that
        # `args_known` still contains these unknown options.
        argparser.parse_known_args(optdict2list(args))
    else:
        # Raise exception if `options[sec_known]` contains unknown
        # options that were parsed to `argparser.set_defaults`.
        argparser.parse_args(optdict2list(args))

    # Overwrite known config-file options with known command-line
    # options.
    options[sec_known] = args_known
    # Overwrite unknown config-file options with unknown command-line
    # options.
    if secs_unknown is not None:
        options[sec_unknown].update(args_unknown)
    else:
        options["unknown"] = args_unknown
    return options


def optdict2list(
    optdict,
    convert_to_str=True,
    convert_from_str=False,
    skiped_opts=None,
    dumped_vals=None,
    **kwargs,
):
    """
    Convert an option dictionary to an option list.

    Parameters
    ----------
    optdict : dict
        The option dictionary that should be converted to an option
        list.
    convert_to_str: bool, optional
        If ``True``, convert the **values** of the input dictionary to
        strings.
    convert_from_str : bool, optional
        If ``True``, apply :func:`convert_str` on the **values** of the
        input dictionary.  This will convert strings to their
        corresponding Python data types.  Must not be used together with
        `convert_to_str`.
    skiped_opts : list or tuple or None, optional
        If not ``None``, skip key-value pairs of the input dictionary
        whose value is contained in `skiped_opts`.
    dumped_vals : list or tuple or None, optional
        If not ``None``, don't include the given values of the input
        dictionary in the returned option list.
    kwargs : dict, optional
        Keyword arguments to parse to :func:`convert_str`.

    Returns
    -------
    optlist : list
        The resulting option list.  Each key of `optdict` is prefixed
        with either a single hyphen (``'-'``) or two hyphens, depending
        on whether the key consists of a single character or multiple
        characters.

    See Also
    --------
    :func:`optdict2str` :
        Convert an option dictionary to an option string
    :func:`optlist2dict` :
        Convert an option list to an option dictionary

    Notes
    -----
    If `convert_to_str` or `convert_from_str` is ``True``, `skiped_opts`
    and `dumped_vals` will be compared to the converted values.

    Examples
    --------
    .. testsetup::

        from opthandler import optdict2list

    >>> optdict2list({'a': 0, 'Bc': 'xY'})
    ['-a', '0', '--Bc', 'xY']
    >>> optdict2list({' a': 0, ' Bc ': 'xY '})
    ['-a', '0', '--Bc', 'xY']
    >>> optdict2list({' a': 0, ' Bc ': 'xY '}, convert_to_str=False)
    ['-a', 0, '--Bc', 'xY ']
    >>> optdict2list({'a': 0, 'Bc': 'xY Ab'})
    ['-a', '0', '--Bc', 'xY Ab']
    >>> optdict2list({'a': 0, 'Bc': '', 'xy': 'z'})
    ['-a', '0', '--Bc', '--xy', 'z']
    >>> optdict2list(
    ...     {'a': 0, 'Bc': None, 'xy': False},
    ...     skiped_opts=('None', 'False'),
    ... )
    ['-a', '0']
    >>> optdict2list(
    ...     {'a': 0, 'Bc': None, 'xy': False},
    ...     skiped_opts=(None, False),
    ... )
    ['-a', '0', '--Bc', 'None', '--xy', 'False']
    >>> # 0 is False, 1 is True
    >>> optdict2list(
    ...     {'a': 0, 'Bc': None, 'xy': False},
    ...     skiped_opts=(None, False),
    ...     convert_to_str=False,
    ... )
    []
    >>> optdict2list(
    ...     {'a': 0, 'Bc': None, 'xy': False},
    ...     skiped_opts=('None', 'False'),
    ...     convert_to_str=False,
    ... )
    ['-a', 0, '--Bc', None, '--xy', False]
    >>> optdict2list(
    ...     {'a': 0, 'Bc': None, 'xy': True},
    ...     dumped_vals=('None', 'True'),
    ... )
    ['-a', '0', '--Bc', '--xy']
    """
    if convert_to_str and convert_from_str:
        raise ValueError(
            "'convert_from_str' must not be used together with"
            " 'convert_to_str'"
        )
    optlist = []
    for opt, val in optdict.items():
        opt = str(opt).strip()
        if convert_from_str:
            val = convert_str(val, **kwargs)
        elif convert_to_str:
            val = str(val).strip()
        if skiped_opts is not None and val in skiped_opts:
            continue
        if dumped_vals is not None and val in dumped_vals:
            val = ""
        if len(opt) == 1:
            optlist.append("-" + opt)
        elif len(opt) > 1:
            optlist.append("--" + opt)
        # else: len(opt) == 0 => `val` is position argument.
        if isinstance(val, str) and len(val) == 0:
            continue
        optlist.append(val)
    return optlist


def optdict2str(optdict, skiped_opts=None, dumped_vals=None):
    """
    Convert an option dictionary to an option string.

    Parameters
    ----------
    optdict : dict
        The option dictionary that should be converted to an option
        list.
    skiped_opts : list or tuple or None, optional
        If not ``None``, skip key-value pairs of the input dictionary
        whose value is contained in `skiped_opts`.
    dumped_vals : list or tuple or None, optional
        If not ``None``, don't include the given values of the input
        dictionary in the returned option list.

    Returns
    -------
    optstr : str
        The resulting option string.  Each key of `optdict` is prefixed
        with either a single hyphen (``'-'``) or two hyphens, depending
        on whether the key consists of a single character or multiple
        characters.

    See Also
    --------
    :func:`optdict2list` :
        Convert an option dictionary to an option list
    :func:`shlex.join` :
        Convert an option list to an option string

    Notes
    -----
    This function simply applies :func:`shlex.join` on the output of
    :func:`optdict2list`.

    Examples
    --------
    .. testsetup::

        from opthandler import optdict2str

    >>> optdict2str({'a': 0, 'Bc': 'xY'})
    '-a 0 --Bc xY'
    >>> optdict2str({' a': 0, ' Bc ': 'xY '})
    '-a 0 --Bc xY'
    >>> optdict2str({'a': 0, 'Bc': 'xY Ab'})
    "-a 0 --Bc 'xY Ab'"
    >>> optdict2str({'a': 0, 'Bc': '', 'xy': 'z'})
    '-a 0 --Bc --xy z'
    >>> optdict2str(
    ...     {'a': 0, 'Bc': None, 'xy': False},
    ...     skiped_opts=('None', 'False'),
    ... )
    '-a 0'
    >>> optdict2str(
    ...     {'a': 0, 'Bc': None, 'xy': False},
    ...     skiped_opts=(None, False),
    ... )
    '-a 0 --Bc None --xy False'
    >>> optdict2str(
    ...     {'a': 0, 'Bc': None, 'xy': True},
    ...     dumped_vals=('None', 'True'),
    ... )
    '-a 0 --Bc --xy'
    """
    return shlex.join(
        optdict2list(optdict, skiped_opts=skiped_opts, dumped_vals=dumped_vals)
    )


def optlist2dict(optlist, convert=False, **kwargs):
    """
    Convert an option list to an option dictionary.

    Parameters
    ----------
    optlist : iterable
        The option list that should be converted to an option
        dictionary.  Each option must start with a hyphen (``'-'``) and
        must be a separate item of the list.  Multiple values for the
        same option might be given as separate list items or one single
        list item.
    convert : bool, optional
        If ``True``, apply :func:`convert_str` on the **values** of the
        returned option dictionary.  This will convert strings to their
        corresponding Python data types.
    kwargs : dict, optional
        Keyword arguments to parse to :func:`convert_str`.

    Returns
    -------
    optdict : dict
        The resulting option dictionary.  Each item of `optlist` that
        starts with ``'-'`` becomes a key in `optdict`.  All following
        items that don't start with ``'-'`` become the value of that
        key.

    See Also
    --------
    :func:`shlex.join` :
        Convert an option list to an option string
    :func:`optdict2list` :
        Convert an option dictionary to an option list

    Examples
    --------
    .. testsetup::

        from opthandler import optlist2dict

    >>> optlist2dict(['-a', '0', '-b', '1'])
    {'a': '0', 'b': '1'}
    >>> optlist2dict([' -a', ' 0 ', ' -b ', '1 '])
    {'a': '0', 'b': '1'}
    >>> optlist2dict(['-a', '0', '-B', 'XyZ'])
    {'a': '0', 'B': 'XyZ'}
    >>> optlist2dict(['--ax', '0x', '---bxy', '1xy'])
    {'ax': '0x', 'bxy': '1xy'}
    >>> optlist2dict(['-a', '0', '-b', '1', '2'])
    {'a': '0', 'b': '1 2'}
    >>> optlist2dict(['-a', '0', '-b', '1 2'])
    {'a': '0', 'b': '1 2'}
    >>> optlist2dict(['-a', '0', '-b', '-c', '2'])
    {'a': '0', 'b': '', 'c': '2'}
    >>> optlist2dict(['arg1', 'arg2', '-b', '1'])
    {'': 'arg1 arg2', 'b': '1'}
    >>> optlist2dict([])
    {}

    Wrong input:

    >>> optlist2dict(['-a 0', '-b 1'])
    {'a 0': '', 'b 1': ''}
    """
    optdict = {}
    last_flag = ""
    for opt in optlist:
        opt = str(opt).strip()
        if opt.startswith("-"):
            opt = opt.lstrip("-")
            optdict[opt] = ""
            last_flag = opt
        else:
            optdict[last_flag] = optdict.pop(last_flag, "") + " " + opt
    if convert:
        optdict = {
            k.strip(): convert_str(v.strip(), **kwargs)
            for k, v in optdict.items()
        }
    else:
        optdict = {k.strip(): v.strip() for k, v in optdict.items()}
    return optdict


def posargs2str(posargs, prec=3):
    """
    Convert a list of positional arguments to a string.

    Parameters
    ----------
    posargs : iterable
        The list of positional arguments.
    prec : int, optional
        The number of decimal places to use for floating point numbers.

    Returns
    -------
    posargs : str
        The positional arguments as string.

    Notes
    -----
    This function is meant to generate a string of positional arguments
    that can be parsed to the Slurm job scripts of this project.

    ``True``/``False`` are converted to ``'1'``/``'0'``.

    Examples
    --------
    .. testsetup::

        from opthandler import posargs2str

    >>> posargs = ["in", "out", 0, 12.345, 12.344, True, "arg1 arg2"]
    >>> posargs2str(posargs, prec=2)
    "in out 0 12.35 12.34 1 'arg1 arg2'"
    """
    # Set a fixed number of decimal points for floats.
    posargs = (
        "{:.{p}f}".format(arg, p=prec) if isinstance(arg, float) else arg
        for arg in posargs
    )
    # Convert `True` to 1 and `False` to 0.
    posargs = (int(arg) if isinstance(arg, bool) else arg for arg in posargs)
    return shlex.join(str(arg) for arg in posargs)


def read_config(conf_file="hpcssrc.ini"):
    """
    Search and read options from a |config_file|.

    Parameters
    ----------
    conf_file : str, optional
        The name of the |config_file|.  The config file must be written
        in `INI language`_ as supported by the built-in
        :mod:`configparser` Python module.

        .. _INI language:
            https://docs.python.org/3/library/configparser.html#supported-ini-file-structure

    Returns
    -------
    config : configparser.ConfigParser
        A :class:`~configparser.ConfigParser` instance containing the
        configuration read from the first found config file.  If no
        config file was found, an empty
        :class:`~configparser.ConfigParser` is returned.

    Notes
    -----
    This function searches for the config file in the following order at
    the following locations:

        1. At the location given by `conf_file`.  If this is a relative
           path, it is interpreted relative to the current working
           directory.
        2. At :file:`${HOME}/.hpcss/hpcssrc.ini` (where :file:`${HOME}`
           is the user's home directory).
        3. In the root directory of the hpc_submit_scripts repository.

    As soon as a config file is found, this config file is read and
    other locations are not scanned anymore.  If no config file is found
    at all, this function returns an empty
    :class:`~configparser.ConfigParser`.

    Note that :class:`~configparser.ConfigParser` instances always store
    options and their values as strings.  However, unlike the default
    :class:`~configparser.ConfigParser`, the returned
    :class:`~configparser.ConfigParser` reads option names
    case-sensitively.  Moreover, section names are case-insensitive and
    leading and trailing spaces are removed.
    """  # noqa: W505,E501
    config = configparser.ConfigParser(converters={"none": str2none})
    # Remove leading and trailing spaces from section headers and ignore
    # the case of sections.
    config.SECTCRE = re.compile(r"\[ *(?P<header>[^]]+?) *\]", re.IGNORECASE)
    # Make option names case-sensitive.
    config.optionxform = str
    home = os.path.expanduser("~")
    file_root = os.path.abspath(os.path.dirname(__file__))
    project_root = os.path.abspath(os.path.join(file_root, "../"))
    if os.path.isfile(conf_file):
        config.read(conf_file)
    elif os.path.isfile(home + "/.hpcss/" + conf_file):
        config.read(home + "/.hpcss/" + conf_file)
    elif os.path.isfile(project_root + "/" + conf_file):
        config.read(project_root + "/" + conf_file)
        # Check if `project_root` is indeed the root directory of this
        # project.
        if not os.path.isfile(project_root + "/" + "LICENSE.txt"):
            raise FileExistsError(
                "Could not find the root directory of the hpc_submit_scripts"
                " project.  This might happen if you change the directory"
                " structure of this project"
            )
    return config


def rm_option(cmd, option):
    """
    Remove an option from a command string.

    Parameters
    ----------
    cmd : str
        The command from which to remove the given option(s).
    option : str or list or tuple
        The option(s) to remove.

    Returns
    -------
    cmd_new : str
        The command without the given option(s).

    Examples
    --------
    .. testsetup::

        from opthandler import rm_option

    >>> cmd = '--job-name=Test -o out.log --dependency afterok:12 -c 4'
    >>> options = ('--dependency', '-d')
    >>> rm_option(cmd, options)
    '--job-name=Test -o out.log -c 4'
    >>> cmd = '--job-name=Test -o out.log --dependency=afterok:12 -c 4'
    >>> rm_option(cmd, options)
    '--job-name=Test -o out.log -c 4'
    >>> cmd = '--job-name=Test -o out.log -d afterok:12 -c 4'
    >>> rm_option(cmd, options)
    '--job-name=Test -o out.log -c 4'
    >>> cmd = '--job-name=Test -o out.log -d=afterok:12 -c 4'
    >>> rm_option(cmd, options)
    '--job-name=Test -o out.log -c 4'
    >>> cmd = '-o out.log --dependency afterok:12 -d afterok:14 -c 4'
    >>> rm_option(cmd, options)
    '-o out.log -c 4'
    >>> rm_option(cmd, '--dependency')
    '-o out.log -d afterok:14 -c 4'
    >>> rm_option(cmd, '--dep')
    '-o out.log -d afterok:14 -c 4'
    >>> rm_option(cmd, '-d')
    '-o out.log --dependency afterok:12 -c 4'
    >>> cmd = '-o out.log -d afterok:12 -n 2 -d afterok:14 -c 4'
    >>> rm_option(cmd, '-d')
    '-o out.log -n 2 -c 4'
    """
    if isinstance(option, (list, tuple)):
        for opt in option:
            cmd = rm_option(cmd, opt)
    elif option in cmd:
        cmd_list = shlex.split(cmd)
        opt_ix = [
            ix for ix, o in enumerate(cmd_list) if o.startswith(option.strip())
        ]
        # Remove in reverse order so that indices in `opt_ix` stay valid
        for ix in opt_ix[::-1]:
            # Remove the option.
            popped = cmd_list.pop(ix)
            # NOTE: `shlex.split` does not split at "=" but at spaces.
            if "=" not in popped:
                # Remove the corresponding option value.
                cmd_list.pop(ix)
        cmd = " ".join(cmd_list)
    return cmd


def str2none(s, case_sensitive=False, empty_none=False):
    """
    Convert the string ``'None'`` to the NoneType ``None``.

    If the input is ``'None'``, convert it to the NoneType ``None``,
    else raise a :exc:`ValueError`.

    Parameters
    ----------
    s : str_like
        The input.  Can be anything that can be converted to a string.
    case_sensitive : bool, optional
        If ``False``, also convert the lower case string ``'none'`` to
        the NoneType ``None``.
    empty_none : bool, optional
        If ``True``, also convert the empty string ``''`` to the
        NoneType ``None``.

    Returns
    -------
    converted_string : None
        Returns the NoneType ``None`` if the input was ``'None'`` or
        convertible to ``'None'``.

    Raises
    ------
    ValueError
        If the input string was not ``'None'``.

    See Also
    --------
    :func:`convert_str` : Convert a string to its corresponding type

    Notes
    -----
    This function was written as converter for a
    :class:`~configparser.ConfigParser`.

    Examples
    --------
    .. testsetup::

        from opthandler import str2none

    >>> str2none(None)  # Returns None
    >>> str2none('None')  # Returns None
    >>> str2none('none')  # Returns None
    >>> str2none('none', case_sensitive=True)
    Traceback (most recent call last):
    ...
    ValueError: Input cannot be convertet to NoneType
    >>> str2none('')
    Traceback (most recent call last):
    ...
    ValueError: Input cannot be convertet to NoneType
    >>> str2none('', empty_none=True)  # Returns None
    >>> str2none(2)
    Traceback (most recent call last):
    ...
    ValueError: Input cannot be convertet to NoneType
    """
    s = str(s)
    if (
        (case_sensitive and s == "None")
        or (not case_sensitive and s.lower() == "none")
        or (empty_none and s == "")
    ):
        return None
    else:
        raise ValueError("Input cannot be convertet to NoneType")
