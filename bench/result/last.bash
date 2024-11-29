set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

verb=`must_env_val "${env}" 'bench.result.display.verb'`

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`
ca=`env_val "${env}" 'bench.meta.ca'`

bench_record_prepare "${host}" "${port}" "${user}" "${pp}" "${db}" "${ca}"

query='SELECT MAX(bench_id) FROM bench_meta WHERE finished=1'
bench_id=`my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "${query}" 'tab' "${ca}" | \
	{ grep -v 'MAX' || test $? = 1; }`
if [ -z "${bench_id}" ]; then
	echo "[:(] no bench result found" >&2
	exit
fi

query="SELECT id FROM bench_meta WHERE bench_id=\"${bench_id}\" AND finished=1"
ids=`my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "${query}" 'tab' "${ca}" | \
	{ grep -v 'id' || test $? = 1; }`
if [ -z "${ids}" ]; then
	echo "[:(] no bench result found" >&2
	exit
fi
ids=`lines_to_list "${ids}"`

color=`must_env_val "${env}" 'display.color'`
width=`must_env_val "${env}" 'display.width.max'`

py=`must_env_val "${env}" 'sys.ext.exec.py'`
"${py}" "${here}/display_ids.py" "${host}" "${port}" "${user}" "${pp}" "${db}" "${ca}" "${verb}" "${color}" "${width}" "${ids}"
