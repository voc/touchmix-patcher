#!/bin/bash

set -eo pipefail

if [[ -z "$UPDATE_URL" || -z "$UPDATE_SERVER" ]]; then
	echo "+++ UPDATE_URL or UPDATE_SERVER not set, skipping"
	exit 0
fi

sed -i -e "s,^UG_HOST=.*,UG_HOST=${UPDATE_SERVER},g" usr/share/ds2i/check-upgrade-available.sh
sed -i -e "s,http://tm.qschome.com:8080/tm16/,${UPDATE_URL},g" usr/share/ds2i/check-upgrade-available.sh
