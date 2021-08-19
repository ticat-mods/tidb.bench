set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

tiflash=`must_env_val "${env}" 'bench.tpch.tiflash'`
tiflash=`to_true "${tiflash}"`
if [ "${tiflash}" == 'true' ]; then
	tiflash="-tiflash"
else
	tiflash=""
fi

threads=`must_env_val "${env}" 'bench.tpch.threads'`
duration=`must_env_val "${env}" 'bench.tpch.duration'`
sf=`must_env_val "${env}" 'bench.tpch.scale-factor'`

tag="sf=${sf}-t=${threads}-dur=${duration}${tiflash}"

echo "bench.workload.tag=${tag}" >> "${env_file}"
