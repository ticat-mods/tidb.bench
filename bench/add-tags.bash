set -euo pipefail

. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
shift

tags="${1}"
if [ -z "${tags}" ]; then
	echo "[:-] arg 'tags' is empty, skipped" >&2
	exit
fi

group="${2}"
if [ -z "${group}" ]; then
	group="random.${RANDOM}"
fi

echo "bench.tag.${group}=${tags}" | tee -a "${env_file}"
