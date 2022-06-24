set -euo pipefail

. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
shift

tags="${1}"
if [ -z "${tags}" ]; then
	echo "[:-] arg 'tags' is empty, skipped" >&2
	exit
fi
echo "bench.tag.random.${RANDOM}=${tags}" | tee -a "${env_file}"
