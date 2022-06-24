set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

env_file="${1}/env"
bt_prepare "${env_file}"
record_prepare "${env_file}"

res_title='ResourceUsage'

tidb_cpu_agg=`bt_aggregate 'irate(process_cpu_seconds_total{job="tidb"}[30s])'`
if [ ! -z "${tidb_cpu_agg}" ]; then
	tidb_cpu_agg=(${tidb_cpu_agg})
	record_write "${res_title}" 'tidb.cpu.avg.cores' "${tidb_cpu_agg[0]}" 'avg' '2' '0'
	record_write "${res_title}" 'tidb.cpu.max.cores' "${tidb_cpu_agg[1]}" 'max' '3' '0'
fi

tikv_cpu_agg=`bt_aggregate 'irate(process_cpu_seconds_total{job="tikv"}[30s])'`
if [ ! -z "${tikv_cpu_agg}" ]; then
	tikv_cpu_agg=(${tikv_cpu_agg})
	record_write "${res_title}" 'tikv.cpu.avg.cores' "${tikv_cpu_agg[0]}" 'avg' '2' '0'
	record_write "${res_title}" 'tikv.cpu.max.cores' "${tikv_cpu_agg[1]}" 'max' '3' '0'
fi

pd_cpu_agg=`bt_aggregate 'irate(process_cpu_seconds_total{job=~".*pd.*"}[30s])'`
if [ ! -z "${pd_cpu_agg}" ]; then
	pd_cpu_agg=(${pd_cpu_agg})
	record_write "${res_title}" 'pd.cpu.avg.cores' "${pd_cpu_agg[0]}" 'avg' '2' '0'
	record_write "${res_title}" 'pd.cpu.max.cores' "${pd_cpu_agg[1]}" 'max' '3' '0'
fi

tidb_mem_agg=`bt_aggregate 'process_resident_memory_bytes{job="tidb"}'`
if [ ! -z "${tidb_mem_agg}" ]; then
	tidb_mem_agg=(${tidb_mem_agg})
	record_write "${res_title}" 'tidb.mem.avg.mb' `to_mb "${tidb_mem_agg[0]}"` 'avg' '2' '0'
	record_write "${res_title}" 'tidb.mem.max.mb' `to_mb "${tidb_mem_agg[1]}"` 'max' '3' '0'
fi

tikv_mem_agg=`bt_aggregate 'process_resident_memory_bytes{job="tikv"}'`
if [ ! -z "${tikv_mem_agg}" ]; then
	tikv_mem_agg=(${tikv_mem_agg})
	record_write "${res_title}" 'tikv.mem.avg.mb' `to_mb "${tikv_mem_agg[0]}"` 'avg' '2' '0'
	record_write "${res_title}" 'tikv.mem.max.mb' `to_mb "${tikv_mem_agg[1]}"` 'max' '3' '0'
fi

# TODO: unused yet
tidb_max_procs=(`bt_aggregate 'tidb_server_maxprocs{job="tidb"}'`)

echo "[:)] bench resouce-usages are recorded"
