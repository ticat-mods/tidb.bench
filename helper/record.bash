. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/tiup.helper/tiup.bash"

function bench_record_prepare()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"
	local ca="${6}"

	my_ensure_db "${host}" "${port}" "${user}" "${pp}" "${db}" "${ca}"

	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "            \
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
	" '' "${ca}"

	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "            \
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
	" '' "${ca}"

	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "            \
	CREATE TABLE IF NOT EXISTS bench_meta (                           \
		id INT AUTO_INCREMENT,                                        \
		finished INT,                                                 \
		bench_id VARCHAR(128),                                        \
		run_id TIMESTAMP,                                             \
		end_ts TIMESTAMP,                                             \
		run_host VARCHAR(128),                                        \
		workload VARCHAR(128),                                        \
		tiup_yaml TEXT,                                               \
		dashboard VARCHAR(256),                                       \
		monitor VARCHAR(256),                                         \
		PRIMARY KEY (id),                                             \
		INDEX (                                                       \
			bench_id,                                                 \
			run_id,                                                   \
			end_ts                                                    \
		),                                                            \
		INDEX (run_host),                                             \
		INDEX (workload)                                              \
	)                                                                 \
	" '' "${ca}"
}

function bench_record_clear()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"
	local ca="${6}"

	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "DROP TABLE IF EXISTS bench_meta" '' "${ca}"
	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "DROP TABLE IF EXISTS bench_tags" '' "${ca}"
	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "DROP TABLE IF EXISTS bench_data" '' "${ca}"
}

function normalize_host_addr()
{
	local addr="${1}"
	if [ -z "${addr}" ]; then
		return
	fi

	local addr="${addr#'https://'}"
	local addr="${addr#'http://'}"

	local trimmed="${addr#'127.0.0.1'}"
	local trimmed="${trimmed#'localhost'}"

	if [ "${trimmed}" != "${addr}" ]; then
		local guess=`guess_ip`
		if [ ! -z "${guess}" ]; then
			local addr="${guess}${trimmed}"
		fi
	fi

	echo "${addr}"
}

function bench_record_write_start()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"
	local workload="${6}"
	local env="${7}"
	local ca="${8}"

	local bench_id=`must_env_val "${env}" 'sys.session.id'`
	local ip=`must_env_val "${env}" 'sys.session.id.ip'`
	local run_id=`must_env_val "${env}" 'bench.run.begin'`
	local end_ts=`must_env_val "${env}" 'bench.run.end'`

	local tiup_yaml=''
	local tiup_yaml_path=`env_val "${env}" 'tidb.tiup.yaml'`
	if [ ! -z "${tiup_yaml_path}" ] && [ -f "${tiup_yaml_path}" ]; then
		local tiup_yaml=`cat "${tiup_yaml_path}" | base64 -w 0`
	fi

	local dashboard='-'
	local monitor='-'
	local name=`env_val "${env}" 'tidb.cluster'`
	if [ ! -z "${name}" ]; then
		local dashboard=`cluster_dashboard "${name}"`
		local monitor=`cluster_grafana "${name}"`
		local dashboard=`normalize_host_addr "${dashboard}"`
		local monitor=`normalize_host_addr "${monitor}"`
	fi

	bench_record_prepare "${host}" "${port}" "${user}" "${pp}" "${db}" "${ca}"

	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "            \
		INSERT IGNORE INTO bench_meta (                                      \
			finished,                                                 \
			bench_id,                                                 \
			run_id,                                                   \
			end_ts,                                                   \
			workload,                                                 \
			run_host,                                                 \
			tiup_yaml,                                                \
			dashboard,                                                \
			monitor                                                   \
		) VALUES (                                                    \
			0,                                                        \
			\"${bench_id}\",                                          \
			FROM_UNIXTIME(${run_id}),                                 \
			FROM_UNIXTIME(${end_ts}),                                 \
			\"${workload}\",                                          \
			\"${ip}\",                                                \
			\"${tiup_yaml}\",                                         \
			\"${dashboard}\",                                         \
			\"${monitor}\"                                            \
		);                                                            \
		SELECT last_insert_id() FROM bench_meta LIMIT 1               \
		" 'tab' "${ca}" | tail -n 1
}

