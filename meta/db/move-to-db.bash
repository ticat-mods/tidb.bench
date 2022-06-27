set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat ${1}/env`
shift

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`

src=`must_env_val "${env}" 'bench.meta.db-name'`
dest="${1}"

my_ensure_db "${host}" "${port}" "${user}" "${pp}" "${src}"
my_ensure_db "${host}" "${port}" "${user}" "${pp}" "${dest}"

tables=('bench_meta' 'bench_tags' 'bench_data')
for table in "${tables[@]}"; do
	my_exe "${host}" "${port}" "${user}" "${pp}" "${dest}" "ALTER TABLE ${src}.${table} RENAME ${dest}.${table}"
done

echo "[:)] meta data moved from '${src}' to '${dest}'"
