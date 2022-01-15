set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

here="`dirname ${BASH_SOURCE[0]}`"
session="${1}"
env=`cat "${session}/env"`

threads=`must_env_val "${env}" 'bench.ycsb.threads'`
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

cluster=`must_env_val "${env}" 'tidb.cluster'`
pd=`must_pd_addr "${cluster}"`

log="${session}/ycsb.`date +%s`.log"
echo "bench.run.log=${log}" >> "${session}/env"

repo_addr=`env_val "${env}" 'bench.ycsb.repo-address'`
if [ -z "${repo_addr}" ]; then
	begin=`timestamp`

	tiup bench ycsb run \
		--pd "${pd}" \
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
		| tee "${log}"
else
	check_or_install_ycsb "${repo_addr}" "${here}"

	begin=`timestamp`

	ycsb_workload=`env_val "${env}" 'bench.ycsb.workload'`
	insert_count=`must_env_val "${env}" 'bench.ycsb.insert-count'`
	record_count=`must_env_val "${env}" 'bench.ycsb.record-count'`
	operation_count=`must_env_val "${env}" 'bench.ycsb.operation-count'`
	if [ -z "${ycsb_workload}" ]; then
		echo "[:(] unimplemention"
		exit 1
	else
		${here}/go-ycsb/bin/go-ycsb run mysql \
			--pd "${pd}" \
			-p mysql.host=${host} \
			-p mysql.port=${port} \
			-p mysql.user=${user} \
			-p mysql.db=test \
			-p recordcount=${record_count} \
			-p threadcount=${threads} \
			-p insertcount=${insert_count} \
			-p operationcount=${operation_count} \
			-P ${here}/go-ycsb/workloads/${ycsb_workload} \
			| tee "${log}"
	fi
fi

end=`timestamp`
score=`parse_ycsb "${log}"`
summary=`parse_ycsb_summary "${log}" | sed 's/ /-/g' | tr '\n' ' '`

echo "bench.workload=ycsb" >> "${session}/env"
echo "bench.run.begin=${begin}" >> "${session}/env"
echo "bench.run.end=${end}" >> "${session}/env"
echo "bench.run.score=${score}" >> "${session}/env"
echo "bench.ycsb.summary=${summary}" >> "${session}/env"
