set -euo pipefail

. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
shift

tags="${1}"
echo "bench.tag.random.${RANDOM}=${tags}" | tee -a "${env_file}"
