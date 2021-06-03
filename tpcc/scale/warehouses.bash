set -euo pipefail

env="${1}/env"
shift

wh="${1}"

echo -e "bench.tpcc.warehouses\t${wh}" >> "${env}"

echo "[:)] set data scale to env:"
echo "    - bench.tpcc.warehouses = ${wh}"
