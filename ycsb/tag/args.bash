set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

tag=''

function append()
{
	local name="${1}"
	local key="${2}"
	local val=`env_val "${env}" "${key}"`
	if [ ! -z "${val}" ]; then
		tag="${tag}-${name}${val}"
		echo $tag
	fi
}

ycsb_workload=`env_val "${env}" 'bench.ycsb.workload'`
if [ -z "${ycsb_workload}" ]; then
    append 'b' 'bench.ycsb.batch-size'
    append 'n' 'bench.ycsb.count'
    append 't' 'bench.ycsb.conn-count'
    append 'i' 'bench.ycsb.isolation'
    append 'rd' 'bench.ycsb.request-distribution'
    append 'rp' 'bench.ycsb.read-proportion'
    append 'ip' 'bench.ycsb.insert-proportion'
    append 'up' 'bench.ycsb.update-proportion'
    append 'sp' 'bench.ycsb.scan-proportion'
    append 'rmw' 'bench.ycsb.read-modify-write-proportion'
else
    tag="${ycsb_workload}"
    append 'n' 'bench.ycsb.record-count'
    append 't' 'bench.ycsb.threads'
    append 'ic' 'bench.ycsb.insert-count'
    append 'oc' 'bench.ycsb.operation-count'
fi

tag="${tag:1}"

echo "workload.tag.args=${tag}" >> "${env_file}"
