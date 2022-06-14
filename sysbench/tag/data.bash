set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

tables=`must_env_val "${env}" 'bench.sysbench.tables'`
table_size=`must_env_val "${env}" 'bench.sysbench.table-size'`

tag="tb${tables}-ts${table_size}"
echo "tidb.data.tag=${tag}" >> "${env_file}"
