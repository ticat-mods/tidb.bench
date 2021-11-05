. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/ticat.helper.bash/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/tiup.helper.bash/helper.bash"

function parse_tpmc()
{
	local log="${1}"
	cat "${log}" | grep Summary | grep 'NEW_ORDER ' | awk -F 'TPM: ' '{print $2}' | awk '{print $1}' | awk -F ',' '{print $1}'
}

function parse_tpch_score()
{
	local log="${1}"
	cat "${log}" | grep Summary | awk -F 'Q*: ' '{print $2}' | awk -F 's' '{print $1}' | awk '{sum += 100/$1} END {print sum}'
}

function parse_tpch_detail()
{
	local log="${1}"
	local col=`cat "${log}" | grep Summary | awk '{print $2}' | sed ':a;N;$!ba;s/:/,/g' | sed ':a;N;$!ba;s/\n//g'`
	local val=`cat "${log}" | grep Summary | awk '{print $3}' | sed ':a;N;$!ba;s/s/,/g' | sed ':a;N;$!ba;s/\n//g'`
	echo "${col} ${val}"
}

function parse_sysbench_events()
{
	local log="${1}"
	cat "${log}" | grep "total number of events" | awk -F 'events: ' '{print $2}' | awk '{print $1}'
}

function parse_sysbench_detail()
{
    local log="${1}"
    cat "${log}" | awk '
    BEGIN {
        state = ""
        num_queries = 0
        num_txns = 0
        total_times = 1
        min = 0
        avg = 0
        max = 0 
        p95 = 0
    }
    /^SQL statistics/ { state = "sql" }
    /^General statistics/ { state = "time" }
    /^Latency/ { state = "latency" }
    state == "sql" {
        switch ($1) {
        case /transactions/: num_txns=$2; break;
        case /queries/: num_queries=$2; break;
        }
    }
    state == "time" && /total time/ {
        total_times=substr($3, 0, length($3)-1)
    }
    state == "latency" {
        switch ($1) {
        case /min/: min=$2; break;
        case /avg/: avg=$2; break;
        case /max/: max=$2; break;
        case /95th/: p95=$3; break;
        }
    }
    END {
        printf "qps tps min avg p95 max\n"
        printf "%.2f %.2f %s %s %s %s\n", num_queries/total_times,num_txns/total_times, min, avg, p95, max
    }
    '
}

function parse_ycsb()
{
	local log="${1}"
	cat "${log}" | grep "OPS:" | awk -F 'OPS: ' '{print $2}' | awk -F ',' '{print $1}' | awk '{sum += $1} END {print sum}'
}

function check_or_install()
{
	local to_check="${1}"
	if [ -z "${2+x}" ]; then
		local to_install="${to_check}"
	else
		local to_install="${2}"
	fi

	local pms=(
		'yum'
		'apt-get'
		'brew'
	)

	if ! [ -x "$(command -v ${to_check})" ]; then
		echo "[:-] command ${to_check} not found"

		local ok='false'
		for pm in "${pms[@]}"; do
			if [ -x "$(command -v ${pm})" ]; then
				echo "[:-] will install ${to_install} using ${pm}"
				${pm} install -y "${to_install}"
				if [[ $? > 0 ]]; then
					echo "[:(] installation failed"
					exit 1
				else
					echo "[:)] installed ${to_install}"
					ok='true'
					break 1
				fi
			fi
		done

		if [ "${ok}" != 'true' ]; then
			echo "[:(] no supported package manager found, please install ${to_install}(${to_check}) manually"
			exit 2
		fi
	else
		echo "[:)] command ${to_check} installed"
	fi
}

function convert_ver_dir_to_hash_in_tag()
{
	local val="${1}"
	local ver="${val%+*}"
	local path="${val#*+}"
	if [ -f "${path}" ]; then
		local file=`basename "${path}"`
		local role="${file%-*}"
		local role="${role:0-2}"
		local server="${file#*-}"
		if [ "${server}" == 'server' ]; then
			local hash=`${path} -V | grep Hash | awk '{print $NF}'`
			local hash="${hash:0:5}"
			echo "${ver}+${role}-${hash}"
			return
		fi
	fi
	echo "${val}"
}

function gen_tag()
{
	local keys_str="${1}"
	local for_backup=`to_true "${2}"`

	if [ ! -z "${3+x}" ]; then
		local add_key_name=`to_true "${3}"`
	else
		local add_key_name='false'
	fi

	if [ ! -z "${4+x}" ]; then
		local nightly_major="${4}"
	else
		local nightly_major=''
	fi

	IFS=',' read -ra keys <<< "${keys_str}"
	local vals=''
	for key in "${keys[@]}"; do
		if [ "${for_backup}" == 'true' ]; then
			local val=`must_env_val "${env}" "${key}"`
			if [ -z "${val}" ]; then
				exit 1
			fi
			if [ "${key}" == 'tidb.version' ]; then
				local val="${val%+*}"
				if [ "${val}" == 'nightly' ] && [ ! -z "${nightly_major}" ]; then
					local val="${nightly_major}"
				else
					# Consider versions with the same major number are compatible in storage
					local val="${val%%.*}"
				fi
			fi
		else
			local val=`env_val "${env}" "${key}"`
			if [ -z "${val}" ]; then
				local val="{${key}}"
			else
				local val=`convert_ver_dir_to_hash_in_tag "${val}"`
			fi
		fi

		if [ "${add_key_name}" == 'true' ]; then
			local val="${key}-${val}"
		fi
		local vals="${vals}@${val}"
	done

	if [ "${for_backup}" == 'true' ]; then
		local vals=`echo ${vals//./-}`
	fi

	echo "${vals}"
}

function sysbench_short_name()
{
	local name="${1}"
	local longs=(
		bulk_insert
		oltp_common
		oltp_delete
		oltp_insert
		oltp_point_select
		oltp_read_only
		oltp_read_write
		oltp_update_index
		oltp_update_non_index
		oltp_write_only
		select_random_points
		select_random_ranges
	)
	local shorts=(
		bi
		c
		d
		i
		ps
		ro
		rw
		ui
		uni
		wo
		srp
		srr
	)

	for ((n = 0; n < ${#longs[@]}; n++)); do
		if [ "${longs[${n}]}" == "${name}" ]; then
			echo "${shorts[${n}]}"
			return
		fi
	done
	echo "n_a"
}

function timestamp()
{
	echo `date +%s`
}
