set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
db=`must_env_val "${env}" 'bench.meta.db-name'`
summary=`must_env_val "${env}" 'bench.run.log'`".summary"

id=`bench_record_write_start "${host}" "${port}" "${user}" "${db}" 'sysbench' "${env}"`
test_name=`must_env_val "${env}" 'bench.sysbench.test-name'`

fields=(`cat "${summary}"`)
keys=(`echo "${fields[0]}" | tr ',' ' '`)
vals=(`echo "${fields[1]}" | tr ',' ' '`)
for (( i = 0; i < ${#keys[@]}; i++ )); do
	agg_action=`sysbench_result_agg_action "${keys[i]}"`
	verb_level=`sysbench_result_verb_level "${keys[i]}"`
	bench_record_write "${host}" "${port}" "${user}" "${db}" "${id}" "${test_name}" "${keys[i]}" "${vals[i]}" \
		"${agg_action}" "${verb_level}"
done

threads=`env_val "${env}" 'bench.sysbench.threads'`
if [ ! -z "${threads}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "threads=${threads}"
fi
duration=`env_val "${env}" 'bench.sysbench.duration'`
if [ ! -z "${duration}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "duration=${duration}"
fi
tables=`env_val "${env}" 'bench.sysbench.tables'`
if [ ! -z "${tables}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "tables=${tables}"
fi
table_size=`env_val "${env}" 'bench.sysbench.table-size'`
if [ ! -z "${table_size}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "table-size=${table_size}"
fi
bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "test=${test_name}"
bench_record_write_tags_from_env "${host}" "${port}" "${user}" "${db}" "${id}" "${env}"

bench_record_write_finish "${host}" "${port}" "${user}" "${db}" "${id}"
