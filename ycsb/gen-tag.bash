set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

tag=''

function append()
{
	local key="${1}"
	local name="${2}"
	local val=`env_val "${env}" "${key}"`
	if [ ! -z "${key}" ]; then
		tag="${tag}-${name}=${val}"
	fi
}

append 'bs' 'bench.ycsb.batch-size'
append 'cnt' 'bench.ycsb.count'
append 'cc' 'bench.ycsb.conn-count'
append 'iso' 'bench.ycsb.isolation'
append 'rd' 'bench.ycsb.request-distribution'
append 'rp' 'bench.ycsb.read-proportion'
append 'ip' 'bench.ycsb.insert-proportion'
append 'up' 'bench.ycsb.update-proportion'
append 'sp' 'bench.ycsb.scan-proportion'
append 'rmwp' 'bench.ycsb.read-modify-write-proportion'

tag="ycsb+${tag}"

echo "bench.workload.tag=${tag}" >> "${env_file}"
