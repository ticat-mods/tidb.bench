set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/helper.bash"

here="`dirname ${BASH_SOURCE[0]}`"
session="${1}"
env=`cat "${session}/env"`

threads=`must_env_val "${env}" 'bench.ycsb.threads'`
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
pp=`env_val "${env}" 'mysql.pwd'`

pd=`must_env_val "${env}" 'tidb.pd'`

log="${session}/ycsb.`date +%s`.log"
echo "bench.run.log=${log}" >> "${session}/env"

tiup bench ycsb run \
	--pd "${pd}" \
	-P "${port}" \
	-H "${host}" \
	-U "${user}" \
	-p "${pp}" \
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
	| tee "${log}"

score=`parse_ycsb "${log}"`
parse_ycsb_summary "${log}" | tee "${log}.summary"

echo "bench.run.id=--" >> "${session}/env"
echo "bench.run.score=${score}" >> "${session}/env"
