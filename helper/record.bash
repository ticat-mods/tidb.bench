function bench_record_prepare()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"

	my_ensure_db "${host}" "${port}" "${user}" "${db}"

	my_exe "${host}" "${port}" "${user}" "${db}" "  \
	CREATE TABLE IF NOT EXISTS bench_data (         \
		bench_id VARCHAR(128),                      \
		run_id TIMESTAMP,                           \
		section VARCHAR(64),                        \
		name VARCHAR(128),                          \
		val DECIMAL(16,2),                          \
		display_order INT AUTO_INCREMENT,           \
		agg_action VARCHAR(32),                     \
		verb_level INT,                             \
		INDEX (                                     \
			bench_id,                               \
			run_id,                                 \
			section                                 \
		),                                          \
		INDEX (name),                               \
		INDEX (display_order)                       \
	)                                               \
	"

	my_exe "${host}" "${port}" "${user}" "${db}" "  \
	CREATE TABLE IF NOT EXISTS bench_tags (         \
		bench_id VARCHAR(128),                      \
		run_id TIMESTAMP,                           \
		tag VARCHAR(512),                           \
		INDEX (                                     \
			bench_id,                               \
			run_id                                  \
		),                                          \
		INDEX (tag)                                 \
	)                                               \
	"

	my_exe "${host}" "${port}" "${user}" "${db}" "  \
	CREATE TABLE IF NOT EXISTS bench_meta (         \
		bench_id VARCHAR(128),                      \
		run_id TIMESTAMP,                           \
		end_ts TIMESTAMP,                           \
		run_host VARCHAR(128),                      \
		workload VARCHAR(128),                      \
		PRIMARY KEY (                               \
			bench_id,                               \
			run_id                                  \
		),                                          \
		INDEX (run_host),                           \
		INDEX (workload)                            \
	)                                               \
	"
}

function bench_record_clear()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"

	my_exe "${host}" "${port}" "${user}" "${db}" "DROP TABLE IF EXISTS bench_meta"
	my_exe "${host}" "${port}" "${user}" "${db}" "DROP TABLE IF EXISTS bench_tags"
	my_exe "${host}" "${port}" "${user}" "${db}" "DROP TABLE IF EXISTS bench_data"
}

function bench_record_write()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"
	shift 4

	local env="${1}"
	shift

	local section="${1}"
	local name="${2}"
	local val="${3}"
	local agg_action="${4}"
	local verb_level="${5}"

	local bench_id=`must_env_val "${env}" 'sys.session.id'`
	local run_id=`must_env_val "${env}" 'bench.run.begin'`
	local end_ts=`must_env_val "${env}" 'bench.run.end'`

	my_exe "${host}" "${port}" "${user}" "${db}" "                    \
		INSERT INTO bench_data (                                      \
			bench_id,                                                 \
			run_id,                                                   \
			section,                                                  \
			name,                                                     \
			val,                                                      \
			agg_action,                                               \
			verb_level                                                \
		) VALUES (                                                    \
			\"${bench_id}\",                                          \
			FROM_UNIXTIME(${run_id}),                                 \
			\"${section}\",                                           \
			\"${name}\",                                              \
			${val},                                                   \
			\"${agg_action}\",                                        \
			${verb_level}                                             \
		)"
}

function bench_record_write_tag()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"
	local tag="${5}"
	local env="${6}"

	local bench_id=`must_env_val "${env}" 'sys.session.id'`
	local run_id=`must_env_val "${env}" 'bench.run.begin'`

	my_exe "${host}" "${port}" "${user}" "${db}" "                    \
		INSERT INTO bench_tags (                                      \
			bench_id,                                                 \
			run_id,                                                   \
			tag                                                       \
		) VALUES (                                                    \
			\"${bench_id}\",                                          \
			FROM_UNIXTIME(${run_id}),                                 \
			\"${tag}\"                                                \
		)"
}

function bench_record_write_tags_from_env()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"
	local env="${5}"

	local tags=`env_val "${env}" 'bench.tag'`
	if [ -z "${tags}" ]; then
		return
	fi

	local tags=`list_to_array "${tags}"`
	for tag in ${tags[@]}; do
		bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${tag}" "${env}"
	done
}

function bench_record_write_finish()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"
	local workload="${5}"
	local env="${6}"

	local bench_id=`must_env_val "${env}" 'sys.session.id'`
	local ip=`must_env_val "${env}" 'sys.session.id.ip'`
	local run_id=`must_env_val "${env}" 'bench.run.begin'`
	local end_ts=`must_env_val "${env}" 'bench.run.end'`

	my_exe "${host}" "${port}" "${user}" "${db}" "                    \
		INSERT INTO bench_meta (                                      \
			bench_id,                                                 \
			run_id,                                                   \
			end_ts,                                                   \
			workload,                                                 \
			run_host                                                  \
		) VALUES (                                                    \
			\"${bench_id}\",                                          \
			FROM_UNIXTIME(${run_id}),                                 \
			FROM_UNIXTIME(${end_ts}),                                 \
			\"${workload}\",                                          \
			\"${ip}\"                                                 \
		)"
}

function bench_record_show()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"

	echo
	my_exe "${host}" "${port}" "${user}" "${db}" "SELECT * FROM bench_meta;"
	echo
	my_exe "${host}" "${port}" "${user}" "${db}" "SELECT * FROM bench_tags;"
	echo
	my_exe "${host}" "${port}" "${user}" "${db}" "SELECT * FROM bench_data;"
}
