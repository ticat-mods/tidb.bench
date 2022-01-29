set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

session="${1}"
env=`cat "${session}/env"`

sf=`must_env_val "${env}" 'bench.tpch.scale-factor'`
threads=`must_env_val "${env}" 'bench.tpch.threads'`
duration=`must_env_val "${env}" 'bench.tpch.duration'`
queries=`must_env_val "${env}" 'bench.tpch.queries'`

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`
db=`must_env_val "${env}" 'mysql.db'`

log="${session}/tpch.`date +%s`.log"
echo "bench.run.log=${log}" >> "${session}/env"

echo "SET GLOBAL tidb_multi_statement_mode='ON';" | mysql -P "${port}" -h "${host}" -u "${user}" "${db}"

tiup bench tpch \
	-T "${threads}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	-D "${db}" \
	--queries "${queries}" \
	--sf "${sf}" --time "${duration}" run | tee "${log}"

score=`parse_tpch_score "${log}"`
detail=`parse_tpch_detail "${log}"`

echo "bench.workload=tpch" >> "${session}/env"
echo "bench.tpch.detail=${detail}" >> "${session}/env"
echo "bench.run.score=${score}" >> "${session}/env"
