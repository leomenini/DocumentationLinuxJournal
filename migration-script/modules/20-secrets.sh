#!/usr/bin/env bash
# Secretos: nunca se leen ni se copian en texto plano al destino. Se arma un tar en memoria
# y se cifra directo con gpg simétrico (AES256) — misma técnica que usamos en la Fase 1.
# La passphrase la pide gpg de forma interactiva; esta herramienta nunca la guarda ni la ve.

module_20_secrets() {
  require_cmd gpg
  local out="$DEST/20-secrets"
  mkdir -p "$out"
  local archive="$out/secretos.tar.gpg"

  log "Secretos a cifrar: ${SECRET_PATHS[*]} ${SECRET_ETC_PATHS[*]:-} ${TAILSCALE_STATE:-}"
  local existing=()
  local p
  for p in "${SECRET_PATHS[@]}"; do [[ -e "$p" ]] && existing+=("$p"); done
  for p in "${SECRET_ETC_PATHS[@]:-}"; do [[ -e "$p" ]] && existing+=("$p"); done
  [[ -n "${TAILSCALE_STATE:-}" && -e "$TAILSCALE_STATE" ]] && existing+=("$TAILSCALE_STATE")

  if [[ ${#existing[@]} -eq 0 ]]; then
    warn "no encontré ninguno de los paths de secretos configurados, salteo el módulo"
    return 0
  fi

  log "Te va a pedir una passphrase (gpg) para cifrar el paquete de secretos."
  tar -c --absolute-names "${existing[@]}" 2>/dev/null \
    | gpg --symmetric --cipher-algo AES256 --yes -o "$archive"

  # Solo se guarda un checksum del archivo cifrado y una lista de qué rutas entraron
  # (nombres de archivo, no contenido) — nada sensible.
  printf '%s\n' "${existing[@]}" > "$out/contenidos.txt"
  sha256_dir "$out"
  manifest_record_module "secrets" "20-secrets"
  ok "Secretos cifrados en $archive"
  warn "La passphrase NO queda guardada en ningún lado — anotala vos aparte del backup."
}
