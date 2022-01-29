set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

session="${1}"
env_file="${session}/env"
env=`cat "${env_file}"`
shift

port="${1}"
ver="${2}"
db="${3}"
cluster="${4}"
host="${5}"

py=`must_env_val "${env}" 'sys.ext.exec.py'`

yaml="${session}/meta-db-local.yaml"

function setup_env()
{
	local cluster="${1}"
	local tidb=`cluster_tidbs "${cluster}" | head -n 1`
	if [ -z "${tidb}" ]; then
		echo "[:(] can't get tidb address from cluster '${cluster}'" >&2
		exit 1
	fi
	local host=`echo "${tidb}" | awk -F ':' '{print $1}'`
	local port=`echo "${tidb}" | awk -F ':' '{print $2}'`
	echo "bench.meta.host=${host}" | tee -a "${env_file}"
	echo "bench.meta.port=${port}" | tee -a "${env_file}"
	echo "bench.meta.user=root" | tee -a "${env_file}"
}

exist=`cluster_exist "${cluster}"`
if [ "${exist}" != 'false' ]; then
	echo "[:)] cluster name '${cluster}' exists, skipped"
	setup_env "${cluster}"
	exit
fi

echo -e "deploy.host.tikv=${host}@${port}\ndeploy.host.pd=${host}@${port}\ndeploy.host.tidb=${host}@${port}\ndeploy.port.delta=${port}" | \
	PYTHONPATH='../../helper/python.helper' "${py}" '../../helper/tiup.helper/topology.py' | tee "${yaml}"
echo
echo "${yaml}"

tiup cluster --format=plain deploy "${cluster}" "${ver}" "${yaml}" --yes
tiup cluster --format=plain start "${cluster}"

setup_env "${cluster}"
