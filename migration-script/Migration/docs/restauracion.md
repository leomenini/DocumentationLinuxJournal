# Restauración en Debian 13

Referencia para la Fase 4. Antes de cada bloque, confirmar con Leo; verificar nombres de
paquetes con `apt policy` porque esta tabla se armó desde Mint.

## 0. El USB y cómo desempacarlo (leer primero)

El pendrive es **exfat** y se llama `KINGSTON` (no se formateó: tiene también `Backup6.11.26`,
el respaldo de junio, que no se toca). El backup de septiembre está en **tres piezas**:

| Pieza | Qué trae |
|---|---|
| `Backup09-26/` (sueltos) | Los blobs: `Videos`, `Music`, `Pictures`, `Downloads`, `Public`, `Documents`, `Files`, `docker-volumes/`, `postgres/` |
| `Backup09-26/home-chico-09-26.tar.zst` | Los ~208.000 archivos chicos con permisos y symlinks: `devTools`, `.config`, `.local`, `.var`, `.wine`, `go`, `.claude`, `.npm`, y los dotfiles |
| `secretos-09-26.tar.gpg` | Secretos, **cifrado simétrico AES256**: `.ssh`, `.claude.json`, keyrings, `rclone.conf`, `docker-state`, `migration/network`, `migration/netplan`, `tailscaled.state`, `ssh_host_*`, y `/etc` entero (`etc-full/`) |

exfat **no guarda permisos ni ownership**: por eso todo lo que los necesita viaja en un tar.

```bash
U=/media/<user>/KINGSTON            # el USB
B=~/Restore                      # donde se desempaca

mkdir -p "$B" && cd "$B"
# 1. los blobs (ya son archivos, solo copiarlos)
rsync -rtv --info=progress2 "$U/Backup09-26/" "$B/"
# 2. los archivos chicos, con sus permisos originales
zstd -dc "$B/home-chico-09-26.tar.zst" | tar -xv -C "$B"
# 3. los secretos: pide la passphrase (no depende de ninguna clave GPG)
gpg -d "$U/secretos-09-26.tar.gpg" | tar -xv -C "$B"
```

Verificar antes de confiar: `zstd -t "$B/home-chico-09-26.tar.zst"` y
`gpg -d "$U/secretos-09-26.tar.gpg" | tar -tv | head`.

**`/etc` del sistema viejo** queda en `$B/etc-full/etc-09-26.tar.zst`. No se restaura encima del
`/etc` de Debian: se desempaca aparte y se copian piezas sueltas.

```bash
mkdir -p /tmp/etc-viejo && zstd -dc "$B/etc-full/etc-09-26.tar.zst" | tar -x -C /tmp/etc-viejo
```

De ahí salen: `etc/libvirt/qemu/*.xml` (las VMs), `etc/ssh/sshd_config`, `etc/default/grub`,
`etc/apt/sources.list.d/` y `etc/samba/smb.conf` — **como referencia**, no para copiar tal cual
(son de Ubuntu/Mint y apuntan a `noble`).

## 1. Paquetes: de Mint a Debian

Fuente: `$B/migration/apt-agregados.txt`.

| Grupo | Paquetes | Cómo en Debian |
|---|---|---|
| Repos de Debian (`main`) | git, tmux, htop, ncdu, tree, fzf, micro, xclip, eza, zoxide, bat, nala, i3, rofi, compiz, compizconfig-settings-manager, compiz-plugins, compiz-plugins-extra, vlc, gimp, audacity, octave, octave-dev, fpc, imagemagick, pavucontrol, adb, wine, winetricks, openssh-server, python3-pip, python3-venv, npm, uxplay, mangohud, cmatrix, netdiscover, iw, traceroute, xorriso, vainfo, vdpauinfo, msr-tools, cpu-checker, bridge-utils, systemd-container | `apt install`. Verificar cada uno con `apt policy` antes |
| Virtualización | virt-manager, virtinst, virt-viewer, qemu-system-x86, qemu-utils, libvirt-daemon-system, libvirt-clients, ovmf, swtpm, swtpm-tools, python3-libvirt, spice-vdagent, mdevctl | `apt install`; después `sudo usermod -aG libvirt leo` |
| Desarrollo | libssl-dev, libasound2-dev, libdbus-1-dev | `apt install` |
| Idioma | language-pack-es*, hunspell-es, hyphen-es, mythes-es, wspanish, *-l10n-es, *-locale-es | `task-spanish` (+ `task-spanish-desktop`) |
| Repos de proveedores | brave-browser, code, docker-ce + plugins, tailscale, gh, spotify-client | Instrucciones oficiales para Debian de cada proveedor |
| `.deb` externos | urserver, zoom, claude-desktop, omniget | Descargar la versión actual del sitio de cada uno (ver `migration/debs-externos.txt`) |
| `contrib` / `non-free` | steam-installer, lutris, driver NVIDIA, firmware | Ver secciones 4 y 5 |
| No reinstalar | linux-image/headers/modules/tools/hwe-*, linux-firmware-*, nvidia-*-580 y 535, libnvidia-*, mint-meta-xfce, protonvpn-*, postgresql (host, ver sección 9), libs sueltas (libvirt0, libspice-*, etc.) | Son de Ubuntu/Mint o se instalan solas como dependencias |

