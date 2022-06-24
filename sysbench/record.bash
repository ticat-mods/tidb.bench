set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

host=`must_env_val "${env}" 'bench.meta.host'`
port=`must_env_val "${env}" 'bench.meta.port'`
user=`must_env_val "${env}" 'bench.meta.user'`
pp=`env_val "${env}" 'bench.meta.pwd'`
db=`must_env_val "${env}" 'bench.meta.db-name'`
summary=`must_env_val "${env}" 'bench.run.log'`".summary"

id=`env_val "${env}" 'bench.run.id'`
if [ -z "${id}" ]; then
	id=`bench_record_write_start "${host}" "${port}" "${user}" "${pp}" "${db}" 'sysbench' "${env}"`
	echo "bench.run.id=${id}" >> "${env_file}"
fi

test_name=`must_env_val "${env}" 'bench.sysbench.test-name'`

fields=(`cat "${summary}"`)
keys=(`echo "${fields[0]}" | tr ',' ' '`)
vals=(`echo "${fields[1]}" | tr ',' ' '`)
for (( i = 0; i < ${#keys[@]}; i++ )); do
	agg_action=`sysbench_result_agg_action "${keys[i]}"`
	verb_level=`sysbench_result_verb_level "${keys[i]}"`
	greater_is_good=`sysbench_result_gig "${keys[i]}"`
	bench_record_write "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "${test_name}" "${keys[i]}" "${vals[i]}" \
		"${agg_action}" "${verb_level}" "${greater_is_good}"
done

threads=`env_val "${env}" 'bench.sysbench.threads'`
if [ ! -z "${threads}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "threads-${threads}"
fi
duration=`env_val "${env}" 'bench.sysbench.duration'`
if [ ! -z "${duration}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "duration-${duration}"
fi
tables=`env_val "${env}" 'bench.sysbench.tables'`
if [ ! -z "${tables}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "tables-${tables}"
fi
table_size=`env_val "${env}" 'bench.sysbench.table-size'`
if [ ! -z "${table_size}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "table-size-${table_size}"
fi
bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "${test_name}"

bench_record_write_finish "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}"
