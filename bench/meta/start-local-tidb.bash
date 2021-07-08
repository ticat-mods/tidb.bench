set -euo pipefail

shift
host="${1}"
port="${2}"
db_name="${3}"
cluster="${4}"
ver="${5}"

tiup cluster deploy "${cluster}" "${ver}" "${yaml}"${confirm}
