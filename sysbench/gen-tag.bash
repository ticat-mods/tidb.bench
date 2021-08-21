set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

test_name=`must_env_val "${env}" 'bench.sysbench.test-name'`
tables=`must_env_val "${env}" 'bench.sysbench.tables'`
table_size=`must_env_val "${env}" 'bench.sysbench.table-size'`

tag="${test_name}-tb=${tables}-ts=${table_size}"

soft_tag=''
threads=`env_val "${env}" 'bench.sysbench.threads'`
if [ ! -z "${threads}" ]; then
	soft_tag="${soft_tag}-t=${threads}"
fi
duration=`env_val "${env}" 'bench.sysbench.duration'`
if [ ! -z "${duration}" ]; then
	soft_tag="${soft_tag}-t=${duration}"
fi

if [ ! -z "${soft_tag}" ]; then
	tag="${tag}+${soft_tag}"
fi
echo "bench.workload.tag=${tag}" >> "${env_file}"
