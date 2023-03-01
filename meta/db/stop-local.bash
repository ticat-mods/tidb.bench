set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env=`cat ${1}/env`
shift

name=`must_env_val "${env}" 'bench.meta.cluster'`
plain=`tiup_output_fmt_str "${env}"`

tiup cluster${plain} stop "${name}" --yes