Snaps y Flatpak: `flatpak` + Flathub, luego `$B/migration/flatpaks.txt`.

## 2. Fuentes de apt

`/etc/apt/sources.list.d/debian.sources` debe incluir `Components: main contrib non-free non-free-firmware`
para `trixie`, `trixie-updates` y `trixie-security`. Después: `sudo apt update`.

## 3. Primeros pasos tras instalar

```bash
sudo apt install curl git rsync cryptsetup
curl -fsSL https://claude.ai/install.sh | bash      # Claude Code
cp -a "$B/migracion" ~/migracion
```

## 4. Driver NVIDIA y firmware

GPU **GeForce GT 1030** (GP108, Pascal) y WiFi USB **MediaTek MT7601U**, los dos identificados
el 11-09. Los paquetes ya están verificados contra packages.debian.org:

```bash
sudo apt install linux-headers-amd64 nvidia-kernel-dkms nvidia-driver \
                 firmware-mediatek firmware-realtek
```

- `nvidia-driver` en trixie **y** en trixie-backports es la misma `550.163.01`: **no hay 580 en
  Debian 13**. La 550 soporta Pascal, pero el wiki de Debian la marca no mantenida, con problemas
  de seguridad, y **no funciona con kernel 6.16+** (trixie trae 6.12, así que anda; el riesgo
  aparece si después se pone un kernel de backports). Si Leo quiere la 580: repo CUDA de NVIDIA
  o el `.run`, con DKMS a mano.
- El flavor **`open` no sirve**: excluye Maxwell, Pascal y Volta. Va el propietario.
- Con Secure Boot: el instalador del módulo DKMS pide enrolar una clave MOK al reiniciar.
- `firmware-mediatek` es el que trae `mt7601u.bin` (**no** `firmware-misc-nonfree`, como decía
  la versión anterior de esta guía). El driver `mt7601u` es in-kernel, así que el 6.12 lo tiene.
- `firmware-realtek` es para la Ethernet RTL8168 integrada, que sirve de red de respaldo si el
  WiFi no levanta en la live.

## 5. Steam y juegos

```bash
sudo dpkg --add-architecture i386 && sudo apt update
sudo apt install steam-installer
apt policy lutris    # si no está en trixie: flatpak install flathub net.lutris.Lutris
```

## 6. Identidad y redes

`.ssh` y los keyrings salen del tar cifrado, así que **ya vienen con sus permisos correctos**
(700/600) y no hace falta `chmod`. **`.gnupg` no se restaura: está vacío, Leo nunca usó GPG.**

```bash
cp -a "$B/.ssh" ~/ && cp -a "$B/.gitconfig" ~/
mkdir -p ~/.local/share && cp -a "$B/.local/share/keyrings" ~/.local/share/
ls -ld ~/.ssh && ls -l ~/.ssh     # confirmar 700 y 600
```

### Redes WiFi — ojo, Mint usaba netplan

Mint 22.3 guardaba los perfiles en `/etc/netplan/90-NM-*.yaml` y NetworkManager generaba copias
efímeras en `/run`. **`/etc/NetworkManager/system-connections/` estaba vacío**: por eso el primer
intento de respaldo copió cero archivos sin dar error.

**Debian no usa netplan.** Lo que sirve son los keyfile `.nmconnection` que quedaron en
`$B/migration/network/` (los 3 `*<ssid>*` y `Wired connection 1`); los `.yaml` de
`$B/migration/netplan/` son **solo referencia** (ahí están los SSID y las PSK en texto si hay
que retipearlas).

```bash
sudo cp "$B/migration/network/"*.nmconnection /etc/NetworkManager/system-connections/
cd /etc/NetworkManager/system-connections/
sudo mv 'netplan-NM-203fd5ce-ab5d-479e-a9f5-740697f52d07-<ssid>%202.4.nmconnection' '<ssid>-2.4.nmconnection'
sudo chown root:root *.nmconnection && sudo chmod 600 *.nmconnection
sudo nmcli connection reload
nmcli connection show
```

