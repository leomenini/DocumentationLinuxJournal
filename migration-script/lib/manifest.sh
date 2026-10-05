#!/usr/bin/env bash
# Arma y lee manifest.json — el registro de qué se corrió, con qué versión de la
# herramienta y con qué checksums, para que un backup sea auditable y determinístico.

manifest_init() {
  local dest="$1"
  # Si ya hay un manifest de una corrida anterior (ej. un --only parcial), arrancamos
  # desde ahí en vez de tirarlo: cada módulo que corre ahora reemplaza su propia entrada,
  # pero los módulos que no corrieron esta vez no se pierden.
  if [[ -f "$dest/manifest.json" ]]; then
    MANIFEST_MODULES_JSON=$(jq -c '.modules' "$dest/manifest.json" 2>/dev/null || echo "[]")
  else
    MANIFEST_MODULES_JSON="[]"
  fi
}

# manifest_record_module <nombre> <dir-relativo-a-DEST>
manifest_record_module() {
  local name="$1" reldir="$2"
  local dir="$DEST/$reldir"
  local size checksum_file entry
  size=$(du -sb "$dir" 2>/dev/null | cut -f1)
  size=${size:-0}
  checksum_file="$reldir/checksums.sha256"
  entry=$(jq -n --arg name "$name" --arg dir "$reldir" --arg size "$size" \
    --arg checksums "$checksum_file" \
    '{module:$name, dir:$dir, size_bytes:($size|tonumber), checksums:$checksums}')
  # Reemplaza la entrada existente del mismo módulo (por nombre) en vez de duplicarla.
  MANIFEST_MODULES_JSON=$(jq --argjson e "$entry" \
    '(map(select(.module != $e.module))) + [$e]' <<<"$MANIFEST_MODULES_JSON")
}

manifest_write() {
  local dest="$1"
  local repo_dir tool_commit
  repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  tool_commit=$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || echo "sin-git")

  jq -n \
    --arg created_at "$(date -Iseconds)" \
    --arg hostname "$(hostname)" \
    --arg os_release "$(grep -E '^(NAME|VERSION)=' /etc/os-release 2>/dev/null | tr '\n' ' ')" \
    --arg kernel "$(uname -r)" \
    --arg pkg_manager "$(detect_pkg_manager)" \
    --arg tool_commit "$tool_commit" \
    --argjson modules "$MANIFEST_MODULES_JSON" \
    '{created_at:$created_at, hostname:$hostname, os_release:$os_release, kernel:$kernel,
      pkg_manager:$pkg_manager, tool_commit:$tool_commit, modules:$modules}' \
    > "$dest/manifest.json"
}

detect_pkg_manager() {
  if command -v apt-mark >/dev/null 2>&1; then echo apt
  elif command -v dnf >/dev/null 2>&1; then echo dnf
  elif command -v pacman >/dev/null 2>&1; then echo pacman
  elif command -v zypper >/dev/null 2>&1; then echo zypper
  else echo desconocido
  fi
}

manifest_verify() {
  local dest="$1"
  [[ -f "$dest/manifest.json" ]] || die "no hay manifest.json en $dest"
  local ok=1
  local reldir checksums
  while IFS=$'\t' read -r reldir checksums; do
    local full="$dest/$checksums"
    if [[ ! -f "$full" ]]; then
      warn "falta $checksums (módulo $reldir)"
      ok=0
      continue
    fi
    if [[ ! -s "$full" ]]; then
      ok "checksums OK: $reldir (sin archivos que verificar)"
      continue
    fi
    if (cd "$dest/$reldir" && sha256sum -c checksums.sha256 --quiet) 2>/dev/null; then
      ok "checksums OK: $reldir"
    else
      warn "checksums MAL: $reldir"
      ok=0
    fi
  done < <(jq -r '.modules[] | [.dir, .checksums] | @tsv' "$dest/manifest.json")
  [[ "$ok" == "1" ]]
}
