set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat ${1}/env`
shift

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

my_ensure_db "${host}" "${port}" "${user}" "${pp}" "${db}"

bench_record_clear "${host}" "${port}" "${user}" "${pp}" "${db}"

# recreate tables
bench_record_prepare "${host}" "${port}" "${user}" "${pp}" "${db}"

echo "[:)] all clear"
