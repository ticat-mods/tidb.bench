function check_or_install_ycsb()
{
	local addr="${1}"
	local prefix="${2}"

	if [ ! -x "${prefix}/go-ycsb/bin/go-ycsb" ]; then
		wget -c "${addr}" -O - | tar -xz -C "${prefix}"
	fi
}

function parse_ycsb()
{
	local log="${1}"
	cat "${log}" | { grep "OPS:" || test $? = 1; } | \
		awk -F 'OPS: ' '{print $2}' | awk -F ',' '{print $1}' | awk '{sum += $1} END {print sum}'
}

function parse_ycsb_summary()
{
	local log="${1}"
	cat "${log}" | awk -F '- ' '
	BEGIN {
		map["Takes(s)"] = "takes"
		map["Count"] = "count"
		map["OPS"] = "ops"
		map["Avg(us)"] = "avg"
		map["Min(us)"] = "min"
		map["Max(us)"] = "max"
		map["99th(us)"] = "p99"
		map["99.9th(us)"] = "p999"
		map["99.99th(us)"] = "p9999"
	}
	/READ/ || /UPDATE/ || /INSERT/ || /SCAN/ || /READ_MODIFY_WRITE/ || /DELETE/ {
		split($2,items,", ")
		gsub(/ /, "", $1)
		if ($1 in result); else {
			result[$1]["size"] = 0
			result[$1]["min"] = 1000000000
			result[$1]["max"] = 0
		}
		result[$1]["size"] += 1
		for (idx in items) {
			split(items[idx],pairs,": ")
			name=map[pairs[1]]
			switch (name) {
			case "takes":
			case "count":
			case "ops":
			case "avg":
			case "p99":
			case "p999":
			case "p9999":
				if (name in result[$1]); else
					result[$1][name] = 0
				result[$1][name] += pairs[2]
				break
			case "min":
				if (result[$1][name] > pairs[2])
					result[$1][name] = pairs[2]
				break
			case "max":
				if (result[$1][name] < pairs[2])
					result[$1][name] = pairs[2]
				break
			}
		}
	}
	END {
		for (type in result) {
			columns=""
			values=""
			size=result[type]["size"]
			if (size == 0) continue;
			for (col in result[type]) {
				if (col == "size") continue;
				val = result[type][col]
				switch (col) {
				case "avg":
				case "ops":
				case "p99":
				case "p999":
				case "p9999":
					val = val / size
				}
				if (columns != "") {
					columns = columns ","
					values = values ","
				}
				columns = columns col
				values = values val
			}
			print type,columns,values,size
		}
	}
'
}

function ycsb_result_agg_action()
{
	local key="${1}"
	if [ "${key}" == 'takes' ] || [ "${key}" == 'ops' ] || [ "${key}" == 'count' ]; then
		echo 'SUM'
	elif [ "${key}" == 'min' ]; then
		echo 'MIN'
	elif [ "${key}" == 'max' ]; then
		echo 'MAX'
	else
		echo 'AVG'
	fi
}

function ycsb_result_verb_level()
{
	local key="${1}"
	local verb=3
	if [ "${key}" == 'ops' ]; then
		local verb=0
	elif [ "${key}" == 'avg' ]; then
		local verb=0
	elif [ "${key}" == 'p99' ]; then
		local verb=0
	elif [ "${key}" == 'p999' ]; then
		local verb=1
	elif [ "${key}" == 'p9999' ]; then
		local verb=1
	elif [ "${key}" == 'max' ]; then
		local verb=2
	elif [ "${key}" == 'min' ]; then
		local verb=3
	elif [ "${key}" == 'takes' ]; then
		local verb=3
	elif [ "${key}" == 'count' ]; then
		local verb=3
	fi
	echo ${verb}
}

function ycsb_result_gig()
{
	local key="${1}"
	if [ "${key}" == 'ops' ] || [ "${key}" == 'count' ]; then
		echo '1'
	elif [ "${key}" == 'takes' ]; then
		echo '-1'
	else
		echo '0'
	fi
}
