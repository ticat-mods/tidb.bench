set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

env_file="${1}/env"
bt_prepare "${env_file}"
record_prepare "${env_file}"

jt_title='Jitters(1=100%)'

qps_jt=`bt_jitter 'sum(rate(tidb_executor_statement_total{}[1m]))'`
if [ ! -z "${qps_jt}" ]; then
	qps_jt=(${qps_jt})
	record_write "${jt_title}" 'qps.sdev' "${qps_jt[0]}" 'avg' '2' '0'
	record_write "${jt_title}" 'qps.+max' "${qps_jt[1]}" 'max' '4' '-1'
	record_write "${jt_title}" 'qps.-max' "${qps_jt[2]}" 'min' '2' '1'
fi

lat95_jt=`bt_jitter 'histogram_quantile(0.95, sum(rate(tidb_server_handle_query_duration_seconds_bucket{}[1m])) by (le, instance))'`
if [ ! -z "${lat95_jt}" ]; then
	lat95_jt=(${lat95_jt})
	record_write "${jt_title}" 'p95.sdev' "${lat95_jt[0]}" 'avg' '3' '0'
	record_write "${jt_title}" 'p95.+max' "${lat95_jt[1]}" 'max' '5' '-1'
	record_write "${jt_title}" 'p95.-max' "${lat95_jt[2]}" 'min' '3' '1'
fi

lat99_jt=`bt_jitter 'histogram_quantile(0.99, sum(rate(tidb_server_handle_query_duration_seconds_bucket{}[1m])) by (le, instance))'`
if [ ! -z "${lat99_jt}" ]; then
	lat99_jt=(${lat99_jt})
	record_write "${jt_title}" 'p99.sdev' "${lat99_jt[0]}" 'avg' '2' '0'
	record_write "${jt_title}" 'p99.+max' "${lat99_jt[1]}" 'max' '4' '-1'
	record_write "${jt_title}" 'p99.-max' "${lat99_jt[2]}" 'min' '2' '1'
fi

lat999_jt=`bt_jitter 'histogram_quantile(0.999, sum(rate(tidb_server_handle_query_duration_seconds_bucket{}[1m])) by (le, instance))'`
if [ ! -z "${lat999_jt}" ]; then
	lat999_jt=(${lat999_jt})
	record_write "${jt_title}" 'p999.sdev' "${lat999_jt[0]}" 'avg' '3' '0'
	record_write "${jt_title}" 'p999.+max' "${lat999_jt[1]}" 'max' '5' '-1'
	record_write "${jt_title}" 'p999.-max' "${lat999_jt[2]}" 'min' '3' '1'
fi

echo "[:)] bench jitters are recorded"
