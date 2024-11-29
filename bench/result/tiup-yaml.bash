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

to_file="${2}"

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`
ca=`env_val "${env}" 'bench.meta.ca'`

query="SELECT tiup_yaml FROM bench_meta WHERE id=${id}"
text=`my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "${query}" 'tab' "${ca}" | { grep -v 'tiup_yaml' || test $? = 1; }`

if [ -z "${text}" ]; then
	echo "[:(] tiup yaml file not found for record '${id}'" >&2
	exit 1
fi

text=`echo "${text}" | base64 --d`

if [ -z "${to_file}" ]; then
	echo "${text}"
else
	c="${to_file:0:1}"
	if [ "${c}" != '/' ] && [ "${c}" != '\' ]; then
		echo "[:(] arg 'to-file' should be abs path" >&2
		exit 1
	else
		echo "${text}" > "${to_file}"
	fi
fi
