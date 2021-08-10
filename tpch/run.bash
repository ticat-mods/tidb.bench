set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`

sf=`must_env_val "${env}" 'bench.tpch.scale-factor'`
threads=`must_env_val "${env}" 'bench.tpch.threads'`
duration=`must_env_val "${env}" 'bench.tpch.duration'`

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`

log="${session}/tpch.`date +%s`.log"
echo "bench.run.log=${log}" >> "${session}/env"

echo "SET GLOBAL tidb_multi_statement_mode='ON';" | mysql -P "${port}" -h "${host}" -u "${user}" test

tiup bench tpch \
	-T "${threads}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	--sf "${sf}" --time "${duration}" run | tee "${log}"
