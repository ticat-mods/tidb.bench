set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

keys=`must_env_val "${env}" 'tidb.backup.tag-from-keys'`

tag=`gen_tag "${keys}" 'true'`
echo "[:)] setup tidb.backup.tag=${tag}"
echo "tidb.backup.tag=${tag}" >> "${env_file}"

tag=`gen_tag "${keys}" 'false'`
echo "[:)] setup bench.tag=${tag}"
echo "bench.tag=${tag}" >> "${env_file}"
