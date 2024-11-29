set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

id=`must_env_val "${env}" 'bench.result.filter.record-id'`
if [ `is_number "${id}"` != 'true' ]; then
	echo "[:(] arg 'record-id' value is '${id}', not a number"
	exit 1
fi

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`
ca=`env_val "${env}" 'bench.meta.ca'`

query="SELECT dashboard AS dummy_title FROM bench_meta WHERE id=${id}"
dashboard=`my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "${query}" 'tab' "${ca}" | { grep -v 'dummy_title' || test $? = 1; }`

if [ -z "${dashboard}" ]; then
	echo "[:(] dashboard link not found for record '${id}'" >&2
else
	echo "Dashboard:     http://${dashboard}"
fi
