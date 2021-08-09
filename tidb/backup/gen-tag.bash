set -euo pipefail
. "`cd $(dirname ${BASH_SOURCE[0]}) && pwd`/../../helper/helper.bash"

env_file="${1}/env"
env=`cat "${env_file}"`
shift

keys_str="${1}"
IFS=',' read -ra keys <<< "${keys_str}"

vals=''
for key in "${keys[@]}"; do
	val=`must_env_val "${env}" "${key}"`
	vals="${vals}@${val}"
	echo "key=${key}, val=${val}"
done

vals=`echo ${vals/./-}`

echo "[:)] setup tidb.backup.tag=${vals}"
echo "tidb.backup.tag=${vals}" >> "${env_file}"
