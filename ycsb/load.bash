set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../helper/helper.bash"

wkdir=`dirname ${BASH_SOURCE[0]}`
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

repo_addr=`env_val "${env}" 'bench.ycsb.repo-address'`
if [ -z "${repo_addr}" ]; then
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
else
    set -x
    check_or_install_ycsb "${repo_addr}" "${wkdir}"
    ycsb_workload=`env_val "${env}" 'bench.ycsb.workload'`
    insert_count=`must_env_val "${env}" 'bench.ycsb.insert-count'`
    insert_start=`must_env_val "${env}" 'bench.ycsb.insert-start'`
    record_count=`must_env_val "${env}" 'bench.ycsb.record-count'`
    if [ -z "${ycsb_workload}" ]; then
        echo "[:(] unimplemention"
        exit 1
    else
        ${wkdir}/go-ycsb/bin/go-ycsb load mysql \
            -p mysql.host=${host} \
            -p mysql.port=${port} \
            -p mysql.user=${user} \
            -p mysql.db=test \
            -p recordcount=${record_count} \
            -p threadcount=${threads} \
            -p insertcount=${insert_count} \
            -p insertstart=${insert_start} \
            -P ${wkdir}/go-ycsb/workloads/${ycsb_workload}
    fi
fi
