bam_depth.sh is a bash script that filters BAM data, 
expands regions in BED files, calculates depth of coverage, 
and outputs a tab-separated file with region names and 
coverage depth for each position, while considering region strand.

__Usage:__
`./bam_depth.sh --bam <bam_file> --bed <bed_file> --slop 2 [--cpu <num_cpus>]`

__Output:__
```
ENSG00000187961.15	21	21	21	21	22
ENSG00000187583.11	42	42	42	43	42
ENSG00000187642.10	48	48	48	47	47
ENSG00000188290.11	40	39	39	38	37
ENSG00000187608.10	35	35	34	34	35
```
