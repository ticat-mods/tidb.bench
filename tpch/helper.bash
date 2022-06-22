function parse_tpch_score()
{
	local log="${1}"
	cat "${log}" | { grep 'Summary' || test $? = 1; } | \
		awk -F 'Q*: ' '{print $2}' | awk -F 's' '{print $1}' | awk '{sum += 100/$1} END {print sum}'
}

function parse_tpch_detail()
{
	local log=`cat "${1}" | { grep 'Summary' || test $? = 1; }`

	# There are bugs in the below `local col=` lines when log line is 1, here is a workaround
	if [ `echo "${log}" | wc -l` == 1 ]; then
		local col=`echo "${log}" | awk '{print $2}'`
		local col="${col%:},"
		local val=`echo "${log}" | awk '{print $3}'`
		local val="${val%s},"
		echo "${col} ${val}"
		return
	fi

	local col=`echo "${log}" | awk '{print $2}' | sed ':a;N;$!ba;s/:/,/g' | sed ':a;N;$!ba;s/\n//g'`
	local val=`echo "${log}" | awk '{print $3}' | sed ':a;N;$!ba;s/s/,/g' | sed ':a;N;$!ba;s/\n//g'`
	echo "${col} ${val}"
}

function tpch_result_read_from_file()
{
	local summary_file="${1}"
	local fields=(`cat "${summary_file}"`)
	local keys=(`echo "${fields[0]}" | tr ',' ' '`)
	local vals=(`echo "${fields[1]}" | tr ',' ' '`)
	for (( i = 0; i < ${#keys[@]}; i++ )); do
		local key="${keys[i]}"
		local key="${key:1}"
		echo "${key}" "${vals[i]}"
	done
}
