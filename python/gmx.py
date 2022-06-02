# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst


"""
Python functions related to molecular dynamics (MD) simulations
performed with Gromacs_.

.. _Gromacs: https://www.gromacs.org/
"""


def get_nsteps_from_mdp(infile):
    """
    Extract the maximum number of simulation steps of an Gromacs MD
    simulation from the `.mpd file
    <https://manual.gromacs.org/documentation/current/user-guide/mdp-options.html>`__.

    Parameters
    ----------
    infile : str
        Name of the .mdp file.

    Returns
    -------
    nsteps : int
        Maximum number of simulation steps specified in the .mdp file.

    Raises
    ------
    FileNotFoundError
        If the input file does not exist.
    ValueError
        If the input file does not contain a line that starts with
        "nsteps" or if "nsteps" is not followed by an equal (=) sign.
    """  # noqa: W505,E501
    with open(infile, "r") as file:
        found_nsteps = False
        for i, line in enumerate(file):
            line = line.strip()
            if line.startswith("nsteps"):
                found_nsteps = True
                line_nsteps = line
                line_num = i + 1
                # nsteps can be defined multiple times in an .mdp file.
                # From
                # https://manual.gromacs.org/documentation/current/reference-manual/file-formats.html#mdp  # noqa: W505,E501
                # "The ordering of the items is not important, but if
                # you enter the same thing twice, the last is used."
                # => Do not break the loop after the first occurence of
                #    'nsteps'.
    if not found_nsteps:
        raise ValueError(
            "Could not fine a line in file '{}' that starts with"
            " 'nsteps'".format(infile)
        )
    if "=" not in line_nsteps:
        raise ValueError(
            "Line {} in file '{}' starts with 'nsteps' but does not contain an"
            " equal (=) sign".format(line_num, infile)
        )
    nsteps = line_nsteps.split("=")[1]
    nsteps = nsteps.split(";")[0]  # Remove potential comments
    return int(nsteps)
