#!/bin/bash

set -eo pipefail

if [[ $# -ne 4 ]]; then
	echo "usage: $0 in out version firmware"
	exit 1
fi

in="$1"
out="$2"
version="$3"
firmware="$4"

echo "+ generating versions.xml"

if [[ $(grep -c "<Version" "$in") -ne 1 ]]; then
	echo "unexpected number of <Version> tags"
	exit 1
fi

if ! grep -q "BuildNumber=\"$version\"" "$in" > /dev/null; then
	echo "mismatched version"
	exit 1
fi

if [[ ! -f "$firmware" ]]; then
	echo "firmware file $firmware does not exist"
	exit 1
fi

MD5=$(md5sum "$firmware" | cut -d' ' -f1)

cp "$in" "$out"
sed -i -e "s,HostURL=\"[^\"]*\",HostURL=\"${UPDATE_URL}\",g" "$out"
sed -i -e "s,Checksum=\"[^\"]*\",Checksum=\"${MD5}\",g" "$out"
sed -i -e "s,</Notes>,<Item data=\"* custom-patched firmware version!\"/>\n</Notes>,g" "$out"