function bench_record_write_finish()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"

	local id="${6}"

	local ca="${7}"

	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "UPDATE bench_meta SET finished=1 WHERE id=${id}" '' "${ca}"
}

function bench_record_write()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"
	shift 5

	local id="${1}"
	local section="${2}"
	local name="${3}"
	local val="${4}"
	local agg_action="${5}"
	local verb_level="${6}"
	local gig="${7}"

	local ca="${8}"

	local run_host=`get_ip_or_host`

	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "            \
		INSERT IGNORE INTO bench_data (                                      \
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
		)" '' "${ca}"
}

function bench_record_write_tag()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"

	local id="${6}"
	local tag="${7}"

	local ca="${8}"

	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "            \
		INSERT IGNORE INTO bench_tags (                                      \
			id,                                                       \
			tag                                                       \
		) VALUES (                                                    \
			${id},                                                    \
			\"${tag}\"                                                \
		)" '' "${ca}"
}

function bench_record_write_tags_from_env()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"
	local id="${6}"
	local env="${7}"
	local ca="${8}"

	local tags=`env_val "${env}" 'bench.tag'`
	if [ ! -z "${tags}" ]; then
		local tags=`list_to_array "${tags}"`
		for tag in ${tags[@]}; do
			bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "${tag}" "${ca}"
		done
	fi

	local tags_lines=`env_prefix_vals "${env}" 'bench.tag\.' | sort | uniq`
	if [ ! -z "${tags_lines}" ]; then
		echo "${tags_lines}" | while read line; do
			local tags=`list_to_array "${line}"`
			for tag in ${tags[@]}; do
				bench_record_write_tag "${host}" "${port}" "${user}" "${pp}" "${db}" "${id}" "${tag}" "${ca}"
			done
		done
	fi
}

function bench_record_list()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"
	local max="${6}"
	local ca="${7}"

	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "            \
		SELECT                                                        \
			id as record_id,                                          \
			bench_id,                                                 \
			run_id as begin,                                          \
			workload                                                  \
		FROM bench_meta                                               \
		WHERE finished=1 ORDER BY bench_id DESC                       \
		LIMIT ${max}                                                  \
	" '' "${ca}"
}

function bench_record_show_tags()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"
	local ca="${6}"

	my_exe "${host}" "${port}" "${user}" "${pp}" "${db}"              \
		"SELECT DISTINCT tag FROM bench_tags" 'tab' "${ca}"
}

function bench_record_add_tags()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"

	local ids="${6}"
	local tags="${7}"
	local ids=(`list_to_array "${ids}"`)
	local tags=(`list_to_array "${tags}"`)

	local ca="${8}"

	for id in "${ids[@]}"; do
		for tag in "${tags[@]}"; do
			echo "adding tag '${tag}' to record '${id}'"
			my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "    \
				INSERT IGNORE INTO bench_tags (                              \
					id,                                               \
					tag                                               \
				) VALUES (                                            \
					${id},                                            \
					\"${tag}\"                                        \
				)                                                     \
				ON DUPLICATE KEY UPDATE tag=tag                       \
			" '' "${ca}"
		done
	done
}

function bench_record_rm_tags()
{
	local host="${1}"
	local port="${2}"
	local user="${3}"
	local pp="${4}"
	local db="${5}"

	local ids="${6}"
	local tags="${7}"
	local ids=(`list_to_array "${ids}"`)
	local tags=(`list_to_array "${tags}"`)

	local ca="${8}"

	for id in "${ids[@]}"; do
		for tag in "${tags[@]}"; do
			echo "removing tag '${tag}' from record '${id}'"
			local query="DELETE FROM bench_tags WHERE id=${id} AND tag=\"${tag}\""
			my_exe "${host}" "${port}" "${user}" "${pp}" "${db}" "${query}" '' "${ca}"
		done
	done
}
