set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

ids="${1}"
ids=`lines_to_list "${ids}"`
verb="${2}"

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

bench_record_prepare "${host}" "${port}" "${user}" "${pp}" "${db}"

color=`must_env_val "${env}" 'display.color'`
width=`must_env_val "${env}" 'display.width.max'`

py=`must_env_val "${env}" 'sys.ext.exec.py'`
"${py}" "${here}/display_ids.py" "${host}" "${port}" "${user}" "${pp}" "${db}" "${verb}" "${color}" "${width}" "${ids}"