Tres cosas que fallan seguido acá:

- El archivo de la red de 2,4 GHz tiene **`%20`** en el nombre (espacio escapado por netplan).
  Renombrarlo y revisar que el campo `id=` adentro diga algo legible.
- Los perfiles traen fijada la interfaz vieja `wlx98ded00d2682` (MAC del adaptador USB). Si el
  nombre de interfaz cambia en Debian, editar `interface-name=` o borrar esa línea.
- **No copiar** los `.nmconnection` de `docker0`, `virbr0`, `br-*`, `lo` ni `tailscale0`: se
  regeneran solos y chocan con los bridges nuevos. Por eso no están en el backup.

Claves de host SSH: están en `$B/migration/ssh-host-keys/` (las 6). Copiarlas a `/etc/ssh/`,
`chmod 600` las privadas y 644 las `.pub`, `sudo systemctl restart ssh`. Evita el aviso de
identidad cambiada al conectarse por el tailnet. `sshd_config` viejo está en `/tmp/etc-viejo`
como referencia — no sobrescribir el de Debian.

## 7. Shell y configuración

- Instalar antes eza, zoxide, fzf, bat, micro, tmux; si no, `.bashrc` puede tirar errores.
- `bat` es `batcat` en Debian: agregar `alias bat=batcat` si `.bashrc` lo usa.
- Copiar `.bashrc`, `.profile`, `.tmux.conf`, `.selected_editor`.
- `.config`: restaurar **selectivamente**, no entero (versiones de Cinnamon distintas):
  `BraveSoftware`, `Code/User`, `rclone`, y lo que Leo elija tras listar `ls $B/.config`.
- `.themes`, `.icons`, `.local/share/fonts` (`fc-cache -f`), `.local/share/cinnamon`.
- VS Code: `xargs -a "$B/migration/vscode-ext.txt" -n1 code --install-extension`
  (o Settings Sync con GitHub).
- Flatpak: `flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`
  y `xargs -a "$B/migration/flatpaks.txt" flatpak install -y flathub`; después copiar `$B/.var`.
- npm global: revisar `npm-global.txt` y reinstalar lo que Leo quiera.

## 8. Docker, Nextcloud y tgpg

Instalar Docker CE desde el repo oficial de Docker para Debian (docs.docker.com/engine/install/debian),
no el paquete `docker.io`. Después `sudo usermod -aG docker leo` y cerrar sesión.

Restaurar un volumen desde su tar:

```bash
restaurar_vol() {  # uso: restaurar_vol NOMBRE_VOLUMEN ARCHIVO.tar.gz
  docker volume create "$1"
  docker run --rm -v "$1":/data -v "$B/docker-volumes":/backup alpine \
    sh -c "cd /data && tar -xzf /backup/$2"
}
```

**Nextcloud** (decidir antes si va en este desktop o en el ThinkCentre):
1. Copiar el directorio del compose manteniendo el nombre `nextcloud` (o fijar `name: nextcloud`).
2. En el compose, cambiar `nextcloud:apache` por el tag exacto de `docker-state/nextcloud-version.txt`
   (ej. `nextcloud:31.0.x-apache`). Postgres queda en `postgres:17`.
3. `restaurar_vol nextcloud_nextcloud-data nextcloud_nextcloud-data.tar.gz`
   y `restaurar_vol nextcloud_postgres-data nextcloud_postgres-data.tar.gz`.
4. `docker compose up -d`, luego:
   ```bash
   docker exec -u www-data nextcloud-nextcloud-1 php occ maintenance:mode --off
   docker exec -u www-data nextcloud-nextcloud-1 php occ maintenance:data-fingerprint
   docker exec -u www-data nextcloud-nextcloud-1 php occ status
   ```
5. Si la IP o el hostname cambian, revisar `trusted_domains` (`occ config:system:get trusted_domains`).
6. Plan B si el volumen de Postgres no arranca: volumen vacío y
   `cat $B/postgres/nextcloud.sql | docker exec -i nextcloud-db-1 sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'`.
7. Recién con todo funcionando, actualizar Nextcloud de a una versión mayor.
8. Probar que GoodNotes (iPad) vuelve a subir su backup — si entra por el tailnet, recién
   después de la sección 10.

**tgpg** (postgres:16, sin compose):
- Leer puertos, variables y montajes de `docker-state/inspect-tgpg.json` (sin mostrar contraseñas en pantalla).
- Opción A: `restaurar_vol tgpg-data tgpg-16ddc356….tar.gz` y `docker run` con `-v tgpg-data:/var/lib/postgresql/data`.
- Opción B: contenedor nuevo vacío y `cat $B/postgres/tgpg.sql | docker exec -i tgpg sh -c 'psql -U "${POSTGRES_USER:-postgres}"'`.

