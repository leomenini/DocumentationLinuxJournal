#!/usr/bin/env bash
# Helpers compartidos por backup.sh, restore.sh y todos los módulos.
# Se cargan con `source`, nunca se ejecutan solos.

set -uo pipefail

RED=$'\033[31m'; YELLOW=$'\033[33m'; GREEN=$'\033[32m'; BLUE=$'\033[34m'; RESET=$'\033[0m'

log()  { printf '%s[*]%s %s\n' "$BLUE" "$RESET" "$*" >&2; }
ok()   { printf '%s[ok]%s %s\n' "$GREEN" "$RESET" "$*" >&2; }
warn() { printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()  { printf '%s[error]%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "falta el comando '$1' (instalalo antes de correr este módulo)"
}

# confirm "mensaje" -> 0 si el usuario dice que sí (o si YES=1), 1 si dice que no.
confirm() {
  local prompt="$1"
  if [[ "${YES:-0}" == "1" ]]; then
    log "$prompt (auto-confirmado por --yes)"
    return 0
  fi
  local reply
  read -r -p "$prompt [s/N] " reply
  [[ "$reply" =~ ^[sS]$ ]]
}

# Guardas de seguridad heredadas de ~/migracion/CLAUDE.md — cualquier módulo que arme un
# comando dinámicamente debe pasar por acá antes de ejecutarlo.
assert_not_destructive() {
  local cmd="$1"
  case "$cmd" in
    *mkfs*|*wipefs*|*parted*|*fdisk*|*sgdisk*|*cryptsetup*|*' dd '*|*dd\ if=*)
      die "comando bloqueado por seguridad (toca discos): $cmd" ;;
    *'docker volume rm'*|*'docker volume prune'*|*'docker system prune'*)
      die "comando bloqueado por seguridad (borra volúmenes Docker): $cmd" ;;
    *'rclone sync'*|*'rclone move'*|*'rclone delete'*|*'rclone purge'*)
      die "comando bloqueado por seguridad (rclone destructivo, usar solo 'rclone copy'): $cmd" ;;
  esac
}

# rm -rf solo dentro del propio $DEST del backup, mostrando la ruta antes.
safe_rm_rf() {
  local path="$1"
  [[ -n "${DEST:-}" ]] || die "safe_rm_rf sin \$DEST seteado, me niego a borrar '$path'"
  case "$path" in
    "$DEST"/*|"$DEST") ;;
    *) die "safe_rm_rf: '$path' está fuera de \$DEST ('$DEST'), me niego a borrarlo" ;;
  esac
  log "Voy a borrar: $path"
  confirm "¿Confirmás el borrado de arriba?" || die "cancelado por el usuario"
  rm -rf -- "$path"
}

# Corre lo que sea (una función, un comando) parando y levantando una lista de contenedores
# de forma segura. Uso: with_containers_stopped "c1 c2" mi_funcion arg1 arg2
with_containers_stopped() {
  local containers="$1"; shift
  local c was_running=()
  for c in $containers; do
    [[ -z "$c" ]] && continue
    local running
    running=$(docker inspect -f '{{.State.Running}}' "$c" 2>/dev/null || echo "false")
    if [[ "$running" == "true" ]]; then
      log "Parando contenedor $c..."
      docker stop "$c" >/dev/null
      was_running+=("$c")
    fi
  done
  "$@"
  for c in "${was_running[@]:-}"; do
    [[ -z "$c" ]] && continue
    log "Levantando contenedor $c de nuevo..."
    docker start "$c" >/dev/null
  done
}

# rsync que respeta $DRY_RUN globalmente (agrega -n en vez de copiar de verdad).
rsync_dr() {
  local flags=(-a)
  [[ "${DRY_RUN:-0}" == "1" ]] && flags=(-an)
  rsync "${flags[@]}" "$@"
}

sha256_dir() {
  local dir="$1"
  # -r/--no-run-if-empty: si no hay archivos, no correr sha256sum en absoluto (si no,
  # xargs lo invoca igual una vez sin argumentos y termina hasheando stdin por error).
  (cd "$dir" && find . -type f ! -name checksums.sha256 -print0 | sort -z | xargs -r -0 sha256sum) \
    > "$dir/checksums.sha256"
}
