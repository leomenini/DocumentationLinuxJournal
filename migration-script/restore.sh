#!/usr/bin/env bash
# Restore ASISTIDO: lee un backup hecho con backup.sh y, módulo por módulo, muestra qué hay
# y el comando sugerido para restaurarlo. Nunca instala paquetes ni pisa configs solo —
# vos confirmás cada bloque (Enter = mostrar más detalle / correr, s = saltar).
#
# Uso: ./restore.sh --from /ruta/del/backup [--yes]

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/manifest.sh"

FROM=""
YES=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from) FROM="$2"; shift 2 ;;
    --from=*) FROM="${1#*=}"; shift ;;
    --yes) YES=1; shift ;;
    -h|--help) echo "Uso: $0 --from /ruta/del/backup [--yes]"; exit 1 ;;
    *) die "argumento desconocido: $1" ;;
  esac
done

[[ -n "$FROM" ]] || die "falta --from /ruta/del/backup"
[[ -f "$FROM/manifest.json" ]] || die "no encuentro manifest.json en $FROM"

BACKUP_PKG_MGR=$(jq -r '.pkg_manager' "$FROM/manifest.json")
CURRENT_PKG_MGR=$(detect_pkg_manager)
BACKUP_HOST=$(jq -r '.hostname' "$FROM/manifest.json")
BACKUP_DATE=$(jq -r '.created_at' "$FROM/manifest.json")
BACKUP_OS=$(jq -r '.os_release' "$FROM/manifest.json")

echo
log "Backup de '$BACKUP_HOST' ($BACKUP_OS), hecho el $BACKUP_DATE"
if [[ "$BACKUP_PKG_MGR" != "$CURRENT_PKG_MGR" ]]; then
  warn "Este backup se hizo con '$BACKUP_PKG_MGR' y esta máquina usa '$CURRENT_PKG_MGR'."
  warn "Los nombres de paquete casi seguro NO van a coincidir — tratalos como referencia,"
  warn "no los instales a ciegas."
else
  log "Misma familia de gestor de paquetes ($CURRENT_PKG_MGR) — más chances de que los" \
      "nombres de paquete sirvan tal cual."
fi
echo

step() {
  local title="$1" body="$2"
  echo "── $title ──"
  echo "$body"
  if [[ "$YES" == "1" ]]; then
    echo "(--yes: sigo al próximo paso sin pausar)"
    return
  fi
  read -r -p "Enter para seguir, 's' para saltar el resto > " reply
  [[ "$reply" =~ ^[sS]$ ]] && { warn "resto de pasos saltado por el usuario"; exit 0; }
}

if [[ -d "$FROM/00-inventory" ]]; then
  step "Paquetes" "$(cat <<EOF
Listas en: $FROM/00-inventory/
Gestor original: $BACKUP_PKG_MGR — acá: $CURRENT_PKG_MGR
Revisar a mano cuáles existen en el repo de esta distro antes de instalar, por ejemplo:
  apt-cache policy \$(cat $FROM/00-inventory/apt-manual.txt)   # (si es apt en ambos lados)
Flatpaks: $FROM/00-inventory/flatpaks.txt -> 'flatpak install' uno por uno
VS Code:  $FROM/00-inventory/vscode-extensions.txt -> 'code --install-extension <id>'
EOF
)"
fi

if [[ -d "$FROM/10-dotfiles" ]]; then
  step "Dotfiles y config" "$(cat <<EOF
En: $FROM/10-dotfiles/
Sugerido (revisando conflictos antes, no pisar a ciegas):
  rsync -an $FROM/10-dotfiles/.config/ ~/.config/     # dry-run primero
  rsync -an $FROM/10-dotfiles/.local/share/ ~/.local/share/
EOF
)"
fi

if [[ -d "$FROM/20-secrets" ]]; then
  step "Secretos (cifrados)" "$(cat <<EOF
Archivo: $FROM/20-secrets/secretos.tar.gpg
Contenidos (solo nombres, en $FROM/20-secrets/contenidos.txt):
$(cat "$FROM/20-secrets/contenidos.txt" 2>/dev/null)
Para descifrar (pide la passphrase, que vos guardaste aparte):
  gpg -d $FROM/20-secrets/secretos.tar.gpg | tar -tv   # primero solo listar
  gpg -d $FROM/20-secrets/secretos.tar.gpg | tar -x    # después sí extraer
EOF
)"
fi

if [[ -d "$FROM/30-network" ]]; then
  step "Redes" "$(cat <<EOF
Keyfiles en: $FROM/30-network/keyfiles/ (formato NetworkManager .nmconnection)
  sudo cp $FROM/30-network/keyfiles/*.nmconnection /etc/NetworkManager/system-connections/
  sudo chmod 600 /etc/NetworkManager/system-connections/*.nmconnection
  sudo systemctl restart NetworkManager
(Si la distro nueva usa netplan en vez de NetworkManager nativo, mirar $FROM/30-network/netplan/)
EOF
)"
fi

if [[ -d "$FROM/40-docker" ]]; then
  step "Docker" "$(cat <<EOF
Volúmenes en: $FROM/40-docker/volumes/*.tar.gz
Dumps SQL en: $FROM/40-docker/sql/*.sql
Para cada volumen (crear el volumen vacío primero con 'docker volume create <nombre>'):
  docker run --rm -v <nombre>:/data -v $FROM/40-docker/volumes:/backup alpine \\
    tar xzf /backup/<nombre>.tar.gz -C /data
Después levantar el compose correspondiente y restaurar el SQL si hace falta.
EOF
)"
fi

if [[ -d "$FROM/50-postgres-host" ]]; then
  step "PostgreSQL del host" "$(cat <<EOF
Dump en: $FROM/50-postgres-host/host.sql
  sudo -u postgres psql -f $FROM/50-postgres-host/host.sql
Instalar antes la MISMA versión mayor de PostgreSQL que tenía el host viejo (ver
$FROM/50-postgres-host/etc-postgresql/ para confirmar la versión).
EOF
)"
fi

if [[ -d "$FROM/60-libvirt" ]]; then
  step "libvirt" "$(cat <<EOF
XML en: $FROM/60-libvirt/xml/*.xml
  virsh define $FROM/60-libvirt/xml/<vm>.xml
$( [[ -d "$FROM/60-libvirt/disks" ]] && echo "Discos incluidos en $FROM/60-libvirt/disks/ — copiarlos a /var/lib/libvirt/images/ antes de definir" || echo "Discos NO incluidos en este backup — las VMs se van a reinstalar de cero." )
EOF
)"
fi

if [[ -d "$FROM/70-personal" ]]; then
  step "Archivos personales" "$(cat <<EOF
En: $FROM/70-personal/ (Documents, Videos, devTools, etc.)
  rsync -an $FROM/70-personal/ ~/    # dry-run primero, mirar bien antes de copiar de verdad
EOF
)"
fi

ok "Checklist de restore terminado."
