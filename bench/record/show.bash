set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`

host=`env_val "${env}" 'bench.meta.host'`
if [ -z "${host}" ]; then
	if [ -f "${session}/scores" ]; then
		cat "${session}/scores"
	fi
	exit
fi

port=`must_env_val "${env}" 'bench.meta.port'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

bench_start=`env_val "${env}" 'bench.start'`
if [ -z "${bench_start}" ]; then
	query="SELECT * FROM bench_meta.score"
else
	query="SELECT * FROM bench_meta.score WHERE bench_start=FROM_UNIXTIME(${bench_start})"
fi

mysql -h "${host}" -P "${port}" -u root --database="${db}" -e "${query}"
