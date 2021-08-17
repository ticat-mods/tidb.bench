set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

tables=`must_env_val "${env}" 'bench.sysbench.tables'`
table_size=`must_env_val "${env}" 'bench.sysbench.table-size'`
test_name=`must_env_val "${env}" 'bench.sysbench.test-name'`
echo "bench.workload.tag=${test_name}-tb-${tables}-ts-${table_size}" >> "${env_file}"
