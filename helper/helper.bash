. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/ticat.helper.bash/helper.bash"

function parse_tpmc()
{
	local log="${1}"
	cat "${log}" | grep Summary | grep 'NEW_ORDER ' | awk -F 'TPM: ' '{print $2}' | awk '{print $1}' | awk -F ',' '{print $1}'
}

function parse_sysbench_events()
{
	local log="${1}"
	cat "${log}" | grep "total number of events" | awk -F 'events: ' '{print $2}' | awk '{print $1}'
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

function gen_tag()
{
	local keys_str="${1}"
	local for_backup=`to_true "${2}"`
	local nightly_major="${3}"

	IFS=',' read -ra keys <<< "${keys_str}"
	local vals=''
	for key in "${keys[@]}"; do
		if [ "${for_backup}" == 'true' ]; then
			local val=`must_env_val "${env}" "${key}"`
			if [ -z "${val}" ]; then
				exit 1
			fi
		else
			local val=`env_val "${env}" "${key}"`
			if [ -z "${val}" ]; then
				val="{${key}}"
			fi
		fi

		if [ "${for_backup}" == 'true' ]; then
			if [ "${key}" == 'tidb.version' ]; then
				local val="${val%%+*}"
				if [ "${val}" == 'nightly' ]; then
					local val="${nightly_major}"
				else
					# Consider versions with the same major number are compatible in storage
					local val="${val%%.*}"
				fi
			fi
		fi

		local vals="${vals}@${val}"
	done

	if [ "${for_backup}" == 'true' ]; then
		local vals=`echo ${vals//./-}`
	fi

	echo "${vals}"
}
