#!/bin/sh

echo "Starting pubmed download."
rake cap_cutover:pull_pubmed_for_cap[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkaa]
echo "Finished chunkaa."
rake cap_cutover:pull_pubmed_for_cap[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkab]
echo "Finished chunkab."
rake cap_cutover:pull_pubmed_for_cap[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkac]
echo "Finished chunkac."
rake cap_cutover:pull_pubmed_for_cap[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkad]
echo "Finished chunkad."
rake cap_cutover:pull_pubmed_for_cap[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkae]
echo "Finished chunkae."
rake cap_cutover:pull_pubmed_for_cap[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkaf]

echo "Finished all."
