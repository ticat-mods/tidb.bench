set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

threads=`must_env_val "${env}" 'bench.tpcc.threads'`
duration=`must_env_val "${env}" 'bench.tpcc.duration'`
wh=`must_env_val "${env}" 'bench.tpcc.warehouses'`

tag="wh=${wh}-t=${threads}-dur=${duration}"

echo "bench.workload.tag=${tag}" >> "${env_file}"
