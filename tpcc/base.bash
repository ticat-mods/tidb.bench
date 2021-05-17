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
	local k1="${1}"
	local k2="${2}"
	val=`echo "${env}" | { grep "^${k1}" || test $? = 1; } | awk '{print $2}'`
	if [ -z "${val}" ]; then
		echo "[:-] no env val '${k1}'" >&2
		val=`echo "${env}" | { grep "^${k2}" || test $? = 1; } | awk '{print $2}'`
		if [ -z "${val}" ]; then
			echo "[:(] no env val '${k2}' too" >&2
			exit 1
		else
			echo "[:-] got it from env val '${k2}'" >&2
		fi
	fi
	echo "${val}"
}

host=`env_val 'bench.mysql.host' 'mysql.host'`
port=`env_val 'bench.mysql.port' 'mysql.port'`
user=`env_val 'bench.mysql.user' 'mysql.user'`

threads=`echo "${env}" | { grep '^bench.tpcc.threads' || test $? = 1; } | awk '{print $2}'`
if [ -z "${threads}" ]; then
	echo "[:(] no env val 'bench.tpcc.threads', set to 1" >&2
	threads='1'
fi
warehouses=`echo "${env}" | { grep '^bench.tpcc.warehouses' || test $? = 1; } | awk '{print $2}'`
if [ -z "${warehouses}" ]; then
	echo "[:(] no env val 'bench.tpcc.warehouses', set to 1" >&2
	warehouses='1'
fi
