set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../../helper/helper.bash"

env=`cat "${1}/env"`
shift

ids="${1}"
tags="${2}"

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

bench_record_rm_tags "${host}" "${port}" "${user}" "${pp}" "${db}" "${ids}" "${tags}"
echo "[:)] done"
