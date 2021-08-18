set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`
shift

event="${1}"

host=`env_val "${env}" 'bench.meta.host'`
if [ -z "${host}" ]; then
	if [ -f "${session}/durations" ]; then
		cat "${session}/durations"
	else
		echo "[:(] can't find meta db from env, and session file-record also not exists" >&2
	fi
	exit
fi

port=`must_env_val "${env}" 'bench.meta.port'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

if [ -z "${event}" ]; then
	query="SELECT * FROM durations"
else
	query="SELECT * FROM durations WHERE event=\"${event}\""
fi

mysql -h "${host}" -P "${port}" -u root --database="${db}" -e "${query}"
