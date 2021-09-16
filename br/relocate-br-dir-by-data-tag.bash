set -euo pipefail

here=`cd $(dirname ${BASH_SOURCE[0]}) && pwd`
. "${here}/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

tag=`must_env_val "${env}" 'tidb.data.tag'`
dir_root=`must_env_val "${env}" 'br.backup-dir'`
dir="${dir_root}/br-t${tag}"

echo "br.backup-dir=${dir}" >> "${env_file}"
