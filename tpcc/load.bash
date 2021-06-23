set -euo pipefail

env=`cat "${1}/env"`
shift

here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/base.bash" "${env}" "${here}"

threads=`env_val 'bench.tpcc.load.threads'`

${bin} \
	-T "${threads}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	--dropdata \
	--warehouses "${warehouses}" --time "102400h" prepare
