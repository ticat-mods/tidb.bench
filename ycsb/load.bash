set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

here=`dirname ${BASH_SOURCE[0]}`
env=`cat "${1}/env"`

threads=`must_env_val "${env}" 'bench.ycsb.load.threads'`
count=`must_env_val "${env}" 'bench.ycsb.count'`
bs=`must_env_val "${env}" 'bench.ycsb.batch-size'`
cc=`must_env_val "${env}" 'bench.ycsb.conn-count'`

raf=`must_env_val "${env}" 'bench.ycsb.read-all-fields'`
rmwp=`must_env_val "${env}" 'bench.ycsb.read-modify-write-proportion'`
rp=`must_env_val "${env}" 'bench.ycsb.read-proportion'`
rd=`must_env_val "${env}" 'bench.ycsb.request-distribution'`
ip=`must_env_val "${env}" 'bench.ycsb.insert-proportion'`
iso=`must_env_val "${env}" 'bench.ycsb.isolation'`
sp=`must_env_val "${env}" 'bench.ycsb.scan-proportion'`
sld=`must_env_val "${env}" 'bench.ycsb.scan-length-distribution'`
up=`must_env_val "${env}" 'bench.ycsb.update-proportion'`

host=`must_env_val "${env}" 'mysql.host'`
port=`must_env_val "${env}" 'mysql.port'`
user=`must_env_val "${env}" 'mysql.user'`

cluster=`must_env_val "${env}" 'tidb.cluster'`
pd=`must_pd_addr "${cluster}"`

tiup bench ycsb prepare \
	--pd "${pd}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	-T "${threads}" \
	-c "${count}" \
	--batchsize "${bs}" \
	--conncount "${cc}" \
	--readallfields "${raf}" \
	--readmodifywriteproportion "${rmwp}" \
	--readproportion "${rp}" \
	--requestdistribution "${rd}" \
	--insertproportion "${ip}" \
	--isolation "${iso}" \
	--scanproportion "${sp}" \
	--requestdistribution "${sld}" \
	--updateproportion "${up}" \
	--dropdata \
	--time "102400h"
