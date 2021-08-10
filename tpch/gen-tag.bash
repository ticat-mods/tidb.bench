set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

sf=`must_env_val "${env}" 'bench.tpch.scale-factor'`
echo "bench.workload.tag=sf-${sf}" >> "${env_file}"
