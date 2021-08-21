set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

sf=`must_env_val "${env}" 'bench.tpch.scale-factor'`

tiflash=`must_env_val "${env}" 'bench.tpch.tiflash'`
tiflash=`to_true "${tiflash}"`
if [ "${tiflash}" == 'true' ]; then
	tiflash="-tiflash"
else
	tiflash=""
fi

tag="sf=${sf}${tiflash}"

soft_tag=''
threads=`env_val "${env}" 'bench.tpch.threads'`
if [ ! -z "${threads}" ]; then
	soft_tag="${soft_tag}-t=${threads}"
fi
duration=`env_val "${env}" 'bench.tpch.duration'`
if [ ! -z "${duration}" ]; then
	soft_tag="${soft_tag}-t=${duration}"
fi

if [ ! -z "${soft_tag}" ]; then
	tag="${tag}+${soft_tag:1}"
fi
echo "bench.workload.tag=${tag}" >> "${env_file}"
