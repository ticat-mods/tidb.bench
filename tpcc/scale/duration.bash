set -euo pipefail

env="${1}/env"
shift

dur="${1}"

echo -e "bench.tpcc.duration\t${dur}" >> "${env}"

echo "[:)] set data scale to env:"
echo "    - bench.tpcc.dur= ${dur}"
