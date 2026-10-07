#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform"
INVENTORY_FILE="$ROOT_DIR/infra/ansible/inventory.ini"

cd "$TF_DIR"
HAPROXY_IP="$(terraform output -raw vm_haproxy_public_ip)"
MICRO_IP="$(terraform output -raw vm_microservices_public_ip)"

if [[ -z "${HAPROXY_IP}" || -z "${MICRO_IP}" ]]; then
  echo "No se pudieron obtener las IPs de salida de Terraform."
  exit 1
fi

if [[ ! -f "$INVENTORY_FILE" ]]; then
  echo "No existe $INVENTORY_FILE. Ejecuta primero terraform apply."
  exit 1
fi

ANSIBLE_USER="$(awk -F= '/^ansible_user=/{print $2}' "$INVENTORY_FILE" | tail -n 1)"
SSH_KEY_PATH="$(awk -F= '/^ansible_ssh_private_key_file=/{print $2}' "$INVENTORY_FILE" | tail -n 1)"

if [[ -z "$ANSIBLE_USER" || -z "$SSH_KEY_PATH" ]]; then
  echo "No se pudo leer ansible_user o ansible_ssh_private_key_file desde inventory.ini"
  exit 1
fi

SSH_OPTS=(-F /dev/null -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new)

echo "[1/3] Verificando servicio HAProxy en ${HAPROXY_IP}..."
HAPROXY_STATUS="$(ssh "${SSH_OPTS[@]}" "${ANSIBLE_USER}@${HAPROXY_IP}" "systemctl is-active haproxy" 2>/dev/null || true)"
if [[ "$HAPROXY_STATUS" != "active" ]]; then
  echo "FAIL: HAProxy no esta activo (status=${HAPROXY_STATUS:-unknown})."
  exit 1
fi
echo "PASS: HAProxy activo."

echo "[2/3] Verificando contenedores en ${MICRO_IP}..."
CONTAINERS="$(ssh "${SSH_OPTS[@]}" "${ANSIBLE_USER}@${MICRO_IP}" "docker ps --format '{{.Names}}' | sort" 2>/dev/null || true)"

for required in users-service products-service orders-service; do
  if ! grep -qx "$required" <<< "$CONTAINERS"; then
    echo "FAIL: No se encontro el contenedor requerido: $required"
    echo "Contenedores actuales:"
    echo "$CONTAINERS"
    exit 1
  fi
done
echo "PASS: Los 3 microservicios estan activos."

echo "[3/3] Huella del entorno (IPs + contenedores)..."
echo "haproxy_ip=$HAPROXY_IP"
echo "microservices_ip=$MICRO_IP"
echo "containers=$(echo "$CONTAINERS" | tr '\n' ',' | sed 's/,$//')"

echo "VALIDACION OK: el entorno aprovisionado esta operativo."
