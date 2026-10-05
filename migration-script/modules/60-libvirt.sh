#!/usr/bin/env bash
# XML de cada VM definida en libvirt. Los discos NO se respaldan por default (52 GiB la vez
# pasada, no valía la pena en un USB) — activar LIBVIRT_INCLUDE_DISKS=true en paths.conf si
# alguna vez hace falta, con espacio de sobra en el destino.

module_60_libvirt() {
  if ! command -v virsh >/dev/null 2>&1; then
    warn "virsh no está instalado, salteo el módulo de libvirt"
    return 0
  fi
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "dry-run: simularía volcado de XML de VMs (archivos chicos, no hace falta simular)" \
        "-- discos: $([[ "${LIBVIRT_INCLUDE_DISKS:-false}" == "true" ]] && echo 'SÍ se copiarían, revisar espacio' || echo 'no incluidos')"
    return 0
  fi
  local out="$DEST/60-libvirt"
  mkdir -p "$out/xml"

  local vm
  for vm in $(virsh list --all --name 2>/dev/null); do
    [[ -z "$vm" ]] && continue
    virsh dumpxml "$vm" > "$out/xml/${vm}.xml"
    log "XML guardado: $vm"
  done

  virsh net-list --all --name 2>/dev/null | while read -r net; do
    [[ -z "$net" ]] && continue
    virsh net-dumpxml "$net" > "$out/xml/network-${net}.xml"
  done

  if [[ "${LIBVIRT_INCLUDE_DISKS:-false}" == "true" ]]; then
    warn "LIBVIRT_INCLUDE_DISKS=true: esto puede ser MUY pesado, confirmá antes de seguir"
    if confirm "¿Copiar también los discos de /var/lib/libvirt/images?"; then
      mkdir -p "$out/disks"
      rsync -a --info=progress2 /var/lib/libvirt/images/ "$out/disks/"
    fi
  else
    log "LIBVIRT_INCLUDE_DISKS=false: solo XML, discos no incluidos (ver paths.conf)"
  fi

  sha256_dir "$out"
  manifest_record_module "libvirt" "60-libvirt"
  ok "libvirt listo"
}
