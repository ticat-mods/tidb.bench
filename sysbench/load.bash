set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

threads=`must_env_val "${env}" 'bench.sysbench.load.threads'`
tables=`must_env_val "${env}" 'bench.sysbench.tables'`
table_size=`must_env_val "${env}" 'bench.sysbench.table-size'`
test_name=`must_env_val "${env}" 'bench.sysbench.test-name'`
db=`must_env_val "${env}" 'bench.sysbench.db'`

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`
pp=`env_val "${env}" 'mysql.pwd'`
ca=`env_val "${env}" 'mysql.ca'`

if [ ! -z "${ca}" ]; then
	mysql_ca=" --ssl-ca=${ca}"
else
	mysql_ca=''
fi

MYSQL_PWD="${pp}" mysql -h "${host}" -P "${port}" -u "${user}"${mysql_ca} -e "SET GLOBAL tidb_disable_txn_auto_retry = 'OFF'"
MYSQL_PWD="${pp}" mysql -h "${host}" -P "${port}" -u "${user}"${mysql_ca} -e "CREATE DATABASE IF NOT EXISTS ${db}"

check_or_install sysbench

if [ ! -z "${ca}" ]; then
	sb_ca="--mysql-ssl=on --mysql-ssl-ca=${sb_ca}"
else
	sb_ca=''
fi

sysbench \
	"${sb_ca}"
	--mysql-host="${host}" \
	--mysql-port="${port}" \
	--mysql-user="${user}" \
	--mysql-password="${pp}" \
	--mysql-db="${db}" \
	--threads="${threads}" \
	--db-driver=mysql \
	--tables="${tables}" \
	--table-size="${table_size}" \
	"${test_name}" prepare

analyze=`must_env_val "${env}" 'bench.sysbench.load.analyze'`
analyze=`to_false "${analyze}"`

if [ "${analyze}" == 'false' ]; then
	exit
fi

for ((i=1;i<=tables;i++)); do
	query="analyze table ${db}.sbtest${i}"
	echo "[:-] ${query} begin"
	MYSQL_PWD="${pp}" mysql -h "${host}" -P "${port}" -u "${user}" "${db}" -e "${query}"
	echo "[:)] ${query} done"
done
