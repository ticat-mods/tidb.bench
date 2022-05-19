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
gen_pwd=`to_true "${6}"`
if [ "${gen_pwd}" == 'true' ]; then
	init=' --init'
else
	init=''
fi

plain=' --format=plain'

py=`must_env_val "${env}" 'sys.ext.exec.py'`

yaml="${session}/meta-db-local.yaml"

function setup_env()
{
	local cluster="${1}"
	if [ -z "${2+x}" ]; then
		local write_pwd='false'
		local pp=''
	else
		local write_pwd='true'
		local pp="${2}"
	fi

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

	if [ "${write_pwd}" == 'true' ]; then
		echo "bench.meta.pwd=${pp}" >> "${env_file}"
		echo "bench.meta.pwd=***"
	fi
}

exist=`cluster_exist "${cluster}"`
if [ "${exist}" != 'false' ]; then
	echo "[:)] cluster name '${cluster}' exists, skipped"
	setup_env "${cluster}"
	exit
fi

echo -e "deploy.host.tikv=${host}\ndeploy.host.pd=${host}\ndeploy.host.tidb=${host}\ndeploy.port.delta=${port}" | \
	PYTHONPATH='../../helper/python.helper' "${py}" '../../helper/tiup.helper/topology.py' | tee "${yaml}"
echo
echo "${yaml}"

tiup cluster${plain} deploy "${cluster}" "${ver}" "${yaml}" --yes

log="${session}/meta-tiup-cluster-start-log.${RANDOM}"
tiup cluster${plain} start "${cluster}"${init} | tee "${log}"
if [ ! -z "${init}" ]; then
	pp=`cat "${log}" | { grep 'The new password is' || test $? = 1; } | awk -F "'" '{print $2}'`
else
	pp=''
fi
rm -f "${log}"

setup_env "${cluster}" "${pp}"
