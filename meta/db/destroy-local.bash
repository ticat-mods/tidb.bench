set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

name="${1}"

exist=`cluster_exist "${name}"`
if [ "${exist}" == 'false' ]; then
	echo "[:-] cluster name '${name}' not exists" >&2
	exit
fi

tiup cluster --format=plain --yes destroy "${name}"
