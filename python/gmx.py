# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst


"""
Python functions related to molecular dynamics (MD) simulations
performed with |Gromacs|.
"""


def get_box_from_gro(fname):
    """
    Extract the simulation box dimensions from a |gro_file|.

    Parameters
    ----------
    fname : str
        Name of the |gro_file|.

    Returns
    -------
    box : list
        A list containing the simulation box dimensions read from the
        last line of the input file.
    """  # noqa: W505,E501
    box = tail(fname, 1)[0].split()
    box = [float(b) for b in box]
    return box


def get_last_time_from_log(fname):
    """
    Extract the time of the last frame of an |Gromacs| MD simulation
    from the |log_file|.

    Parameters
    ----------
    fname : str
        Name of the |log_file|.

    Returns
    -------
    time : float
        The time of the last frame in the |log_file|.
    """  # noqa: W505,E501
    lines = tail(fname, 300)
    line_prev = ""
    for line in lines[::-1]:
        if "Step" in line and "Time" in line:
            step, time = line_prev.split()
            return float(time)
        line_prev = line


def get_nbins(fname, binwidth):
    """
    Get the number of bins.

    Determine the number of bins to use to divide the z dimension of the
    simulation box stored in the provided |gro_file| in bins of the
    given bin width.

    Parameters
    ----------
    fname : str
        Name of the |gro_file| that holds the box dimensions.
    binwidth : float
        The desired bin width.

    Returns
    -------
    num_bins : int
        The number of bins required to divide the simulation box in bins
        of the given width.
    """
    box_z = get_box_from_gro(fname)[2]
    return round(box_z / binwidth)


def get_nsteps_from_mdp(fname):
    """
    Extract the maximum number of simulation steps of an |Gromacs| MD
    simulation from the |mdp_file|.

    Parameters
    ----------
    fname : str
        Name of the |mdp_file|.

    Returns
    -------
    nsteps : int
        Maximum number of simulation steps specified in the |mdp_file|.

    Raises
    ------
    FileNotFoundError
        If the input file does not exist.
    ValueError
        If the input file does not contain a line that starts with
        "nsteps" or if "nsteps" is not followed by an equal (=) sign.
    """  # noqa: W505,E501
    with open(fname, "r") as file:
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
            " 'nsteps'".format(fname)
        )
    if "=" not in line_nsteps:
        raise ValueError(
            "Line {} in file '{}' starts with 'nsteps' but does not contain an"
            " equal (=) sign".format(line_num, fname)
        )
    nsteps = line_nsteps.split("=")[1]
    nsteps = nsteps.split(";")[0]  # Remove potential comments
    return int(nsteps)


def tail(fname, n):
    """
    Read the last n lines from a file.

    Parameters
    ----------
    fname : str
        Name of the input file.
    n : int
        The number of lines to read from the end of the input file.

    Returns
    -------
    lines : list
        List containing the last `n` lines of the input file.  Each list
        item represents one line of the file.
    """
    lines = []
    if n <= 0:
        return lines
    # Step width to move the cursor (emprical value giving best
    # performance).
    step_width = max(10 * n, 1)
    with open(fname, "r") as file:
        file.seek(0, 2)  # Set cursor to end of file.
        pos = file.tell()  # Get current cursor position.
        # n+1 required to get the entire n-th line and not just its
        # ending.
        while len(lines) < n + 1:
            pos -= min(step_width, pos)
            file.seek(pos, 0)  # Move cursor backwards.
            lines = file.readlines()
            if pos == 0:  # Reached start of file.
                break
    return lines[-n:]
