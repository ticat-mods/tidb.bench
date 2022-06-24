set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

record_prepare "${env_file}"
bench_record_write_tags_from_env "${host}" "${port}" "${user}" "${pp}" "${db}" "${run_id}" "${env}"
