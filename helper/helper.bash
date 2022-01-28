. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/bash.helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/tiup.helper/tiup.bash"

function timestamp()
{
	echo `date +%s`
}
