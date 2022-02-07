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

id=`bench_record_write_start "${host}" "${port}" "${user}" "${db}" 'tpcc' "${env}"`

cat "${summary}" | grep -v ERR | while read line; do
	fields=(${line})
	section="${fields[0]}"
	keys=(`echo "${fields[1]}" | tr ',' ' '`)
	vals=(`echo "${fields[2]}" | tr ',' ' '`)
	for (( i = 0; i < ${#keys[@]}; i++ )); do
		agg_action=`tpcc_result_agg_action "${keys[i]}"`
		verb_level=`tpcc_result_verb_level "${section}" "${keys[i]}"`
		bench_record_write "${host}" "${port}" "${user}" "${db}" "${id}" "${section}" "${keys[i]}" "${vals[i]}" \
			"${agg_action}" "${verb_level}"
	done
done

threads=`env_val "${env}" 'bench.tpcc.threads'`
if [ ! -z "${threads}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "threads=${threads}"
fi
duration=`env_val "${env}" 'bench.tpcc.duration'`
if [ ! -z "${duration}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "duration=${duration}"
fi
warehouses=`env_val "${env}" 'bench.tpcc.warehouses'`
if [ ! -z "${warehouses}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "warehouses=${warehouses}"
fi
bench_record_write_tags_from_env "${host}" "${port}" "${user}" "${db}" "${id}" "${env}"

bench_record_write_finish "${host}" "${port}" "${user}" "${db}" "${id}"
