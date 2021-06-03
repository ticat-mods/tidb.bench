set -euo pipefail

env="${1}/env"

echo -e "bench.tpcc.threads\t1" >> "${env}"
echo -e "bench.tpcc.warehouses\t1" >> "${env}"
echo -e "bench.tpcc.duration\t1m" >> "${env}"

echo "[:)] set data scale to env:"
echo "    - bench.tpcc.threads = 1"
echo "    - bench.tpcc.warehouses = 1"
echo "    - bench.tpcc.duration = 1m"
