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
