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
if [ -z "${file}" ]; then
	echo "[:(] arg 'file-path' is empty, exit" >&2
	exit 1
fi
file=`get_path_under_pwd "${env}" "${file}"`

if [ ! -z "${pp}" ]; then
	pp=" -p ${pp}"
fi

my_ensure_db "${host}" "${port}" "${user}" "${pp}" "${db}"

# check db is empty
tables=('bench_meta' 'bench_tags' 'bench_data')
for table in "${tables[@]}"; do
	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "CREATE TABLE IF NOT EXISTS ${table}(dummy int(11)) "
	rows=`my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "SELECT * FROM ${table} LIMIT 1" 'tab'`
	if [ ! -z "${rows}" ]; then
		echo "[:(] db '${db}' on '${host}:${port}' is not empty, exit" >&2
		exit 1
	fi
done

MYSQL_PWD="${pp}" mysql -h "${host}" -P "${port}" -u "${user}" "${db}" < "${file}"

echo "[:)] restored from '${file}'"
