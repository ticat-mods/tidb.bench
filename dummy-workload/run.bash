set -euo pipefail

echo ">>> dummy-workload begin"

session="${1}"
log="${session}/dummy-workload.log"
echo "hello world" > "${log}"
echo "bench.log=${log}" >> "${session}/env"
echo "bench.score=99" >> "${session}/env"

echo "<<< dummy-workload finish"
