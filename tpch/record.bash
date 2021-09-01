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

# The context of one bench
bench_tag=`env_val "${env}" 'bench.tag'`
bench_begin=`env_val "${env}" 'bench.begin'`
workload='tpch'

# The context of one run
run_begin=`env_val "${env}" 'bench.run.begin'`
if [ -z "${run_begin}" ]; then
	echo "[:-] env 'bench.run.begin' is empty, skipped" >&2
	exit
fi
run_end=`must_env_val "${env}" 'bench.run.end'`
run_log=`must_env_val "${env}" 'bench.run.log'`
detail=(`must_env_val "${env}" 'bench.tpch.detail'`)
score=`must_env_val "${env}" 'bench.run.score'`

## Write the record tables if has meta db
#

function my_exe()
{
	local query="${1}"
	mysql -h "${meta_host}" -P "${meta_port}" -u root --database="${meta_db}" -e "${query}"
}

mysql -h "${meta_host}" -P "${meta_port}" -u root -e "CREATE DATABASE IF NOT EXISTS ${meta_db}"

function write_record()
{
	local table="${1}"

	my_exe "CREATE TABLE IF NOT EXISTS ${table} (   \
		score DECIMAL(10,2),                        \
		workload VARCHAR(64),                       \
		bench_begin TIMESTAMP,                      \
		run_begin TIMESTAMP,                        \
		Q1  DECIMAL(6,2),                           \
		Q2  DECIMAL(6,2),                           \
		Q3  DECIMAL(6,2),                           \
		Q4  DECIMAL(6,2),                           \
		Q5  DECIMAL(6,2),                           \
		Q6  DECIMAL(6,2),                           \
		Q7  DECIMAL(6,2),                           \
		Q8  DECIMAL(6,2),                           \
		Q9  DECIMAL(6,2),                           \
		Q10 DECIMAL(6,2),                           \
		Q11 DECIMAL(6,2),                           \
		Q12 DECIMAL(6,2),                           \
		Q13 DECIMAL(6,2),                           \
		Q14 DECIMAL(6,2),                           \
		Q15 DECIMAL(6,2),                           \
		Q16 DECIMAL(6,2),                           \
		Q17 DECIMAL(6,2),                           \
		Q18 DECIMAL(6,2),                           \
		Q19 DECIMAL(6,2),                           \
		Q20 DECIMAL(6,2),                           \
		Q21 DECIMAL(6,2),                           \
		Q22 DECIMAL(6,2),                           \
		PRIMARY KEY(                                \
			workload,                               \
			bench_begin,                            \
			run_begin                               \
		)                                           \
	)                                               \
	"

	my_exe "INSERT INTO ${table} (                  \
		workload, bench_begin, run_begin,           \
		${detail[0]} score                          \
	)                   				            \
		VALUES (                                    \
		\"${workload}\",                            \
		FROM_UNIXTIME(${bench_begin}),              \
		FROM_UNIXTIME(${run_begin}),                \
		${detail[1]}                                \
		${score}                                    \
	)                                               \
	"
}

write_record 'tpch'
