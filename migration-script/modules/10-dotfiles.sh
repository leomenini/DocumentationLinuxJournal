#!/usr/bin/env bash
# Dotfiles y directorios de config (.config, .local/share, temas, íconos), sin cachés.

module_10_dotfiles() {
  local out="$DEST/10-dotfiles"
  mkdir -p "$out"
  log "Dotfiles y config -> $out"

  local f
  for f in "${DOTFILES[@]}"; do
    [[ -e "$f" ]] && cp -a "$f" "$out/"
  done

  local d rel
  for d in "${DOTDIRS[@]}"; do
    [[ -d "$d" ]] || continue
    # Ruta relativa a $HOME completa (no solo basename): ".local/share" no puede quedar
    # aplanado a "share", si no el restore no sabe dónde va.
    rel="${d#"$HOME"/}"
    mkdir -p "$out/$rel"
    rsync_dr "${DOTDIRS_EXCLUDE[@]}" "$d/" "$out/$rel/"
  done

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "dry-run: no se generan checksums (no se copió nada de verdad)"
    return 0
  fi

  sha256_dir "$out"
  manifest_record_module "dotfiles" "10-dotfiles"
  ok "Dotfiles listos"
}
