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

bench_record_prepare "${host}" "${port}" "${user}" "${db}"

cat "${summary}" | grep -v ERR | while read line; do
	fields=(${line})
	section="${fields[0]}"
	keys=(`echo "${fields[1]}" | tr ',' ' '`)
	vals=(`echo "${fields[2]}" | tr ',' ' '`)
	for (( i = 0; i < ${#fields[@]}; i++ )); do
		bench_record_write "${host}" "${port}" "${user}" "${db}" "${env}" "${section}" "${keys[i]}" "${vals[i]}"
	done
done

bench_record_write_finish "${host}" "${port}" "${user}" "${db}" "${env}"

bench_record_show "${host}" "${port}" "${user}" "${db}"
