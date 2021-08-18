set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

session="${1}"
env=`cat "${session}/env"`

## Args handling
#
workload=`must_env_val "${env}" 'bench.workload'`

run_begin=`must_env_val "${env}" 'bench.run.begin'`
run_end=`must_env_val "${env}" 'bench.run.end'`
version=`must_env_val "${env}" 'tidb.version'`
threads=`must_env_val "${env}" "bench.${workload}.threads"`
score=`must_env_val "${env}" 'bench.run.score'`

keys=`must_env_val "${env}" 'bench.tag-from-keys'`
tag=`gen_tag "${keys}" 'false'`
echo "bench.tag=${tag}" >> "${session}/env"

bench_begin=`env_val "${env}" 'bench.begin'`
if [ -z "${bench_begin}" ]; then
	bench_begin='0'
fi

## Write the text record, in case no meta db
#
echo -e "${score}\tworkload=${workload},run_begin=${run_begin},run_end=${run_end},version=${version},threads=${threads}" >> "${session}/scores"

host=`env_val "${env}" 'bench.meta.host'`
if [ -z "${host}" ]; then
	echo "[:-] no bench.meta.host in env, skipped" >&2
	exit
fi

## Write the record tables if has meta db
#
port=`must_env_val "${env}" 'bench.meta.port'`
db=`must_env_val "${env}" 'bench.meta.db-name'`

function my_exe()
{
	local query="${1}"
	mysql -h "${host}" -P "${port}" -u root --database="${db}" -e "${query}"
}

mysql -h "${host}" -P "${port}" -u root -e "CREATE DATABASE IF NOT EXISTS ${db}"

function write_record()
{
	local table="${1}"

	my_exe "CREATE TABLE IF NOT EXISTS ${table} (   \
		score DECIMAL(10,2),                        \
		version VARCHAR(32),                        \
		threads INT(11),                            \
		workload VARCHAR(64),                       \
		bench_begin TIMESTAMP,                      \
		run_begin TIMESTAMP,                        \
		run_end TIMESTAMP,                          \
		tag VARCHAR(512),                           \
		PRIMARY KEY(                                \
			workload,                               \
			tag,                                    \
			bench_begin,                            \
			run_begin                               \
		)                                           \
	)                                               \
	"

	my_exe "INSERT INTO ${table} VALUES(            \
		${score},                                   \
		\"${version}\",                             \
		${threads},                                 \
		\"${workload}\",                            \
		FROM_UNIXTIME(${bench_begin}),              \
		FROM_UNIXTIME(${run_begin}),                \
		FROM_UNIXTIME(${run_end}),                  \
		\"${tag}\"                                  \
	)                                               \
	"
}

# The main score table
write_record 'scores'
# The detail table, other mods may alter(add cols) it
write_record 'detail'
