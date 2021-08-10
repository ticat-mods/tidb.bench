set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

sf=`must_env_val "${env}" 'bench.tpch.scale-factor'`
threads=`must_env_val "${env}" 'bench.tpch.load.threads'`

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
	--tiflash \
	--analyze --tidb_build_stats_concurrency 8 --tidb_distsql_scan_concurrency 30