**Volúmenes huérfanos** (`142fac…`, `61ef30…`, `c14d62…`): restaurar solo si Leo los necesita;
para inspeccionarlos: `tar -tzf $B/docker-volumes/<archivo> | head`.

**jarvis-verify**: `docker build` desde su Dockerfile en `devTools`.

## 9. PostgreSQL 18 del host (rol `leo`, base `freecodecamp` — **vacía**)

`freecodecamp` **no tiene ninguna tabla** (verificado el 11-09 con `\dt`): el dump son 3,9 KiB
con el rol y el `CREATE DATABASE`, nada más. No es un dump fallido. El cluster 16 que había en
Mint se ignoró a propósito (era un parche de un tutorial que Leo no usa).

```bash
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
sudo apt install postgresql-18
sudo -u postgres psql -f "$B/postgres/host-pg18.sql"
```

Comparar `pg_hba.conf`/`postgresql.conf` con `migration/etc-postgresql/` y portar solo los cambios.

## 10. Tailscale, Unified Remote, libvirt, Timeshift

**Tailscale.** Si Nextcloud se llega por el nombre HTTPS del tailnet, este bloque va **antes**
de la verificación de `trusted_domains` y de la prueba de GoodNotes de la sección 8.

1. Instalador oficial: `curl -fsSL https://tailscale.com/install.sh | sh`.
2. Identidad del nodo, una de dos (decidido en la Fase 1):
   - **Sin `tailscaled.state` respaldado:** borrar el nodo viejo `<host>` en el panel de
     administración **antes** de `sudo tailscale up`. Si se loguea con el nodo viejo todavía dado
     de alta, el nuevo entra como `<host>-1` y cambian el nombre y el certificado.
   - **Con `tailscaled.state` respaldado:** `sudo systemctl stop tailscaled`, copiar el archivo a
     `/var/lib/tailscale/tailscaled.state` (`chown root:root`, `chmod 600`), `sudo systemctl start tailscaled`.
     El nodo vuelve con el mismo nombre y no hace falta tocar el panel ni volver a loguear.
3. Rehacer los proxies desde `$B/migration/tailscale-serve.txt` (no se restauran solos):
   ```bash
   sudo tailscale serve --bg 8080
   tailscale serve status          # comparar contra el archivo guardado
   ```
   Confirmar el puerto contra el archivo antes de correrlo; 8080 es el de esta máquina.
4. Certificado HTTPS: `sudo tailscale cert <host>.<tailnet>.ts.net` (`serve` suele pedirlo solo;
   esto lo fuerza y sirve para ver el error si falla). Requiere HTTPS habilitado en el tailnet.
5. Nextcloud: verificar que el nombre del tailnet sigue en `trusted_domains`
   (`docker exec -u www-data nextcloud-nextcloud-1 php occ config:system:get trusted_domains`)
   y agregarlo con `config:system:set trusted_domains N --value=...` si falta.
6. Recién ahí, probar que GoodNotes (iPad) vuelve a subir su backup.

- Unified Remote: `.deb` actual de unifiedremote.com; copiar `$B/.urserver`; abrir 9511/9512 si hay firewall.
- libvirt: los XML de las 3 VMs (`archlinux`, `win10`, `zorinOS`) están en
  `/tmp/etc-viejo/etc/libvirt/qemu/`. `sudo virsh define <vm>.xml` y reubicar los discos en
  `/var/lib/libvirt/images` (si se conservaron: no entraban en el pendrive, ver `ESTADO.md`).
  Con btrfs: `sudo chattr +C /var/lib/libvirt/images` **antes** de copiar discos.
- Timeshift: `sudo apt install timeshift`. Modo btrfs solo con layout `@`/`@home`; si no, rsync.
  Pocos snapshots y vigilar espacio (`sudo btrfs filesystem usage /`).

## 11. Archivos personales y Drive

- Restaurar con `rsync -aAXH` **desde `~/Restore`** (ya desempacado) al layout de home acordado
  con Leo — no directamente desde el USB: exfat no tiene los permisos.
- `.wine`: copiar entero (depende de symlinks) y probar un programa.
- Drive: `rclone copy Drive:Backup09-26 ~/Descargas/Backup09-26 -P` y `rclone check` antes de descomprimir.
  Si el client_id compartido ya no funciona, crear uno propio (ver `CLAUDE.md`).
