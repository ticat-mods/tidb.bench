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
ca=`env_val "${env}" 'bench.meta.ca'`
summary=`must_env_val "${env}" 'bench.run.log'`".summary"

id=`env_val "${env}" 'bench.run.id'`
if [ -z "${id}" ]; then
	id=`bench_record_write_start "${host}" "${port}" "${user}" "${pp}" "${db}" 'ycsb' "${env}" "${ca}"`
	echo "bench.run.id=${id}" >> "${env_file}"
fi

summary=`ycsb_result_to_lines "${summary}" | sort -k 1,2`

echo "${summary}" | while read line; do
	if [ -z "${line}" ]; then
		continue
	fi
	fields=(${line})
	section="${fields[0]}"
	key="${fields[1]}"
	val="${fields[2]}"
	agg_action=`ycsb_result_agg_action "${key}"`
	verb_level=`ycsb_result_verb_level "${key}"`
	greater_is_good=`ycsb_result_gig "${key}"`
	bench_record_write "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "${section}" "${key}" "${val}" \
		"${agg_action}" "${verb_level}" "${greater_is_good}" "${ca}"
done

threads=`env_val "${env}" 'bench.ycsb.threads'`
if [ ! -z "${threads}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "threads-${threads}" "${ca}"
fi
count=`env_val "${env}" 'bench.ycsb.count'`
if [ ! -z "${count}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "count-${count}" "${ca}"
fi
bs=`env_val "${env}" 'bench.ycsb.batch-size'`
if [ ! -z "${bs}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "batch-size-${bs}" "${ca}"
fi
cc=`env_val "${env}" 'bench.ycsb.conn-count'`
if [ ! -z "${cc}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "conn-count-${cc}" "${ca}"
fi
sld=`env_val "${env}" 'bench.ycsb.scan-length-distribution'`
if [ ! -z "${sld}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "dist-${sld}" "${ca}"
fi

bench_record_write_finish "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "${ca}"
