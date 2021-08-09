set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

wh=`must_env_val "${env}" 'bench.tpcc.warehouses'`
echo "bench.workload.tag=wh-${wh}" >> "${env_file}"
