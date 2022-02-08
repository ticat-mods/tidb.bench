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

id=`bench_record_write_start "${host}" "${port}" "${user}" "${db}" 'ycsb' "${env}"`

cat "${summary}" | while read line; do
	fields=(${line})
	section="${fields[0]}"
	keys=(`echo "${fields[1]}" | tr ',' ' '`)
	vals=(`echo "${fields[2]}" | tr ',' ' '`)
	for (( i = 0; i < ${#keys[@]}; i++ )); do
		agg_action=`ycsb_result_agg_action "${keys[i]}"`
		verb_level=`ycsb_result_verb_level "${keys[i]}"`
		bench_record_write "${host}" "${port}" "${user}" "${db}" "${id}" "${section}" "${keys[i]}" "${vals[i]}" \
			"${agg_action}" "${verb_level}"
	done
done

threads=`env_val "${env}" 'bench.ycsb.threads'`
if [ ! -z "${threads}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "threads=${threads}"
fi
count=`env_val "${env}" 'bench.ycsb.count'`
if [ ! -z "${count}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "count=${count}"
fi
bs=`env_val "${env}" 'bench.ycsb.batch-size'`
if [ ! -z "${bs}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "batch-size=${bs}"
fi
cc=`env_val "${env}" 'bench.ycsb.conn-count'`
if [ ! -z "${cc}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "conn-count=${cc}"
fi
sld=`env_val "${env}" 'bench.ycsb.scan-length-distribution'`
if [ ! -z "${sld}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "dist=${sld}"
fi
bench_record_write_tags_from_env "${host}" "${port}" "${user}" "${db}" "${id}" "${env}"

bench_record_write_finish "${host}" "${port}" "${user}" "${db}" "${id}"
