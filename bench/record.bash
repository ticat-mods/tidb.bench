set -euo pipefail

. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/bench-toolset.bash"

session="${1}"
env_file="${session}/env"
env=`cat "${env_file}"`
shift 4

bt_repo_addr="${1}"
bt_download_token="${2}"

name=`must_env_val "${env}" 'tidb.cluster'`
url='http://'`must_prometheus_addr "${name}"`

begin=`must_env_val "${env}" 'bench.run.begin'`'000'
end=`must_env_val "${env}" 'bench.run.end'`'000'
id=`must_env_val "${env}" 'bench.run.id'`

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
tidb_max_procs=(`metrics_aggregate "${bt}" 'tidb_server_maxprocs{job="tidb"}'`)

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

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

write_record 'Jitters' 'qps.jt.sd'      "${qps_jt[0]}" 'avg' '1' '0'
write_record 'Jitters' 'qps.jt.pos.max' "${qps_jt[1]}" 'max' '3' '0'
write_record 'Jitters' 'qps.jt.neg.max' "${qps_jt[2]}" 'min' '1' '0'

write_record 'Jitters' 'lat95.jt.sd'      "${lat95_jt[0]}" 'avg' '2' '0'
write_record 'Jitters' 'lat95.jt.pos.max' "${lat95_jt[1]}" 'max' '4' '0'
write_record 'Jitters' 'lat95.jt.neg.max' "${lat95_jt[2]}" 'min' '2' '1'

write_record 'Jitters' 'lat99.jt.sd'      "${lat99_jt[0]}" 'avg' '1' '1'
write_record 'Jitters' 'lat99.jt.pos.max' "${lat99_jt[1]}" 'max' '3' '0'
write_record 'Jitters' 'lat99.jt.neg.max' "${lat99_jt[2]}" 'min' '1' '1'

write_record 'Jitters' 'lat999.jt.sd'      "${lat999_jt[0]}" 'avg' '2' '1'
write_record 'Jitters' 'lat999.jt.pos.max' "${lat999_jt[1]}" 'max' '4' '0'
write_record 'Jitters' 'lat999.jt.neg.max' "${lat999_jt[2]}" 'min' '2' '1'

write_record 'ResUsage' 'tidb.cpu.avg' "${tidb_cpu_agg[0]}" 'avg' '1' '0'
write_record 'ResUsage' 'tidb.cpu.max' "${tidb_cpu_agg[1]}" 'max' '9' '0'
write_record 'ResUsage' 'tidb.mem.avg' "${tidb_mem_agg[0]}" 'avg' '1' '0'
write_record 'ResUsage' 'tidb.mem.max' "${tidb_mem_agg[1]}" 'max' '9' '0'

write_record 'ResUsage' 'tidb.max.procs' "${tidb_max_procs[1]}" 'max' '9' '0'

echo "[:)] bench jitters and resouce-usages are recorded"
