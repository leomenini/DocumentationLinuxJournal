#!/usr/bin/env bash
# Inventario de paquetes y herramientas instaladas: todo lo que en la migración Mint→Debian
# guardamos en migration/*.txt a mano. No copia binarios, solo listas de texto.

module_00_inventory() {
  local out="$DEST/00-inventory"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "dry-run: simularía inventario de paquetes/herramientas en $out (listas de texto," \
        "escritura despreciable, no hace falta simular de verdad)"
    return 0
  fi

  mkdir -p "$out"
  log "Inventario de paquetes y herramientas -> $out"

  case "$(detect_pkg_manager)" in
    apt)
      apt-mark showmanual | sort > "$out/apt-manual.txt"
      dpkg --get-selections | sort > "$out/dpkg-selections.txt"
      find /etc/apt/sources.list.d -type f 2>/dev/null | sort > "$out/apt-sources-list.txt"
      [[ -f /etc/apt/sources.list ]] && cp /etc/apt/sources.list "$out/apt-sources.list"
      ;;
    dnf)
      dnf repoquery --userinstalled 2>/dev/null | sort > "$out/dnf-userinstalled.txt"
      ;;
    pacman)
      pacman -Qe 2>/dev/null | sort > "$out/pacman-explicit.txt"
      ;;
    *)
      warn "gestor de paquetes desconocido, salteo el inventario de paquetes del sistema"
      ;;
  esac

  command -v flatpak >/dev/null 2>&1 && flatpak list --app --columns=application 2>/dev/null | sort > "$out/flatpaks.txt"
  command -v npm >/dev/null 2>&1 && npm ls -g --depth=0 2>/dev/null > "$out/npm-global.txt"
  command -v code >/dev/null 2>&1 && code --list-extensions > "$out/vscode-extensions.txt"
  [[ -d "$HOME/go/bin" ]] && ls "$HOME/go/bin" > "$out/go-bin.txt"
  [[ -d "$HOME/.local/bin" ]] && ls "$HOME/.local/bin" > "$out/local-bin.txt"

  systemctl list-unit-files --user --state=enabled --no-legend 2>/dev/null > "$out/systemd-user-units.txt"
  systemctl list-unit-files --state=enabled --no-legend 2>/dev/null > "$out/systemd-system-units.txt"
  crontab -l > "$out/crontab.txt" 2>/dev/null || true

  cp /etc/fstab "$out/fstab" 2>/dev/null || true
  cp /etc/hosts "$out/hosts" 2>/dev/null || true
  cp /etc/os-release "$out/os-release" 2>/dev/null || true
  uname -a > "$out/uname.txt"

  sha256_dir "$out"
  manifest_record_module "inventory" "00-inventory"
  ok "Inventario listo"
}
