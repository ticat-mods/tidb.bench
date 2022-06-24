. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/bench-toolset.bash"

function get_prom_addr()
{
	local env="${1}"
	local prom=`env_val "${env}" 'bench.prometheus'`
	if [ -z "${prom}" ]; then
		local name=`must_env_val "${env}" 'tidb.cluster'`
		local url='http://'`must_prometheus_addr "${name}"`
	else
		local url="${prom}"
	fi
	echo "${url}"
}

function to_mb()
{
	local v="${1}"
	local v=`echo "${v}" | awk '{printf("%f",$0)}'`
	local v="${v%.*}"
	local v=$((v/1024/1024))
	local v="${v%.*}"
	echo "${v}"
}

# export vars: host, port, user, pp, db, run_id
function record_prepare()
{
	local env_file="${1}"
	local env=`cat "${env_file}"`

	host=`must_env_val "${env}" 'bench.meta.host'`
	port=`must_env_val "${env}" 'bench.meta.port'`
	user=`must_env_val "${env}" 'bench.meta.user'`
	pp=`env_val "${env}" 'bench.meta.pwd'`
	db=`must_env_val "${env}" 'bench.meta.db-name'`

	# get or gen curr run_id
	run_id=`env_val "${env}" 'bench.run.id'`
	if [ -z "${run_id}" ]; then
		local workload=`must_env_val "${env}" 'bench.workload'`
		run_id=`bench_record_write_start "${host}" "${port}" "${user}" "${pp}" "${db}" "${workload}" "${env}"`
		echo "bench.run.id=${run_id}" >> "${env_file}"
	fi
}
# read vars: host, port, user, pp, db, run_id
function record_write()
{
	local section="${1}"
	local key="${2}"
	local val="${3}"
	local agg_action="${4}"
	local verb_level="${5}"
	local greater_is_good="${6}"

	bench_record_write "${host}" "${port}" "${user}" "${pp}" "${db}" "${run_id}" \
		"${section}" "${key}" "${val}" "${agg_action}" "${verb_level}" "${greater_is_good}"
}

# export vars: bt_bin, begin, end, metrics_url
function bt_prepare()
{
	local env=`cat "${1}"`

	local bt_repo_addr=`must_env_val "${env}", 'bench.bench-toolset-repo-addr'`
	local bt_download_token=`must_env_val "${env}" 'sys.secret.download-bin-token'`
	bt_bin=`download_or_build_bin "${env}" "${bt_repo_addr}" 'bin/bench-toolset' 'make' "${bt_download_token}"`

	begin=`must_env_val "${env}" 'bench.run.begin'`'000'
	end=`must_env_val "${env}" 'bench.run.end'`'000'

	metrics_url=`get_prom_addr "${env}"`
}
# read vars: bt_bin, begin, end, metrics_url
function bt_jitter()
{
	local query="${1}"
	local res=`"${bt_bin}" metrics jitter -u "${metrics_url}" -q "${query}" -b "${begin}" -e "${end}" | { grep 'jitter' || test = $?; } | awk '{print $2,$4,$6}' | tr -d ,`
	local nan=`echo "${res}" | { grep -i 'NaN' || test $? = 1; }`
	if [ ! -z "${nan}" ]; then
		local res=''
	fi
	echo "${res}"
}
# read vars: bt_bin, begin, end, metrics_url
function bt_aggregate()
{
	local query="${1}"
	local res=`"${bt_bin}" metrics aggregate -u "${metrics_url}" -q "${query}" -b "${begin}" -e "${end}" | awk '{print $2,$4,$6}' | tr -d ,`
	local nan=`echo "${res}" | { grep -i 'NaN' || test $? = 1; }`
	if [ ! -z "${nan}" ]; then
		local res=''
	fi
	echo "${res}"
}
