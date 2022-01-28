. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/bash.helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/tiup.helper/tiup.bash"

# TODO: let each workload import their own helper
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/tpcc.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/tpch.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/sysbench.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/ycsb.bash"

function timestamp()
{
	echo `date +%s`
}
