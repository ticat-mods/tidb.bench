set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`

bs=`must_env_val "${env}" 'bench.ycsb.batch-size'`
cc=`must_env_val "${env}" 'bench.ycsb.conn-count'`
c=`must_env_val "${env}" 'bench.ycsb.count'`
iso=`must_env_val "${env}" 'bench.ycsb.isolation'`
rd=`must_env_val "${env}" 'bench.ycsb.request-distribution'`
rp=`must_env_val "${env}" 'bench.ycsb.read-proportion'`
ip=`must_env_val "${env}" 'bench.ycsb.insert-proportion'`
up=`must_env_val "${env}" 'bench.ycsb.update-proportion'`
sp=`must_env_val "${env}" 'bench.ycsb.scan-proportion'`
rmwp=`must_env_val "${env}" 'bench.ycsb.read-modify-write-proportion'`

tag="b=-${bs}-cc=${cc}-cnt=${c}-iso=${iso}-dist=${rd}-r+i+u+s+rmw=${rp}+${ip}+${up}+${sp}+${rmwp}"

echo "bench.workload.tag=${tag}" >> "${env_file}"
