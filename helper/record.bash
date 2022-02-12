function bench_record_prepare()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"

	my_ensure_db "${host}" "${port}" "${user}" "${db}"

	my_exe "${host}" "${port}" "${user}" "${db}" "                    \
	CREATE TABLE IF NOT EXISTS bench_data (                           \
		id INT,                                                       \
		section VARCHAR(64),                                          \
		name VARCHAR(128),                                            \
		val DECIMAL(16,2),                                            \
		display_order INT AUTO_INCREMENT,                             \
		agg_action VARCHAR(32),                                       \
		run_host VARCHAR(128),                                        \
		verb_level INT,                                               \
		greater_is_good INT,                                          \
		INDEX (                                                       \
			id,                                                       \
			section                                                   \
		),                                                            \
		INDEX (display_order)                                         \
	)                                                                 \
	"

	my_exe "${host}" "${port}" "${user}" "${db}" "                    \
	CREATE TABLE IF NOT EXISTS bench_tags (                           \
		id INT,                                                       \
		tag VARCHAR(512),                                             \
		display_order INT AUTO_INCREMENT,                             \
		PRIMARY KEY (                                                 \
			id,                                                       \
			tag                                                       \
		),                                                            \
		INDEX (display_order)                                         \
	)                                                                 \
	"

	my_exe "${host}" "${port}" "${user}" "${db}" "                    \
	CREATE TABLE IF NOT EXISTS bench_meta (                           \
		id INT AUTO_INCREMENT,                                        \
		finished INT,                                                 \
		bench_id VARCHAR(128),                                        \
		run_id TIMESTAMP,                                             \
		end_ts TIMESTAMP,                                             \
		run_host VARCHAR(128),                                        \
		workload VARCHAR(128),                                        \
		tiup_yaml TEXT,                                               \
		PRIMARY KEY (id),                                             \
		INDEX (                                                       \
			bench_id,                                                 \
			run_id,                                                   \
			end_ts                                                    \
		),                                                            \
		INDEX (run_host),                                             \
		INDEX (workload)                                              \
	)                                                                 \
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

function bench_record_write_start()
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

	local tiup_yaml=''
	local tiup_yaml_path=`env_val "${env}" 'tidb.tiup.yaml'`
	if [ ! -z "${tiup_yaml_path}" ] && [ -f "${tiup_yaml_path}" ]; then
		local tiup_yaml=`cat "${tiup_yaml_path}" | base64 -w 0`
	fi

	bench_record_prepare "${host}" "${port}" "${user}" "${db}"

	my_exe "${host}" "${port}" "${user}" "${db}" "                    \
		INSERT INTO bench_meta (                                      \
			finished,                                                 \
			bench_id,                                                 \
			run_id,                                                   \
			end_ts,                                                   \
			workload,                                                 \
			run_host,                                                 \
			tiup_yaml                                                 \
		) VALUES (                                                    \
			0,                                                        \
			\"${bench_id}\",                                          \
			FROM_UNIXTIME(${run_id}),                                 \
			FROM_UNIXTIME(${end_ts}),                                 \
			\"${workload}\",                                          \
			\"${ip}\",                                                 \
			\"${tiup_yaml}\"                                          \
		);                                                            \
		SELECT last_insert_id() FROM bench_meta LIMIT 1               \
		" 'tab' | tail -n 1
}

function bench_record_write_finish()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"

	local id="${5}"

	my_exe "${host}" "${port}" "${user}" "${db}" "UPDATE bench_meta SET finished=1 WHERE id=${id}"
}

function bench_record_write()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"
	shift 4

	local id="${1}"
	local section="${2}"
	local name="${3}"
	local val="${4}"
	local agg_action="${5}"
	local verb_level="${6}"
	local gig="${7}"

	local run_host=`get_ip_or_host`

	my_exe "${host}" "${port}" "${user}" "${db}" "                    \
		INSERT INTO bench_data (                                      \
			id,                                                       \
			section,                                                  \
			name,                                                     \
			val,                                                      \
			agg_action,                                               \
			run_host,                                                 \
			verb_level,                                               \
			greater_is_good                                           \
		) VALUES (                                                    \
			${id},                                                    \
			\"${section}\",                                           \
			\"${name}\",                                              \
			${val},                                                   \
			\"${agg_action}\",                                        \
			\"${run_host}\",                                          \
			${verb_level},                                            \
			${gig}                                                    \
		)"
}

function bench_record_write_tag()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"

	local id="${5}"
	local tag="${6}"

	my_exe "${host}" "${port}" "${user}" "${db}" "                    \
		INSERT INTO bench_tags (                                      \
			id,                                                       \
			tag                                                       \
		) VALUES (                                                    \
			${id},                                                    \
			\"${tag}\"                                                \
		)"
}

function bench_record_write_tags_from_env()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"
	local id="${5}"
	local env="${6}"

	local tags=`env_val "${env}" 'bench.tag'`
	if [ -z "${tags}" ]; then
		return
	fi

	local tags=`list_to_array "${tags}"`
	for tag in ${tags[@]}; do
		bench_record_write_tag "${host}" "${port}" "${user}" "${db}" "${id}" "${tag}"
	done
}

function bench_record_list()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"
	local max="${5}"

	my_exe "${host}" "${port}" "${user}" "${db}" "                    \
		SELECT                                                        \
			id as record_id,                                          \
			bench_id,                                                 \
			run_id as begin,                                          \
			workload                                                  \
		FROM bench_meta                                               \
		WHERE finished=1 ORDER BY bench_id DESC                       \
		LIMIT ${max}                                                  \
	"
}

function bench_record_add_tags()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"

	local ids="${5}"
	local tags="${6}"
	local ids=(`list_to_array "${ids}"`)
	local tags=(`list_to_array "${tags}"`)

	for id in "${ids[@]}"; do
		for tag in "${tags[@]}"; do
			echo "adding tag '${tag}' to record '${id}'"
			my_exe "${host}" "${port}" "${user}" "${db}" "            \
				INSERT INTO bench_tags (                              \
					id,                                               \
					tag                                               \
				) VALUES (                                            \
					${id},                                            \
					\"${tag}\"                                        \
				)                                                     \
				ON DUPLICATE KEY UPDATE tag=tag                       \
			"
		done
	done
}

function bench_record_rm_tags()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local db="${4}"

	local ids="${5}"
	local tags="${6}"
	local ids=(`list_to_array "${ids}"`)
	local tags=(`list_to_array "${tags}"`)

	for id in "${ids[@]}"; do
		for tag in "${tags[@]}"; do
			echo "removing tag '${tag}' from record '${id}'"
			local query="DELETE FROM bench_tags WHERE id=${id} AND tag=\"${tag}\""
			my_exe "${host}" "${port}" "${user}" "${db}" "${query}"
		done
	done
}
