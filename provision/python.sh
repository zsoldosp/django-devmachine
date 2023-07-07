#!/usr/bin/env bash
#
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi
SCRIPT_DIR=$(dirname $(readlink -f ${0}))
# pip for pre commit, 3.11 to run pre commit hooks
sudo DEBIAN_FRONTEND=noninteractive apt-get install software-properties-common --yes
sudo DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:deadsnakes/ppa --yes
for version in 2.7 3.4 3.5 3.6 3.7 3.8 3.9 3.10 3.11; do
	python=python${version}
	sudo DEBIAN_FRONTEND=noninteractive apt-get install  ${python} --yes
	if ! ${python} -c"import virtualenv"; then
		# TODO: fixme
	do
done
sudo DEBIAN_FRONTEND=noninteractive add-apt-repository --remove ppa:deadsnakes/ppa --yes
pip install tox
ACCOUNT=zsoldosp
for repo in django-performance-testing django-currentuser django-act-as-auth django-admin-caching django-httpxforwardedfor; do
	target=~/${repo}
	if [[ ! -d ${target} ]]; then
		git clone git@github.com:${ACCOUNT}/${repo}.git ${target}
	fi
	#cd ${target}
done
