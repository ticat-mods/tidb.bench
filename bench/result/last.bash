set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

verb="${1}"

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

bench_record_prepare "${host}" "${port}" "${user}" "${db}"

query='SELECT MAX(bench_id) FROM bench_meta WHERE finished=1'
bench_id=`my_exe "${host}" "${port}" "${user}" "${db}" "${query}" 'tab' | grep -v 'MAX'`
if [ -z "${bench_id}" ]; then
	echo "[:(] no bench result found" >&2
	exit
fi

query="SELECT id FROM bench_meta WHERE bench_id=\"${bench_id}\" AND finished=1"
ids=`my_exe "${host}" "${port}" "${user}" "${db}" "${query}" 'tab' | grep -v 'id'`
ids=`lines_to_list "${ids}"`

if [ -z "${ids}" ]; then
	echo "[:(] no bench result found" >&2
	exit
fi

color=`must_env_val "${env}" 'display.color'`
width=`must_env_val "${env}" 'display.width.max'`

py=`must_env_val "${env}" 'sys.ext.exec.py'`
"${py}" "${here}/display_ids.py" "${host}" "${port}" "${user}" "${db}" "${verb}" "${color}" "${width}" "${ids}"
