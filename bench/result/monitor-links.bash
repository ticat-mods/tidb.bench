set -euo pipefail
here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../../helper/helper.bash"

env=`cat "${1}/env"`
shift

id="${1}"
if [ -z "${id}" ]; then
	echo "[:(] arg 'record-id' is empty"
	exit 1
fi
if [ `is_number "${id}"` != 'true' ]; then
	echo "[:(] arg 'record-id' value is '${id}', not a number"
	exit 1
fi

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

query="SELECT monitor, UNIX_TIMESTAMP(run_id) AS begin, UNIX_TIMESTAMP(end_ts) AS end FROM bench_meta WHERE id=${id}"
info=`my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "${query}" 'tab' | { grep -v 'monitor' || test $? = 1; }`
if [ -z "${info}" ]; then
	echo "[:(] info not found for record '${id}'" >&2
	exit 1
fi

addr=`echo "${info}" | awk '{print $1}'`
begin=`echo "${info}" | awk '{print $2}'`
end=`echo "${info}" | awk '{print $3}'`

time_range="?from=${begin}000&to=${end}000"

echo "Overview:      http://${addr}/d/eDbRZpnWk/${time_range}"
echo
echo "PD:            http://${addr}/d/Q6RuHYIWk/${time_range}"
echo "TiDB Summary:  (dynamic address)"
echo "TiKV Summary:  http://${addr}/d/X7VQmEzZk/${time_range}"
echo
echo "Backup Import: http://${addr}/d/AzvioWLWz/${time_range}"
echo "Node Export:   http://${addr}/d/000000001/${time_range}"
echo
echo "TiDB:          http://${addr}/d/000000011/${time_range}"
echo "TiDB Runtime:  http://${addr}/d/000000013/${time_range}"
echo "TiKV Details:  http://${addr}/d/RDVQiEzZz/${time_range}"
echo
echo "Perf Write:    http://${addr}/d/Fcw5wqcWk/${time_range}"
echo "Trouble Shoot: http://${addr}/d/Lg4wiEkZz/${time_range}"
echo "TiKV FastTune: http://${addr}/d/TiKVFastTune/${time_range}"
