#!/bin/bash

########################################################################
# Information and Usage Functions                                      #
########################################################################

information() {
    echo "Calculate the difference between two points in time using GNU date."
    echo "Input times must be enclosed in quotes (otherwise results might be"
    echo "wrong!) and they must be given in a format that is accepted by the"
    echo "--date option of GNU date.  The time difference is returned in the"
    echo "format Days-HH:MM:SS."
}

usage() {
    echo
    echo "Usage:"
    echo
    echo "Required arguments:"
    echo "  -s    Start time."
    echo
    echo "Optional arguments:"
    echo "  -h    Show this help message and exit."
    echo "  -e    End time.  Default: Time when this script was evoked."
}

########################################################################
# Argument Parsing                                                     #
########################################################################

sflag=false
eflag=false
while getopts s:he: option; do
    case ${option} in
        # Required arguments
        s)
            sflag=true
            start_time=${OPTARG}
            ;;
        # Optional arguments
        h)
            information
            usage
            exit 0
            ;;
        e)
            eflag=true
            end_time=${OPTARG}
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
    echo "ERROR: -s [start_time] required."
    usage
    exit 1
fi

# Set defaults for optional arguments
if [[ ${eflag} == false ]]; then
    end_time=$(date --rfc-3339=seconds || exit)
fi

########################################################################
# Main Part                                                            #
########################################################################

start_time_sec=$(date --date "${start_time}" +%s || exit)
end_time_sec=$(date --date "${end_time}" +%s || exit)
time_diff_sec=$((end_time_sec - start_time_sec))
date \
    --utc \
    --date \
    "@${time_diff_sec}" \
    "+$((time_diff_sec / 3600 / 24))-%H:%M:%S" ||
    exit
