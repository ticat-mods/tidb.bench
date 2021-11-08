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
workload='ycsb'

# The context of one run
run_begin=`env_val "${env}" 'bench.run.begin'`
if [ -z "${run_begin}" ]; then
	echo "[:-] env 'bench.run.begin' is empty, skipped" >&2
	exit
fi
run_end=`must_env_val "${env}" 'bench.run.end'`
run_log=`must_env_val "${env}" 'bench.run.log'`

summary=`must_env_val "${env}" 'bench.ycsb.summary'`
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
        type VARCHAR(512),                          \
        takes DECIMAL(8,2),                         \
        count DECIMAL(8,2),                         \
        ops DECIMAL(8,2),                           \
        avg DECIMAL(8,2),                           \
        p99 DECIMAL(8,2),                           \
        p999 DECIMAL(8,2),                          \
        p9999 DECIMAL(8,2),                         \
        min DECIMAL(8,2),                           \
        max DECIMAL(8,2),                           \
		tag VARCHAR(512),                           \
		PRIMARY KEY(                                \
			bench_begin,                            \
			run_begin,                              \
            type                                    \
		)                                           \
	)                                               \
	"
    
    echo "${summary}" | sed 's/ /\n/g' | while read line; do
        if [ -z "${line// }" ]; then
            continue; 
        fi
        detail=(`echo "${line}" | sed 's/-/ /g'`)
        my_exe "INSERT INTO ${table} (                  \
            score, bench_begin, run_begin,              \
            type, ${detail[1]}, tag                     \
        )                   				            \
            VALUES (                                    \
            ${score},                                   \
            FROM_UNIXTIME(${bench_begin}),              \
            FROM_UNIXTIME(${run_begin}),                \
            \"${detail[0]}\",                           \
            ${detail[2]},                               \
            \"${tag}\"                                  \
        )                                               \
        "
    done
}

write_record 'ycsb'
