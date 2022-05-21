function metrics_jitter()
{
	local bt="${1}"
	local query="${2}"
	local res=`"${bt}" metrics jitter -u "${url}" -q "${query}" -b "${begin}" -e "${end}" | grep jitter | awk '{print $2,$4,$6}' | tr -d ,`
	echo "${res}"
}

function metrics_aggregate()
{
	local bt="${1}"
	local query="${2}"
	local res=`"${bt}" metrics aggregate -u "${url}" -q "${query}" -b "${begin}" -e "${end}" | awk '{print $2,$4,$6}' | tr -d ,`
	echo "${res}"
}
