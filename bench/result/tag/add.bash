set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../../helper/helper.bash"

env=`cat "${1}/env"`
shift

tags="${1}"
ids=`must_env_val "${env}" 'bench.meta.result.ids'`

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`
ca=`env_val "${env}" 'bench.meta.ca'`

bench_record_add_tags "${host}" "${port}" "${user}" "${pp}" "${db}" "${ids}" "${tags}" "${ca}"
echo "[:)] done"
