set -euo pipefail

echo ">>> dummy-workload begin"

session="${1}"
log="${session}/dummy-workload.log"
echo "hello world" > "${log}"
echo "bench.run.log=${log}" >> "${session}/env"
echo "bench.run.score=99" >> "${session}/env"

echo "<<< dummy-workload finish"
