#!/bin/bash

set -euo pipefail

scriptpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

UPDATE_PW="gerryNgregNjon987"

_exiterr() {
	echo "ERROR: ${1}" >&2
	exit 1
}

if [[ $# -ne 3 ]]; then
	echo "usage: $0 config Vx.y.z.tar.gz output.tar.gz"
	exit 1
fi

source "$1"
input="$2"
output="$3"
if [[ ! -f $input ]]; then
	_exiterr "input file does not exist"
fi

workdir="$(mktemp -d /tmp/qsc-patcher-XXXXXX)"
remove_workdir() { rm -rf "${workdir}"; }
trap remove_workdir EXIT

echo "+ workdir is $workdir"
echo "+ extracting input"
mkdir "${workdir}/unpack"
tar -x -C "${workdir}/unpack" -f "$input"

if [[ ! -f "${workdir}/unpack/upgrade-file" ]]; then
	_exiterr "tarball contained no upgrade-file"
fi

if [[ ! -f "${workdir}/unpack/checksum.txt" ]]; then
	_exiterr "tarball contained no checksum file"
fi

if ! (cd "${workdir}/unpack"; md5sum -c checksum.txt &> /dev/null); then
	_exiterr "upgrade-file checksum mismatch"
fi

echo "+ decrypting update file"
openssl bf -a -salt -d -in "${workdir}/unpack/upgrade-file" -out "${workdir}/unpack/root.tar.gz" -md md5 -pass "pass:${UPDATE_PW}"
rm "${workdir}/unpack/upgrade-file"

echo "+ extracting rootfs"
mkdir "${workdir}/root"
fakeroot -s "${workdir}/fakeroot" tar --warning=no-timestamp -xp -C "${workdir}/root" -f "${workdir}/unpack/root.tar.gz"
rm "${workdir}/unpack/root.tar.gz"

echo "+ applying patches"

for task in "${scriptpath}/patch.d/"*".sh"; do
	taskname="$(basename "$task")"
	printf "++ running patch step %s\\n" ${taskname%%.sh}
	(
		cd "${workdir}/root"
		exec fakeroot -s "${workdir}/fakeroot" "$task"
	)
done

echo "+ building tarball"
mkdir "${workdir}/patched"
fakeroot -s "${workdir}/fakeroot" tar -pczf "${workdir}/patched/root.tar.gz" -C "${workdir}/root/" --transform 's,^./,,g' .
rm -rf "${workdir}/root"

echo "+ encrypting update file"
openssl bf -a -salt -e -out "${workdir}/patched/upgrade-file" -in "${workdir}/patched/root.tar.gz" -md md5 -pass "pass:${UPDATE_PW}"
rm "${workdir}/patched/root.tar.gz"

echo "+ updating checksum file"
(cd "${workdir}/patched" && md5sum upgrade-file > checksum.txt)

echo "+ generating tarball"
tar -cz -f "$output" -C "${workdir}/patched" upgrade-file checksum.txt

echo "+ done!"
exit 0
