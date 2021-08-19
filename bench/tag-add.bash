set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

keys="${1}"
origin_tag=`must_env_key "${env}" 'bench.tag'`

tag=`gen_tag "${keys}" 'false' 'true'`
echo "bench.tag=${origin_tag}${tag}" >> "${env_file}"
