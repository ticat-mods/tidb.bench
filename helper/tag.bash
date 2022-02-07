# DEPRECATED !!!

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
