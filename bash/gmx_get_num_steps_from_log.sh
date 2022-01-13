#!/bin/bash

########################################################################
# Information and Usage Functions                                      #
########################################################################

information() {
    echo "Extract the final number of simulation steps of an Gromacs MD"
    echo "simulation from the .log file."
}

usage() {
    echo
    echo "Usage:"
    echo
    echo "Required arguments:"
    echo "  -f    Name of the .log file."
    echo
    echo "Optional arguments:"
    echo "  -h    Show this help message and exit."
}

########################################################################
# Argument Parsing                                                     #
########################################################################

sflag=false
while getopts f:h option; do
    case ${option} in
        # Required arguments
        f)
            sflag=true
            infile=${OPTARG}
            ;;
        # Optional arguments
        h)
            information
            usage
            exit 0
            ;;
        # Handling of invalid options or missing arguments
        *)
            usage
            exit 1
            ;;
    esac
done

# Check if all required arguments are given
if [[ ${sflag} == false ]]; then
    echo
    echo "ERROR: -f [infile] required."
    usage
    exit 1
fi

########################################################################
# Main Part                                                            #
########################################################################

if [[ ! -f ${infile} ]]; then
    echo
    echo "ERROR: No such file: '${infile}'"
    exit 1
fi

read_lines=150
counter=1
found_Statistics=false
for string in $(tail -n "${read_lines}" "${infile}" || exit); do
    if [[ ${string} == Statistics ]]; then
        # When ${string} has reached "Statistics", two more iterations
        # are necessary to come to the final number of simulation steps.
        # => Set counter to -3, so it will be -1 in two more iterations.
        counter=-3
        found_Statistics=true
    fi
    if [[ ${counter} -eq -1 ]]; then
        num_steps=${string}
        # Subtract 1 to remove the 0-th step.
        num_steps=$((num_steps - 1))
        break
    fi
    counter=$((counter + 1))
done

if [[ ${found_Statistics} == false ]]; then
    echo
    echo "ERROR: Could not determine the final number of simulation steps from"
    echo "'${infile}'.  Could not find the string 'Statistics' in the last"
    echo "${read_lines} line(s) of '${infile}'.  This might happen if Gromacs"
    echo "could not terminate the simulation gracefully."
    exit 1
fi
if [[ -z ${num_steps} ]]; then
    echo
    echo "ERROR: Could not determine the final number of simulation steps from"
    echo "'${infile}'."
    exit 1
fi

echo "${num_steps}" || exit
