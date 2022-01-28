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
