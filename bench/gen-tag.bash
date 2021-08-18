set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

keys=`must_env_val "${env}" 'bench.tag-from-keys'`
tag=`gen_tag "${keys}" 'false'`
echo "bench.tag=${tag}" >> "${env_file}"
