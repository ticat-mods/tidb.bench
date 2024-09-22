set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

warehouses=`must_env_val "${env}" 'bench.tpcc.warehouses'`
threads=`must_env_val "${env}" 'bench.tpcc.load.threads'`
db=`must_env_val "${env}" 'bench.tpcc.db'`

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`
pp=`env_val "${env}" 'mysql.pwd'`

#tiup bench tpcc \
go-tpc tpcc prepare \
	-T "${threads}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	-p "${pp}" \
	-D "${db}" \
	--dropdata \
	--warehouses "${warehouses}" --time "102400h"
#	--warehouses "${warehouses}" --time "102400h" prepare

analyze=`must_env_val "${env}" 'bench.tpcc.load.analyze'`
analyze=`to_false "${analyze}"`

if [ "${analyze}" == 'false' ]; then
	exit
fi

tables=(
	'customer'
	'district'
	'history'
	'item'
	'new_order'
	'orders'
	'order_line'
	'stock'
	'warehouse'
)
for table in ${tables[@]}; do
	query="analyze table ${db}.${table}"
	echo "[:-] ${query} begin"
	MYSQL_PWD="${pp}" mysql -h "${host}" -P "${port}" -u "${user}" "${db}" -e "${query}"
	echo "[:)] ${query} done"
done
