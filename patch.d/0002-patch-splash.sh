#!/bin/bash

set -euo pipefail

scriptpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

target=usr/bin/psplash

pattern=$'\xff\x3d\x3f\x43'
len=39711
expected_hash="bc0d3ec5d1b0e1b2baa637023e0a4b63"
override="${scriptpath}/0002-patch-splash/cat.rle"

override_size=$(stat -c '%s' "$override")
if [[ $override_size -gt $len ]]; then
	echo "+++ override size (${override_size}) is larger than landing area (${len})"
	exit 1
fi

offset=""
while read -r pos; do
	pos=${pos%%:*}

	HASH=$(set +o pipefail; tail -c +$(( pos + 1)) "$target" | head -c "$len" | md5sum | cut -d ' ' -f1)
	if [[ "$HASH" = "$expected_hash" ]]; then
		offset=$pos
		break
	fi
done < <(grep -abo "$pattern" "$target")

if [[ -z "$offset" ]]; then
	echo "+++ standard image not found in file, aborting"
	exit 1
fi

echo "+++ patching $target at offset $offset"
dd if="$override" of="$target" obs=1 seek="$offset" conv=notrunc

bash
