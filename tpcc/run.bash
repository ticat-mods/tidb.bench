set -euo pipefail

env=`cat "${1}/env"`
shift

here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/base.bash" "${env}" "${here}"

host=`env_val 'mysql.host'`
port=`env_val 'mysql.port'`
user=`env_val 'mysql.user'`

warehouses=`env_val 'bench.tpcc.warehouses'`

threads=`env_val 'bench.tpcc.threads'`
duration=`env_val 'bench.tpcc.duration'`

${bin} \
	-T "${threads}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	--warehouses "${warehouses}" --time "${duration}" run
