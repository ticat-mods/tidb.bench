set -euo pipefail

env=`cat "${1}/env"`
shift

here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/base.bash" "${env}" "${here}"

duration=`echo "${env}" | { grep '^bench.tpcc.duration' || test $? = 1; } | awk '{print $2}'`
if [ -z "${duration}" ]; then
	echo "[:(] no env val 'bench.tpcc.duration', set to '1m'" >&2
	duration='1m'
fi

"${bin}" \
	-T "${threads}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	--dropdata \
	tpcc --warehouses "${warehouses}" --time "${duration}" run
