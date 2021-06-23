set -euo pipefail

env_file="${1}/env"
env=`cat "${env_file}"`

here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/base.bash" "${env}" "${here}"

wh=`env_val 'bench.tpcc.warehouses'`
echo -e "tidb.backup.tag\ttpcc-${wh}" >> "${env_file}"
