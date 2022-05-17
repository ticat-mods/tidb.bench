set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

bench_id="${1}"
verb="${2}"

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

bench_record_prepare "${host}" "${port}" "${user}" "${db}"

query="SELECT id FROM bench_meta WHERE bench_id=\"${bench_id}\" AND finished=1"
ids=`my_exe "${host}" "${port}" "${user}" '' "${db}" "${query}" 'tab' | { grep -v 'id' || test $? = 1; }`
ids=`lines_to_list "${ids}"`

color=`must_env_val "${env}" 'display.color'`
width=`must_env_val "${env}" 'display.width.max'`

py=`must_env_val "${env}" 'sys.ext.exec.py'`
"${py}" "${here}/display_ids.py" "${host}" "${port}" "${user}" "${db}" "${verb}" "${color}" "${width}" "${ids}"
