function parse_tpmc()
{
	local log="${1}"
	cat "${log}" | grep Summary | grep 'NEW_ORDER ' | awk -F 'TPM: ' '{print $2}' | awk '{print $1}' | awk -F ',' '{print $1}'
}

function parse_tpmc_summary()
{
	local log="${1}"
	cat "${log}" | awk -F ' - ' '
	BEGIN {
		map["Takes(s)"]="takes"
		map["Count"]="count"
		map["TPM"]="tpm"
		map["Sum(ms)"]="sum"
		map["Avg(ms)"]="avg"
		map["50th(ms)"]="p50"
		map["90th(ms)"]="p90"
		map["95th(ms)"]="p95"
		map["99th(ms)"]="p99"
		map["99.9th(ms)"]="p999"
		map["Max(ms)"]="max"
		count=0
	}
	/Summary/ {
		split($1,a," ")
		split($2,b,", ")
		columns = ""
		values = ""
		for (idx in b) {
			item = b[idx]
			if (item ~ "Sum") continue;
			split(item,pair,": ")
			if (columns != "") {
				columns = columns ","
				values = values ","
			}
			columns = columns map[pair[1]]
			values = values pair[2]
		}
		print a[2],columns,values
	}
	'
}
