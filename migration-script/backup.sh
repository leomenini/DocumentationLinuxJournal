#!/usr/bin/env bash
# Backup determinístico y re-ejecutable, pensado para el próximo salto de distro.
# Uso:
#   ./backup.sh --dest /ruta/destino [--dry-run] [--yes] [--only=modulo1,modulo2]
#   ./backup.sh --verify /ruta/destino
#
# Ver README.md para el detalle de cada módulo y config/paths.conf para qué se respalda.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/manifest.sh
source "$SCRIPT_DIR/lib/manifest.sh"
# shellcheck source=config/paths.conf
source "$SCRIPT_DIR/config/paths.conf"

DEST=""
DRY_RUN=0
YES=0
ONLY=""
VERIFY_ONLY=""

usage() {
  grep '^#' "$0" | sed -n '2,7p' | sed 's/^# \{0,1\}//'
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest) DEST="$2"; shift 2 ;;
    --dest=*) DEST="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --yes) YES=1; shift ;;
    --only) ONLY="$2"; shift 2 ;;
    --only=*) ONLY="${1#*=}"; shift ;;
    --verify) VERIFY_ONLY="$2"; shift 2 ;;
    --verify=*) VERIFY_ONLY="${1#*=}"; shift ;;
    -h|--help) usage ;;
    *) die "argumento desconocido: $1 (usá --help)" ;;
  esac
done

if [[ -n "$VERIFY_ONLY" ]]; then
  DEST="$VERIFY_ONLY"
  log "Verificando backup en $DEST"
  manifest_verify "$DEST" && ok "Todo OK" || die "hay checksums que no coinciden"
  exit 0
fi

[[ -n "$DEST" ]] || { warn "falta --dest"; usage; }

MODULES=(00-inventory 10-dotfiles 20-secrets 30-network 40-docker 50-postgres-host 60-libvirt 70-personal)
if [[ -n "$ONLY" ]]; then
  IFS=',' read -r -a MODULES <<<"$ONLY"
fi

if [[ "$DRY_RUN" == "1" ]]; then
  warn "DRY-RUN: no se escribe nada persistente salvo el reporte en \$DEST (los módulos de" \
       "secretos y docker se saltean del todo en dry-run, no tiene sentido simularlos)."
fi

mkdir -p "$DEST"
manifest_init "$DEST"

log "Backup -> $DEST (hostname=$(hostname), pkg_manager=$(detect_pkg_manager))"

for m in "${MODULES[@]}"; do
  src="$SCRIPT_DIR/modules/${m}.sh"
  [[ -f "$src" ]] || { warn "módulo desconocido: $m, salteo"; continue; }
  # shellcheck disable=SC1090
  source "$src"
  fn="module_${m//-/_}"

  if [[ "$DRY_RUN" == "1" && "$m" =~ ^(20-secrets|40-docker)$ ]]; then
    log "dry-run: salteo módulo $m (destructivo/interactivo, no tiene modo simulación seguro)"
    continue
  fi

  log "=== Módulo: $m ==="
  "$fn"
done

if [[ "$DRY_RUN" != "1" ]]; then
  manifest_write "$DEST"
  ok "manifest.json escrito en $DEST"
  log "Corré './backup.sh --verify $DEST' para chequear los checksums."
else
  ok "dry-run terminado, no se escribió manifest.json"
fi
