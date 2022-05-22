set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

session="${1}"
env=`cat "${session}/env"`

threads=`must_env_val "${env}" 'bench.sysbench.threads'`
duration=`must_env_val "${env}" 'bench.sysbench.duration'`
tables=`must_env_val "${env}" 'bench.sysbench.tables'`
table_size=`must_env_val "${env}" 'bench.sysbench.table-size'`
test_name=`must_env_val "${env}" 'bench.sysbench.test-name'`
db=`must_env_val "${env}" 'bench.sysbench.db'`

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`
pp=`env_val "${env}" 'mysql.pwd'`

log="${session}/sysbench.`date +%s`.log"
echo "bench.run.log=${log}" >> "${session}/env"

extra_opts=""
if [[ ! `sysbench --version | awk '{print $2}'` < '1.1.0' ]]; then
    extra_opts="--thread-init-timeout=1800"
fi

sysbench \
	--mysql-host="${host}" \
	--mysql-port="${port}" \
	--mysql-user="${user}" \
	--mysql-password="${pp}" \
	--mysql-db="${db}" \
	--time="${duration}" \
	--threads="${threads}" \
	--report-interval=10 \
	--db-driver=mysql \
	--tables="${tables}" \
	--table-size="${table_size}" \
    ${extra_opts} \
	"${test_name}" run | tee "${log}"

score=`parse_sysbench_events "${log}"`
parse_sysbench_detail "${log}" | sed 's/ /,/g' | tee "${log}.summary"

echo "bench.run.score=${score}" >> "${session}/env"
