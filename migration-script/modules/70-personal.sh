#!/usr/bin/env bash
# Archivos personales grandes. Con --dry-run (heredado de backup.sh) usa `rsync -n` y solo
# reporta tamaños; sin dry-run hace la copia real.

module_70_personal() {
  local out="$DEST/70-personal"
  mkdir -p "$out"
  local entry src reldir rsync_flags=(-a --info=progress2)

  [[ "${DRY_RUN:-0}" == "1" ]] && rsync_flags=(-an)

  for entry in "${PERSONAL_DIRS[@]:-}"; do
    [[ -z "$entry" ]] && continue
    IFS=: read -r src reldir <<<"$entry"
    if [[ ! -d "$src" ]]; then
      warn "no existe $src, salteo"
      continue
    fi
    log "Personal: $src -> $out/$reldir"
    mkdir -p "$out/$reldir"
    rsync "${rsync_flags[@]}" "$src/" "$out/$reldir/"
  done

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "dry-run: no se generan checksums (no se copió nada de verdad)"
    return 0
  fi

  sha256_dir "$out"
  manifest_record_module "personal" "70-personal"
  ok "Archivos personales listos"
}
