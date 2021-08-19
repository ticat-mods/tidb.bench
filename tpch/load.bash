set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

sf=`must_env_val "${env}" 'bench.tpch.scale-factor'`
threads=`must_env_val "${env}" 'bench.tpch.load.threads'`

tiflash=`must_env_val "${env}" 'bench.tpch.tiflash'`
tiflash=`to_true "${tiflash}"`
if [ "${tiflash}" == 'true' ]; then
	tiflash=" --tiflash"
else
	tiflash=" "
fi

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`

tiup bench tpch prepare \
	-T "${threads}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	--dropdata \
	--sf "${sf}" --time "102400h" \
	--analyze --tidb_build_stats_concurrency 8 --tidb_distsql_scan_concurrency 30${tiflash}

analyze=`must_env_val "${env}" 'bench.tpch.load.analyze'`
analyze=`to_false "${analyze}"`

# The command 'tiup bench tpch prepare' will do analyze, so the default value will be false
if [ "${analyze}" == 'false' ]; then
	exit
fi

query="SET GLOBAL tidb_multi_statement_mode='ON'"
mysql -h "${host}" -P "${port}" -u "${user}" "${db}" -e "${query}"

db="test"
tables=(lineitem orders partsupp part customer supplier nation part region)
for table in ${tables[@]}; do
	query="analyze table ${db}.${table}"
	echo "[:-] ${query} begin"
	mysql -h "${host}" -P "${port}" -u "${user}" "${db}" -e "${query}"
	echo "[:)] ${query} done"
done
