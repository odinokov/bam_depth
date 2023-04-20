bam_depth.sh is a bash script that takes a BAM file and a BED file as input 
and calculates the depth of coverage for each region in the BED file. 
It considers the strand of the region and outputs a tab-separated file with 
the region name and the coverage depth for each position in the region.

__Usage:__
`./bam_depth.sh --bam ${BAM} --bed{BED}`

__Output:__
```
ENSG00000187961.15	21	21	21	21	22
ENSG00000187583.11	42	42	42	43	42
ENSG00000187642.10	48	48	48	47	47
ENSG00000188290.11	40	39	39	38	37
ENSG00000187608.10	35	35	34	34	35
```
