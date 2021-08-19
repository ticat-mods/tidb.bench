set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

threads=`must_env_val "${env}" 'bench.sysbench.load.threads'`
tables=`must_env_val "${env}" 'bench.sysbench.tables'`
table_size=`must_env_val "${env}" 'bench.sysbench.table-size'`
test_name=`must_env_val "${env}" 'bench.sysbench.test-name'`

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`
db='test'

mysql -h "${host}" -P "${port}" -u "${user}" -e "SET GLOBAL tidb_disable_txn_auto_retry = 'OFF'"
mysql -h "${host}" -P "${port}" -u "${user}" -e "CREATE DATABASE IF NOT EXISTS ${db}"

check_or_install sysbench

sysbench \
	--mysql-host="${host}" \
	--mysql-port="${port}" \
	--mysql-user="${user}" \
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
	query="analyze table ${db}.${db}${i}"
	echo "[:-] ${query} begin"
	mysql -h "${host}" -P "${port}" -u "${user}" "${db}" -e "${query}"
	echo "[:)] ${query} done"
done
