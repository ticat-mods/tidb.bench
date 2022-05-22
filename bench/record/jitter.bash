set -euo pipefail

. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/bench-toolset.bash"

session="${1}"
env_file="${session}/env"
env=`cat "${env_file}"`
shift 4

bt_repo_addr="${1}"
bt_download_token="${2}"

name=`must_env_val "${env}" 'tidb.cluster'`
url='http://'`must_prometheus_addr "${name}"`

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

begin=`must_env_val "${env}" 'bench.run.begin'`'000'
end=`must_env_val "${env}" 'bench.run.end'`'000'

id=`env_val "${env}" 'bench.run.id'`
if [ -z "${id}" ]; then
	workload=`must_env_val "${env}" 'bench.workload'`
	id=`bench_record_write_start "${host}" "${port}" "${user}" "${pp}" "${db}" "${workload}" "${env}"`
	echo "bench.run.id=${id}" >> "${env_file}"
fi

bt=`download_or_build_bin "${env}" "${bt_repo_addr}" 'bin/bench-toolset' 'make' "${bt_download_token}"`

lat95_jt=(`metrics_jitter "${bt}" 'histogram_quantile(0.95, sum(rate(tidb_server_handle_query_duration_seconds_bucket{}[1m])) by (le, instance))'`)
lat99_jt=(`metrics_jitter "${bt}" 'histogram_quantile(0.99, sum(rate(tidb_server_handle_query_duration_seconds_bucket{}[1m])) by (le, instance))'`)
lat999_jt=(`metrics_jitter "${bt}" 'histogram_quantile(0.999, sum(rate(tidb_server_handle_query_duration_seconds_bucket{}[1m])) by (le, instance))'`)

qps_jt=(`metrics_jitter "${bt}" 'sum(rate(tidb_executor_statement_total{}[1m])) by (type)'`)

if [ "${qps_jt[0]}" == 'NaN' ]; then
    qps_jt=('0' '0' '0')
fi

tidb_cpu_agg=(`metrics_aggregate "${bt}" 'irate(process_cpu_seconds_total{job="tidb"}[30s])'`)
tidb_mem_agg=(`metrics_aggregate "${bt}" 'process_resident_memory_bytes{job="tidb"}'`)

# TODO: unused yet
tidb_max_procs=(`metrics_aggregate "${bt}" 'tidb_server_maxprocs{job="tidb"}'`)

function write_record()
{
	local section="${1}"
	local key="${2}"
	local val="${3}"
	local agg_action="${4}"
	local verb_level="${5}"
	local greater_is_good="${6}"

	bench_record_write "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" \
		"${section}" "${key}" "${val}" "${agg_action}" "${verb_level}" "${greater_is_good}"
}

jt_title='Jitters(1=100%)'

write_record "${jt_title}" 'qps.sdev' "${qps_jt[0]}" 'avg' '1' '0'
write_record "${jt_title}" 'qps.+max' "${qps_jt[1]}" 'max' '3' '-1'
write_record "${jt_title}" 'qps.-max' "${qps_jt[2]}" 'min' '1' '1'

write_record "${jt_title}" 'p95.sdev' "${lat95_jt[0]}" 'avg' '2' '0'
write_record "${jt_title}" 'p95.+max' "${lat95_jt[1]}" 'max' '4' '-1'
write_record "${jt_title}" 'p95.-max' "${lat95_jt[2]}" 'min' '2' '1'

write_record "${jt_title}" 'p99.sdev' "${lat99_jt[0]}" 'avg' '1' '0'
write_record "${jt_title}" 'p99.+max' "${lat99_jt[1]}" 'max' '3' '-1'
write_record "${jt_title}" 'p99.-max' "${lat99_jt[2]}" 'min' '1' '1'

write_record "${jt_title}" 'p999.sdev' "${lat999_jt[0]}" 'avg' '2' '0'
write_record "${jt_title}" 'p999.+max' "${lat999_jt[1]}" 'max' '4' '-1'
write_record "${jt_title}" 'p999.-max' "${lat999_jt[2]}" 'min' '2' '1'

res_title='ResourceUsage'

write_record "${res_title}" 'tidb.cpu.avg.cores' "${tidb_cpu_agg[0]}" 'avg' '1' '0'
write_record "${res_title}" 'tidb.cpu.max.cores' "${tidb_cpu_agg[1]}" 'max' '2' '0'

write_record "${res_title}" 'tidb.mem.avg.bytes' "${tidb_mem_agg[0]}" 'avg' '1' '0'
write_record "${res_title}" 'tidb.mem.max.bytes' "${tidb_mem_agg[1]}" 'max' '2' '0'

echo "[:)] bench jitters and resouce-usages are recorded"