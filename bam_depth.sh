#!/bin/bash
#
# bam_depth.sh is a bash script that takes a BAM file and a BED file as input,
# filtes BAM and calculates the depth of coverage for each region in the BED file. 
# It considers the strand of the region and outputs a tab-separated file with 
# the region name and the coverage depth for each position in the region.
# 
# Usage:
# ./bam_depth.sh --bam ${BAM} --bed {BED}
#
# Output:
# ENSG00000187961.15	21	21	21	21	22
# ENSG00000187583.11	42	42	42	43	42
# ENSG00000187642.10	48	48	48	47	47
# ENSG00000188290.11	40	39	39	38	37
# ENSG00000187608.10	35	35	34	34	35
# 
# Copyright (c) 2023, Denis Odinokov
#
# Permission is hereby granted, free of charge, to any person or organization
# obtaining a copy of the software and accompanying documentation covered by
# this license (the "Software") to use, reproduce, display, distribute,
# execute, and transmit the Software, and to prepare derivative works of the
# Software, and to permit third-parties to whom the Software is furnished to
# do so, all subject to the following:

# The copyright notices in the Software and this entire statement, including
# the above license grant, this restriction and the following disclaimer,
# must be included in all copies of the Software, in whole or in part, and
# all derivative works of the Software, unless such copies or derivative
# works are solely in the form of machine-executable object code generated by
# a source language processor.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
# SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
# FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

DEFAULT_CPU=4

show_help() {
    cat << EOF
Usage: $0 --bam <bam_file> --bed <bed_file> [--cpu <num_cpus>]

Mandatory arguments:
  --bam     path to BAM file
  --bed     path to BED file

Optional arguments:
  --cpu     number of CPUs (default: $DEFAULT_CPU)
  --help    display this help message and exit
EOF
}

parse_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --bam)
                BAM_FILE="$2"
                shift 2
                ;;
            --bed)
                BED_FILE="$2"
                shift 2
                ;;
            --cpu)
                NUM_CPUS="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
}

check_dependencies() {

    # Define software dependencies
    declare -ra deps=("samtools" "crabz")

    # Check that required software dependencies are installed
    for dep in "${deps[@]}"
    do
    command -v "$dep" >/dev/null 2>&1 || { echo >&2 "Error: $dep is required but not installed. Aborting."; exit 1; }
    done

}

check_files() {

    if [[ ! -f "${BAM_FILE}" ]] || [[ ! -f "${BED_FILE}" ]]; then
        echo "Error: BAM and BED files must exist" >&2
        show_help
        exit 1
    fi
}

run_command() {
    
    PREFIX="$(basename ${BAM_FILE} .bam | sed -E 's@(rmduplic-|merged-|-sorted|_P|_merge|-ready)@@g')"

    while IFS=$'\t' read -r CHROM START END NAME SCORE STRAND; do

    TMP_BAM_FILE=$(mktemp --suffix=.${PREFIX})

    samtools view -@${NUM_CPUS} -b -h -q 5 -f 3 -F 3852 -G 48 --incl-flags 48 ${BAM_FILE} ${CHROM}:${START}-${END} > ${TMP_BAM_FILE}

    samtools index -@${NUM_CPUS} ${TMP_BAM_FILE}

    if [ ${STRAND} == "-" ]; then
        R='r'
    else
        R=''
    fi

    samtools depth -a -s -r ${CHROM}:${START}-${END} -@${NUM_CPUS} ${TMP_BAM_FILE} 2> /dev/null \
    | sort --parallel=${NUM_CPUS} -k 1,1 -k2,2n${R} -u -V \
    | cut -f3 | paste -sd '\t' - | awk -v NAME=${NAME} '{print NAME"\t"$0}'

    cleanup

    done < <(crabz -d -p${NUM_CPUS} ${BED_FILE} 2> /dev/null)
}

cleanup() {
    # Your cleanup code goes here
    # echo "Cleaning up..."
    rm -rf ${TMP} ${TMP}.bai
}

main() {
    parse_options "$@"

    if [[ -z "${BAM_FILE}" ]] || [[ -z "${BED_FILE}" ]]; then
        echo "Error: BAM and BED files must be specified" >&2
        show_help
        exit 1
    fi

    check_files

    check_dependencies

    NUM_CPUS=${NUM_CPUS:-$DEFAULT_CPU}

    run_command
}

trap cleanup EXIT
main "$@"
exit 0
