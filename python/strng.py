# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst


"""Python functions that operate on or manipulate strings."""


def extract_ints_from_str(s):
    """
    Extract all integers from a string.

    Parameters
    ----------
    s : str
        The input string.

    Returns
    -------
    ints : list
        List of integers in `s`.

    Examples
    --------
    .. testsetup::

        from strng import extract_ints_from_str

    >>> extract_ints_from_str('I have 2 apples and 4 pears')
    [2, 4]
    >>> extract_ints_from_str('I have 2.5 apples and 4 pears')
    [4]
    >>> extract_ints_from_str('I have no apples and no pears')
    []
    >>> extract_ints_from_str('I have -1 apples and -2.5 pears')
    []
    """
    ints = [int(i) for i in s.split() if i.isdigit()]
    return ints
