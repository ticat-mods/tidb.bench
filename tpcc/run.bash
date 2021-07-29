set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`

warehouses=`must_env_val "${env}" 'bench.tpcc.warehouses'`
threads=`must_env_val "${env}" 'bench.tpcc.threads'`
duration=`must_env_val "${env}" 'bench.tpcc.duration'`

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`

log="${session}/tpcc.`date +%s`.log"
echo "bench.log=${log}" >> "${session}/env"

tiup bench tpcc \
	-T "${threads}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	--warehouses "${warehouses}" --time "${duration}" run | tee "${log}"

score=`parse_tpmc "${log}"`
echo "bench.score=${score}" >> "${session}/env"
