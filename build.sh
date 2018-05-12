#!/bin/bash

set -euo pipefail

img_data=$(perl check_version.pl)
version=$(echo "$img_data" | cut -d ' ' -f 1)
checksum=$(echo "$img_data" | cut -d ' ' -f 2)
url=$(echo "$img_data" | cut -d ' ' -f 3)

mkdir input output
wget -O "input/V${version}.tar.gz" "$url"

exec ./patcher.sh config "input/V${version}.tar.gz" "output/V${version}.tar.gz"
