set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat ${1}/env`
shift

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`
ca=`env_val "${env}" 'bench.meta.ca'`

my_ensure_db "${host}" "${port}" "${user}" "${pp}" "${db}" "${ca}"

if [ ! -z "${ca}" ]; then
	local ca=" --ssl-ca=${ca}"
fi

MYSQL_PWD="${pp}" mysql -h "${host}" -P "${port}" -u "${user}"${ca} --comments ${db}
