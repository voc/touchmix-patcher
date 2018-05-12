#!/bin/bash

set -eo pipefail

if [[ -z "$ROOT_PW" ]]; then
	echo "+++ ROOT_PW not set, skipping"
	exit 0
fi

sed -i -e "s,^root:[^:]*:,root:${ROOT_PW}:," etc/passwd
