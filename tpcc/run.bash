set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

session="${1}"
env=`cat "${session}/env"`

warehouses=`must_env_val "${env}" 'bench.tpcc.warehouses'`
threads=`must_env_val "${env}" 'bench.tpcc.threads'`
duration=`must_env_val "${env}" 'bench.tpcc.duration'`
db=`must_env_val "${env}" 'bench.tpcc.db'`

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`

pp=`env_val "${env}" 'mysql.pwd'`

log="${session}/tpcc.`date +%s`.log"
echo "bench.run.log=${log}" >> "${session}/env"

tiup bench tpcc \
	-T "${threads}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	-p "${pp}" \
	-D "${db}" \
	--warehouses "${warehouses}" --time "${duration}" run | tee "${log}"

score=`parse_tpmc "${log}"`
summary=`parse_tpmc_summary "${log}"`
echo
echo "${summary}" | tee "${log}.summary"

echo "bench.workload=tpcc" >> "${session}/env"
echo "bench.run.score=${score}" >> "${session}/env"
