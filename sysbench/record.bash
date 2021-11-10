set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

# The meta db to create table and insert any records we want
meta_host=`env_val "${env}" 'bench.meta.host'`
if [ -z "${meta_host}" ]; then
	echo "[:-] env 'bench.meta.host' is empty, skipped" >&2
	exit
fi
meta_port=`must_env_val "${env}" 'bench.meta.port'`
meta_db=`must_env_val "${env}" 'bench.meta.db-name'`
meta_user=`must_env_val "${env}" 'bench.meta.user'`

# The context of one bench
bench_tag=`env_val "${env}" 'bench.tag'`
bench_begin=`env_val "${env}" 'bench.begin'`
workload='sysbench'

# The context of one run
run_begin=`env_val "${env}" 'bench.run.begin'`
if [ -z "${run_begin}" ]; then
	echo "[:-] env 'bench.run.begin' is empty, skipped" >&2
	exit
fi
run_end=`must_env_val "${env}" 'bench.run.end'`
run_log=`must_env_val "${env}" 'bench.run.log'`

detail=(`must_env_val "${env}" 'bench.sysbench.detail'`)
score=`must_env_val "${env}" 'bench.run.score'`
tag=`env_val "${env}" 'bench.tag'`

## Write the record tables if has meta db
#
function my_exe()
{
	local query="${1}"
	mysql -h "${meta_host}" -P "${meta_port}" -u "${meta_user}" --database="${meta_db}" -e "${query}"
}

mysql -h "${meta_host}" -P "${meta_port}" -u "${meta_user}" -e "CREATE DATABASE IF NOT EXISTS ${meta_db}"

function write_record()
{
	local table="${1}"

	my_exe "CREATE TABLE IF NOT EXISTS ${table} (   \
		score DECIMAL(10,2),                        \
		bench_begin TIMESTAMP,                      \
		run_begin TIMESTAMP,                        \
		qps DECIMAL(16,2),                          \
		tps DECIMAL(16,2),                          \
		min DECIMAL(16,2),                          \
		avg DECIMAL(16,2),                          \
		p95 DECIMAL(16,2),                          \
		max DECIMAL(16,2),                          \
		tag VARCHAR(512),                           \
		PRIMARY KEY(                                \
			bench_begin,                            \
			run_begin                               \
		)                                           \
	)                                               \
	"

	my_exe "INSERT INTO ${table} (                  \
		score, bench_begin, run_begin,              \
		${detail[0]}, tag                            \
	)                   				            \
		VALUES (                                    \
		${score},                                   \
		FROM_UNIXTIME(${bench_begin}),              \
		FROM_UNIXTIME(${run_begin}),                \
		${detail[1]},                                \
		\"${tag}\"                                  \
	)                                               \
	"
}

write_record 'sysbench'
