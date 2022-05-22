function metrics_jitter()
{
	local bt="${1}"
	local query="${2}"
	local res=`"${bt}" metrics jitter -u "${url}" -q "${query}" -b "${begin}" -e "${end}" | grep jitter | awk '{print $2,$4,$6}' | tr -d ,`
	local nan=`echo "${res}" | { grep -i 'NaN' || test $? = 1; }`
	if [ ! -z "${nan}" ]; then
		local res=''
	fi
	echo "${res}"
}

function metrics_aggregate()
{
	local bt="${1}"
	local query="${2}"
	local res=`"${bt}" metrics aggregate -u "${url}" -q "${query}" -b "${begin}" -e "${end}" | awk '{print $2,$4,$6}' | tr -d ,`
	local nan=`echo "${res}" | { grep -i 'NaN' || test $? = 1; }`
	if [ ! -z "${nan}" ]; then
		local res=''
	fi
	echo "${res}"
}
