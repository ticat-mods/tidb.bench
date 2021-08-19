set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

keys=`must_env_val "${env}" 'bench.tag-from-keys'`
tag=`gen_tag "${keys}" 'false'`

tag_expend_keys=`env_val "${env}" 'bench.tag-add-from-keys'`
if [ -z "${tag_expend_keys}" ]; then
	tag_expend=''
else
	tag_expend=`gen_tag "${tag_expend_keys}" 'false' 'true'`
fi

echo "bench.tag=${tag}${tag_expend}" >> "${env_file}"
