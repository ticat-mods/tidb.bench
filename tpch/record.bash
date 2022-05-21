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

id=`bench_record_write_start "${host}" "${port}" "${user}" "${pp}" "${db}" 'tpch' "${env}"`
echo "bench.run.id=${id}" >> "${env_file}"

lines=`tpch_result_read_from_file "${summary}" | sort -n`
agg_action='AVG'
verb_level=1
greater_is_good=0
echo "${lines}" | while read line; do
	kv=(${line})
	bench_record_write "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "benchmark(s)" "${kv[0]}" "${kv[1]}" \
		"${agg_action}" "${verb_level}" "${greater_is_good}"
done

threads=`env_val "${env}" 'bench.tpch.threads'`
if [ ! -z "${threads}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "threads-${threads}"
fi
duration=`env_val "${env}" 'bench.tpch.duration'`
if [ ! -z "${duration}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "duration-${duration}"
fi
sf=`env_val "${env}" 'bench.tpch.scale-factor'`
if [ ! -z "${sf}" ]; then
	bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "scale-factor-${sf}"
fi
tiflash=`env_val "${env}" 'bench.tpch.tiflash'`
if [ ! -z "${tiflash}" ]; then
	tiflash=`to_true "${tiflash}"`
	if [ "${tiflash}" == 'true' ]; then
		bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" 'with-tiflash'
	fi
fi
bench_record_write_tags_from_env "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "${env}"

bench_record_write_finish "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}"
