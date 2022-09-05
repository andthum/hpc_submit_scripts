# MIT License
# Copyright (c) 2021, 2022  All authors listed in the file AUTHORS.rst


"""
Python functions related to molecular dynamics (MD) simulations
performed with |Gromacs|.
"""


# Standard libraries
import bz2
import gzip
import lzma
import os


def get_box_from_gro(fname):
    """
    Extract the simulation box dimensions from a |gro_file|.

    Parameters
    ----------
    fname : str or bytes or os.PathLike
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


def get_compressed_file(fname):
    """
    Check if the input file or a compressed version it exsists.

    Check if the input file exsists.  If it does not exist, check
    whether a file with the same name but with one of the following
    extensions exsists:

        1. .gz
        2. .bz2
        3. .xz
        4. .lzma

    Files are checked in the given order.  The name of the first file
    found will be returned.  If none of the files exsists, an exception
    is raised.

    Parameters
    ----------
    fname : str or bytes or os.PathLike
        Name of the input file.

    Returns
    -------
    found_file : str or bytes
        Name of the first file found.

    Raises
    ------
    FileNotFoundError :
        If neither the input file itself nor the input file with one of
        the above mentioned extensions exists.
    """
    fname = os.fspath(fname)
    formats = ["", ".gz", ".bz2", ".xz", ".lzma"]
    if isinstance(fname, bytes):
        formats = [fmt.encode() for fmt in formats]
    files = [fname + fmt for fmt in formats]
    for file in files:
        if os.path.isfile(file):
            return file
    raise FileNotFoundError("No such files: '{}'".format("' '".join(files)))


def get_last_time_from_log(fname):
    """
    Extract the time of the last frame of an |Gromacs| MD simulation
    from the |log_file|.

    Parameters
    ----------
    fname : str or bytes or os.PathLike
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
    fname : str or bytes or os.PathLike
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
    fname : str or bytes or os.PathLike
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
    with xopen(fname, "r") as file:
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
    fname : str or bytes or os.PathLike
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
    with xopen(fname, "r") as file:
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


def xopen(fname, mode="rt", fformat=None, **kwargs):
    """
    Open a (compressed) file and return a corresponding
    `file-like_object
    <https://docs.python.org/3/glossary.html#term-file-like-object>`__.

    This function is a replacement for the built-in :func:`open`
    function that can additionally read and write compressed files.
    Supported compression formats:

        * gzip (.gz)
        * bzip2 (.bz2)
        * XZ/LZMA2 (.xz)
        * LZMA (.lzma)

    Parameters
    ----------
    fname : str or bytes or os.PathLike
        Name of the file to open.
    mode : {'r', 'rt', 'rb', 'w', 'wt', 'wb', 'x', 'xt', 'xb', 'a', \
'at', 'ab'}, optional
        Opening mode.  See the built-in :func:`open` function for more
        details.
    fformat : {None, 'gz', 'bz2', 'xz', 'lzma', 'uncompressed'}, \
optional
        Explicitly specify the file format.  If ``None``, the file
        format is guessed from the file name extension if present and
        otherwise from the file signature.  If ``'uncompressed'``, the
        file is treated as uncompressed file.
    kwargs : dict, optional
        Additional keyword arguments to parse to the function that is
        used for opening the file.  See there for possible arguments and
        their description.

    Returns
    -------
    file : file-like object
        The opened `file
        <https://docs.python.org/3/glossary.html#term-file-object>`__.

    See Also
    --------
    :func:`open` :
        Function used to open uncompressed files
    :func:`gzip.open` :
        Function used to open gzip-compressed files
    :func:`bz2.open` :
        Function used to open bzip2-compressed files
    :func:`lzma.open` :
        Function used to open XZ- and LZMA-compressed files

    Notes
    -----
    When writing and `fformat` is ``None``, the compression algorithm is
    chosen based on the extension of the given file:

        * ``'.gz'`` uses gzip compression.
        * ``'.bz2'`` uses bzip2 compression.
        * ``'.xz'`` uses XZ/LZMA2 compression.
        * ``'.lzma'`` uses legacy LZMA compression.
        * otherwise, no compression is done.

    When reading and `fformat` is ``None``, the file format is detected
    from the file name extension if present.  If no extension is present
    or the extension is unknown, the format is detected from the file
    signature, i.e. the first few bytes of the file also known as
    "`magic numbers
    <https://www.garykessler.net/library/file_sigs.html>`__".

    References
    ----------
    Inspired by `xopen <https://github.com/pycompression/xopen>`__ by
    Marcel Martin, Ruben Vorderman et al.

    .. _file-like_object:
        https://docs.python.org/3/glossary.html#term-file-like-object
    """
    fname = os.fspath(fname)
    signatures = {
        # https://datatracker.ietf.org/doc/html/rfc1952#page-6
        "gz": b"\x1f\x8b",
        # https://en.wikipedia.org/wiki/List_of_file_signatures
        "bz2": b"\x42\x5a\x68",
        # https://tukaani.org/xz/xz-file-format.txt
        "xz": b"\xfd\x37\x7a\x58\x5a\x00",
        # https://zenhax.com/viewtopic.php?t=27
        "lzma": b"\x5d\x00",
    }

    if fformat not in [None, "uncompressed"] + list(signatures.keys()):
        raise ValueError("Invalid value for 'fformat': {}".format(fformat))

    # Use text mode by default, like the built-in `open` function, also
    # when opening compressed files.
    if mode in ("r", "w", "x", "a"):
        mode += "t"

    # Detect file format from extension.
    if fformat is None:
        for extension in signatures.keys():
            if isinstance(fname, bytes):
                if fname.endswith(b"." + extension.encode()):
                    fformat = extension
            else:
                if fname.endswith("." + extension):
                    fformat = extension

    # Detect file format from file signature.
    if fformat is None and "w" not in mode and "x" not in mode:
        max_len = max(len(signature) for signature in signatures.values())
        try:
            with open(fname, "rb") as fh:
                file_start = fh.read(max_len)
        except OSError:
            # File could not be opened.
            file_start = False
        if file_start:
            for extension, signature in signatures.items():
                if file_start.startswith(signature):
                    fformat = extension
                    break

    if fformat == "gz":
        return gzip.open(fname, mode, **kwargs)
    elif fformat == "bz2":
        return bz2.open(fname, mode, **kwargs)
    elif fformat in ("xz", "lzma"):
        return lzma.open(fname, mode, **kwargs)
    elif fformat == "uncompressed" or fformat is None:
        return open(fname, mode, **kwargs)
