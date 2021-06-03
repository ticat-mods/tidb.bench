set -euo pipefail

env="${1}/env"
shift

threads="${1}"

echo -e "bench.tpcc.threads\t${threads}" >> "${env}"

echo "[:)] set data scale to env:"
echo "    - bench.tpcc.threads = ${threads}"
