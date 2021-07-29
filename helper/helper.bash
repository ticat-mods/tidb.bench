. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/ticat.helper.bash/helper.bash"

function parse_tpmc()
{
	local log="${1}"
	cat "${log}" | grep Summary | grep 'NEW_ORDER ' | awk -F 'TPM: ' '{print $2}' | awk '{print $1}' | awk -F ',' '{print $1}'
}
