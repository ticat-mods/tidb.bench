set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

env=`cat "${1}/env"`

threads=`must_env_val "${env}" 'bench.ycsb.load.threads'`
bs=`must_env_val "${env}" 'bench.ycsb.batch-size'`
cc=`must_env_val "${env}" 'bench.ycsb.conn-count'`
c=`must_env_val "${env}" 'bench.ycsb.count'`
iso=`must_env_val "${env}" 'bench.ycsb.isolation'`
rd=`must_env_val "${env}" 'bench.ycsb.request-distribution'`
rp=`must_env_val "${env}" 'bench.ycsb.read-proportion'`
ip=`must_env_val "${env}" 'bench.ycsb.insert-proportion'`
up=`must_env_val "${env}" 'bench.ycsb.update-proportion'`
rmwp=`must_env_val "${env}" 'bench.ycsb.read-modify-write-proportion'`
sp=`must_env_val "${env}" 'bench.ycsb.scan-proportion'`
raf=`must_env_val "${env}" 'bench.ycsb.read-all-fields'`

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`

tiup bench ycsb prepare \
	-T "${threads}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	--batchsize "${bs}" \
	--conncount "${cc}" \
	-c "${c}" \
	--isolation "${iso}" \
	--readproportion "${rp}" \
	--insertproportion "${ip}" \
	--updateproportion "${up}" \
	--readmodifywriteproportion "${rmwp}" \
	--scanproportion "${sp}" \
	--readallfields "${raf}" \
	--requestdistribution "${rd}" \
	--dropdata \
	--time "102400h"
