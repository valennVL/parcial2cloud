#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform"
ANSIBLE_DIR="$ROOT_DIR/infra/ansible"
IMAGE_TAG="${IMAGE_TAG:-v1.0}"

if ! command -v az >/dev/null 2>&1; then
	echo "Error: Azure CLI (az) no esta instalado en este nodo."
	echo "Instalalo y ejecuta az login antes de correr provision.sh"
	exit 1
fi

if ! az account show >/dev/null 2>&1; then
	echo "Error: no hay sesion activa en Azure CLI."
	echo "Ejecuta: az login"
	exit 1
fi

cd "$TF_DIR"
terraform init
terraform apply -auto-approve -var="image_tag=${IMAGE_TAG}"

cd "$ANSIBLE_DIR"
ansible-playbook -i inventory.ini site.yml

echo "Provision completo: Terraform + Ansible finalizados correctamente."
