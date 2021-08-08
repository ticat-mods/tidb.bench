set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`

host=`env_val "${env}" 'bench.meta.host'`
if [ -z "${host}" ]; then
	if [ -f "${session}/scores" ]; then
		cat "${session}/scores"
	else
		echo "[:(] can't find meta db from env, and session file-record also not exists" >&2
	fi
	exit
fi

port=`must_env_val "${env}" 'bench.meta.port'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

run_start=`env_val "${env}" 'bench.run.start'`
if [ -z "${run_start}" ]; then
	query="SELECT * FROM score"
else
	bench_start=`env_val "${env}" 'bench.start'`
	if [ -z "${bench_start}" ]; then
		query="SELECT * FROM score"
	else
		query="SELECT * FROM score WHERE bench_start=FROM_UNIXTIME(${bench_start})"
		echo "${query}"
	fi
fi

mysql -h "${host}" -P "${port}" -u root --database="${db}" -e "${query}"
