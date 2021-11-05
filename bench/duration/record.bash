set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`
shift

## Args handling
#
event="${1}"
if [ -z "${event}" ]; then
	echo "[:(] arg 'event' is empty" >&2
	exit 1
fi

tag=`env_val "${env}" "bench.tag"`

event_begin=`must_env_val "${env}" "${event}.begin"`
event_end=`must_env_val "${env}" "${event}.end"`

dur=$((event_end - event_begin))

## Write the text record, in case no meta db
#
echo -e "${dur}\tevent=${event},begin=${event_begin},end=${event_end}" >> "${session}/durations"

## Write the record tables if has meta db
#
host=`env_val "${env}" 'bench.meta.host'`
if [ -z "${host}" ]; then
	echo "[:-] no bench.meta.host in env, skipped" >&2
	exit
fi

port=`must_env_val "${env}" 'bench.meta.port'`
db=`must_env_val "${env}" 'bench.meta.db-name'`
user=`must_env_val "${env}" 'bench.meta.user'`

function my_exe()
{
	local query="${1}"
	mysql -h "${host}" -P "${port}" -u "${user}" --database="${db}" -e "${query}"
}

mysql -h "${host}" -P "${port}" -u "${user}" -e "CREATE DATABASE IF NOT EXISTS ${db}"

function write_record()
{
	local table="${1}"

	my_exe "CREATE TABLE IF NOT EXISTS ${table} (   \
		event VARCHAR(64),                          \
		duration_sec INT(11),                       \
		begin TIMESTAMP,                            \
		end TIMESTAMP,                              \
		tag VARCHAR(512),                           \
		PRIMARY KEY(                                \
			event,                                  \
			tag,                                    \
			begin                                   \
		)                                           \
	)                                               \
	"

	my_exe "INSERT INTO ${table} VALUES(            \
		\"${event}\",                               \
		${dur},                                     \
		FROM_UNIXTIME(${event_begin}),              \
		FROM_UNIXTIME(${event_end}),                \
		\"${tag}\"                                  \
	)                                               \
	"
}

write_record 'durations'
