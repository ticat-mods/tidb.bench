
set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat ${1}/env`
shift

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

file="${1}"
if [ -z "${file}" ] || [ "${file:0:1}" != '/' ]; then
	work_dir=`must_env_val "${env}" 'sys.paths.work-dir'`
	file="${work_dir}/meta-db-${host}-${port}-${db}-${RANDOM}.sql"
fi

if [ ! -z "${pp}" ]; then
	pp=" -p ${pp}"
fi

# check tables exist
my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "SHOW TABLES" >/dev/null
tables=('bench_meta' 'bench_tags' 'bench_data')
for table in "${tables[@]}"; do
	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "SELECT * FROM ${table} LIMIT 1" >/dev/null
done

mysqldump"${pp}" -h "${host}" -P "${port}" -u "${user}" "${db}" > "${file}"

echo "[:)] exported to '${file}'"
