set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

keys=`must_env_val "${env}" 'tidb.data.tag-from-keys'`
nightly_major=`must_env_val "${env}" 'tidb.version.nightly-major'`

tag=`gen_tag "${keys}" 'true' 'false' "${nightly_major}"`
echo "[:)] setup tidb.data.tag=${tag}"
echo "tidb.data.tag=${tag}" >> "${env_file}"
