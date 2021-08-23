set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

test_name=`must_env_val "${env}" 'bench.sysbench.test-name'`
test_name=`sysbench_short_name "${test_name}"`

tables=`must_env_val "${env}" 'bench.sysbench.tables'`
table_size=`must_env_val "${env}" 'bench.sysbench.table-size'`

tag="${test_name}-t${tables}-s${table_size}"
echo "workload.tag.data=${tag}" >> "${env_file}"
