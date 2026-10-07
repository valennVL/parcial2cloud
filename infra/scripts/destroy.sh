#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform"

if ! command -v az >/dev/null 2>&1; then
	echo "Error: Azure CLI (az) no esta instalado en este nodo."
	echo "Instalalo y ejecuta az login antes de correr destroy.sh"
	exit 1
fi

if ! az account show >/dev/null 2>&1; then
	echo "Error: no hay sesion activa en Azure CLI."
	echo "Ejecuta: az login"
	exit 1
fi

cd "$TF_DIR"
terraform destroy -auto-approve

echo "Infraestructura eliminada con terraform destroy."
