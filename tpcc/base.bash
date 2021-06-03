set -euo pipefail

env="${1}"
here="${2}"

repo="`dirname ${here}`/repos/go-tpc"
bin="${repo}/bin/go-tpc"

if [ ! -f "${bin}" ]; then
	(
		cd "${repo}" && make
	)
	wait
fi

if [ ! -f "${bin}" ]; then
	echo "[:(] compile go-tpc failed" >&2
	exit 1
fi

function env_val()
{
	local key="${1}"
	val=`echo "${env}" | { grep "^${key}" || test $? = 1; } | awk '{print $2}'`
	if [ -z "${val}" ]; then
		echo "[:-] no env val '${key}'" >&2
		exit 1
	fi
	echo "${val}"
}

host=`env_val 'mysql.host'`
port=`env_val 'mysql.port'`
user=`env_val 'mysql.user'`

threads=`env_val 'bench.tpcc.threads'`
warehouses=`env_val 'bench.tpcc.warehouses'`
