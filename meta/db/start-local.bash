set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`
shift

port="${1}"
ver="${2}"
db="${3}"
cluster="${4}"
host="${5}"

py=`must_env_val "${env}" 'sys.ext.exec.py'`

yaml="${session}/meta-db-local.yaml"

exist=`cluster_exist "${cluster}"`
if [ "${exist}" != 'false' ]; then
	echo "[:)] cluster name '${cluster}' exists, skipped"
	exit
fi

echo -e "deploy.host.tikv=${host}@${port}\ndeploy.host.pd=${host}@${port}\ndeploy.host.tidb=${host}@${port}\ndeploy.port.delta=${port}" | \
	PYTHONPATH='../../helper/python.helper' "${py}" '../../helper/tiup.helper/topology.py' | tee "${yaml}"
echo
echo "${yaml}"

tiup cluster --format=plain deploy "${cluster}" "${ver}" "${yaml}" --yes
tiup cluster --format=plain start "${cluster}"
