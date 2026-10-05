#!/usr/bin/env bash
# Perfiles de red. Detecta si NetworkManager usa netplan de backend (como Mint: los
# keyfiles reales viven efímeros en /run, no en /etc/NetworkManager) o si ya está en modo
# nativo (como Debian: los keyfiles persistentes están directo en /etc/NetworkManager).

_copy_nmconnections() {
  local src_dir="$1" dest_dir="$2"
  local f needs_sudo=0
  find "$src_dir" -name '*.nmconnection' -print0 | while IFS= read -r -d '' f; do
    basename "$f" | grep -Eq "$NETWORK_SKIP_PATTERN" && continue
    if [[ ! -r "$f" ]]; then
      warn "sin permiso para leer $f (necesita root)"
      continue
    fi
    cp -a "$f" "$dest_dir/"
  done
}

module_30_network() {
  local out="$DEST/30-network"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "dry-run: simularía copia de perfiles de red (archivos chicos, no hace falta simular)"
    return 0
  fi

  mkdir -p "$out/keyfiles"

  local nm_dir="/etc/NetworkManager/system-connections"
  local run_dir="/run/NetworkManager/system-connections"

  if [[ "$EUID" -ne 0 ]] && [[ -d "$nm_dir" ]] && find "$nm_dir" -name '*.nmconnection' -print -quit 2>/dev/null | grep -q .; then
    warn "los .nmconnection reales (con las claves WiFi) solo los puede leer root."
    warn "Re-correr este módulo con: sudo $0 --dest \"\$PWD_ABS\" --only=30-network"
    warn "(sin sudo, sigo igual para no cortar el resto del backup, pero va a quedar vacío)"
  fi

  if [[ -d "$nm_dir" ]] && find "$nm_dir" -name '*.nmconnection' -print -quit 2>/dev/null | grep -q .; then
    log "NetworkManager en modo nativo, copiando de $nm_dir"
    _copy_nmconnections "$nm_dir" "$out/keyfiles"
  elif [[ -d "$run_dir" ]]; then
    warn "NetworkManager parece usar netplan de backend (keyfiles persistentes vacíos en" \
         "$nm_dir); tomo los efímeros de $run_dir, que es lo que sirve al restaurar."
    _copy_nmconnections "$run_dir" "$out/keyfiles"
    if [[ -d /etc/netplan ]]; then
      mkdir -p "$out/netplan"
      cp -a /etc/netplan/*.yaml "$out/netplan/" 2>/dev/null || true
    fi
  else
    warn "no encontré perfiles de NetworkManager en ninguno de los dos lugares esperados"
  fi

  sha256_dir "$out"
  manifest_record_module "network" "30-network"
  ok "Perfiles de red guardados"
}
