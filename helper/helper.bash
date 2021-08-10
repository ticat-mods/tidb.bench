. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/ticat.helper.bash/helper.bash"

function parse_tpmc()
{
	local log="${1}"
	cat "${log}" | grep Summary | grep 'NEW_ORDER ' | awk -F 'TPM: ' '{print $2}' | awk '{print $1}' | awk -F ',' '{print $1}'
}

function gen_tag()
{
	local keys_str="${1}"
	local for_backup=`to_true "${2}"`

	IFS=',' read -ra keys <<< "${keys_str}"
	local vals=''
	for key in "${keys[@]}"; do
		local val=`must_env_val "${env}" "${key}"`
		if [ -z "${val}" ]; then
			exit 1
		fi

		if [ "${for_backup}" == 'true' ]; then
			if [ "${key}" == 'tidb.version' ]; then
				local val="${val%%+*}"

				# Consider versions with the same major number are compatible in storage
				local val="${val%%.*}"
			fi
		fi

		local vals="${vals}@${val}"
	done

	if [ "${for_backup}" == 'true' ]; then
		local vals=`echo ${vals//./-}`
	fi

	echo "${vals}"
}
