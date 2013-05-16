#!/bin/sh

echo "Started building pubs."
rake cap:build_from_cap_data[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkaa]
echo "Finished chunkae."
rake cap:build_from_cap_data[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkab]
echo "Finished chunkab."
rake cap:build_from_cap_data[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkac]
echo "Finished chunkac."
rake cap:build_from_cap_data[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkad]
echo "Finished chunkad."
rake cap:build_from_cap_data[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkae]
echo "Finished chunkae."
rake cap:build_from_cap_data[/Users/jameschartrand/Documents/OSS/projects/stanford-cap/existingCAP/cutover/pubmed/chunkaf]
echo "Finished all"
