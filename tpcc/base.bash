set -euo pipefail

env="${1}"
here="${2}"

repo="`dirname ${here}`/repos/go-tpc"
bin="tiup bench tpcc"

function env_val()
{
	local key="${1}"
	local val=`echo "${env}" | { grep "^${key}" || test $? = 1; } | awk '{print $2}'`
	if [ -z "${val}" ]; then
		echo "[:-] no env val '${key}'" >&2
		exit 1
	fi
	echo "${val}"
}
