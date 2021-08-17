set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

keys=`must_env_val "${env}" 'tidb.backup.tag-from-keys'`
nightly_major=`must_env_val "${env}" 'tidb.version.nightly-major'`

tag=`gen_tag "${keys}" 'true' "${nightly_major}"`
echo "[:)] setup tidb.backup.tag=${tag}"
echo "tidb.backup.tag=${tag}" >> "${env_file}"
