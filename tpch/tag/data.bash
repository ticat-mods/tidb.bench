set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

sf=`must_env_val "${env}" 'bench.tpch.scale-factor'`

tiflash=`must_env_val "${env}" 'bench.tpch.tiflash'`
tiflash=`to_true "${tiflash}"`
if [ "${tiflash}" == 'true' ]; then
	tiflash="-tf"
else
	tiflash=""
fi

tag="sf${sf}${tiflash}"
echo "workload.tag.data=${tag}" >> "${env_file}"
