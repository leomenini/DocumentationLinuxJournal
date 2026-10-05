<!-- Mantener este archivo por debajo de ~200 líneas: se carga entero en cada sesión.
     El detalle va en ESTADO.md (checklist) y docs/restauracion.md (se leen a demanda). -->

# Proyecto: migración de Linux Mint 22.3 a Debian 13 (o LMDE 7)

Leo migra su desktop personal de Linux Mint 22.3 (base Ubuntu 24.04 noble) a una distro
basada en Debian. Este directorio (`~/migracion`) coordina el backup, la prueba de hardware,
la instalación y la restauración.

**Al empezar cada sesión:** leé `ESTADO.md` y retomá desde el primer `[ ]`.
**Al terminar un paso:** marcalo `[x]` en `ESTADO.md` con una nota corta (fecha, resultado).

## Cómo trabajar con Leo

- Respondé en español rioplatense (voseo).
- En decisiones de diseño (distro, particionado, dónde vive cada servicio): presentá
  alternativas con trade-offs y discutí. No elijas ni ejecutes por tu cuenta.
- Si una tecnología es nueva para Leo, explicá el contexto antes de pedirle que elija.
- Antes de cada comando, una línea sobre qué hace. Si hay modo prueba, usalo primero
  (`rsync -n`, `rclone --dry-run`, `apt -s`).
- Tus datos sobre Debian pueden estar desactualizados: verificá disponibilidad y versión de
  paquetes con `apt policy <pkg>` o packages.debian.org antes de afirmarlas.
- Nivel: estudiante de ingeniería físico-matemática, programa (Pascal, JS/TS, Python, Go),
  usa Docker, QEMU/KVM, tmux y Claude Code. No expliques lo básico de terminal.

## Reglas de seguridad (no negociables)

- **Nunca** formatear, particionar ni cifrar discos sin que Leo lo pida explícitamente en
  ese mismo turno: `mkfs`, `wipefs`, `parted`, `fdisk`, `sgdisk`, `cryptsetup`, `dd`.
- **Nunca** `docker volume rm/prune`, `docker system prune`, `rclone sync/move/delete/purge`.
  Para subir a Drive se usa solo `rclone copy`.
- `rm -rf` solo dentro de `~/Backup` o `/tmp`, mostrando antes la ruta exacta con `ls`/`du`.
- No leer el contenido de secretos: `.ssh/`, `.gnupg/`, `.claude.json`, `rclone.conf`,
  `migration/system-connections/`, archivos `.env`. Solo verificar existencia/permisos con `ls -l`.
- Los secretos nunca van a Google Drive ni a repos. Drive recibe solo lo no privado.
- No tocar el disco interno (`nvme0n1`) hasta que todo el bloque "Fase 1" de `ESTADO.md`
  esté en `[x]`.
- Bases de datos: dump con el contenedor corriendo; `tar` de volúmenes con el contenedor
  parado; al terminar, volver a levantar Nextcloud y desactivar el modo mantenimiento.
- `.claude/settings.json` bloquea parte de esto, pero no todo (p. ej. comandos envueltos en
  scripts). Las reglas de arriba aplican siempre.

## La máquina actual

- Host `<host>`, IP LAN <ip-lan>, red por **adaptador WiFi USB**: Ralink/MediaTek
  **MT7601U** (`148f:7601`). Driver `mt7601u` in-kernel desde 4.2; firmware en `firmware-mediatek`.
  También hay Ethernet Realtek RTL8168 integrada (`10ec:8168`) como respaldo si el WiFi falla.
- **GPU NVIDIA GeForce GT 1030** (GP108, Pascal, `10de:1d01`), driver 580.173.02 en Mint.
- Kernels HWE 6.17 y 7.0 instalados (3 actualizaciones de kernel en 2 meses; bugs menores
  que desaparecían al reiniciar → motivo principal de la migración: estabilidad).
- Disco único `nvme0n1`: `p1` vfat 512M `/boot/efi`; `p2` ext4 con `/` **y `/home` juntos**
  (no hay `/home` separado → instalar borra todo). `sr0` es lectora óptica.
- Timeshift diario, pero en el mismo disco: se pierde al formatear, no sirve de respaldo.
- Escritorio: Cinnamon a diario; también XFCE + Compiz (Compiz no funciona con Cinnamon),
  i3 y rofi instalados.
- Servicios en uso: Docker (Nextcloud + Postgres), Tailscale, libvirt/virt-manager,
  openssh-server, Unified Remote (`urserver`, puertos 9511/9512), PostgreSQL 18 del host.
- Shell: bash con eza, zoxide, bat, fzf, micro, nala, tmux (`.bashrc` puede depender de ellos).

## Estado del backup (10-09-2026)

Todo en `~/Backup` (≈26 GiB tras recortar cachés). Contenido:

- **Personal:** `Documents`, `Pictures`, `Videos`, `Music`, `Downloads`, `Public`, `devTools`
  (repos), `GameMakerProjects`, `go`, `docker` (compose y bind mounts).
- **Identidad y config:** `.ssh`, `.gnupg`, `.gitconfig`, `.local/share/keyrings`, `.android`,
  `.bashrc`, `.profile`, `.tmux.conf`, `.config` (incluye Brave, VS Code `Code/User`,
  `rclone/rclone.conf`), `.themes`, `.icons`, `.local/share/fonts`, `.local/share/cinnamon`,
  `.urserver`, `.wine`, `.var` (datos Flatpak, sin caché).
- **Herramientas IA:** `.claude`, `.claude.json`, `.gemini`, `.copilot`, `.opencode`, `.mcp`.
- **`postgres/`:** `tgpg.sql` (pg_dumpall, 257 tablas), `nextcloud.sql` (pg_dump, 131 tablas).
- **`docker-volumes/`** (verificados con `gzip -t`): `nextcloud_nextcloud-data.tar.gz` (1,4G),
  `nextcloud_postgres-data.tar.gz`, `tgpg-16ddc356….tar.gz` (volumen de `tgpg`), y tres
  volúmenes anónimos huérfanos (`142fac…`, `61ef30…`, `c14d62…`, posibles bases viejas).
- **`docker-state/`:** `containers.txt`, `df.txt`, `inspect-*.json` (contienen contraseñas),
  `nextcloud-version.txt` (versión exacta de Nextcloud).
- **`migration/`:** `apt-agregados.txt` (227 paquetes agregados sobre la instalación de Mint:
  la lista útil), `apt-manual.txt` (2116, casi todo base de Mint: solo referencia),
  `apt-repos.txt`, `flatpaks.txt`, `vscode-ext.txt`, `npm-global.txt`, `local-bin.txt`,
  `user-units.txt`, `system-units.txt`, `fstab`, `hosts`, `system-connections/` (WiFi con claves).

**Google Drive** (cuenta de 5 TB), remoto rclone `Drive:`:
- `Drive:Backup09-26` ← `~/Desktop/Files/n/backing-up` (70 GiB, 11 archivos
  comprimidos del Desktop). Subida en curso en tmux; falta `rclone check --one-way`.
- El remoto usa el client_id compartido de rclone, que Google retira durante 2026. Sirve para
  esta subida puntual. Si deja de funcionar: crear client_id propio (hay un proyecto GCP
  `rclone-508215` a medio configurar; la app quedó en "Prueba" y agregar testers falló).

**Fuera de `~/Backup`:** `PC legacy` tiene copia en un disco externo aparte. No tocar.

**Descartado a propósito (no respaldar ni sugerir):** juegos de Steam, Zomboid, Hytale,
PrismLauncher, VirtualBox VMs, **los discos de las VMs de libvirt** (52 GiB en
`/var/lib/libvirt/images`: `archlinux`, `win10`, `zorinOS` — descartados el 11-09; los XML sí se
guardaron en `etc-full/`, se redefinen con `virsh define` y se reinstalan), `.lmstudio`, Ollama,
ProtonVPN, servidor RustDesk,
VSCodium, devcontainers `vsc-rdb-alpha-*` y volumen `vscode`, volúmenes del tutorial de
Docker (`todo-*`, `getting-started*`), imágenes oficiales de Docker, build cache, cachés.
La imagen `jarvis-verify` se reconstruye: su Dockerfile está en `devTools`.

## Decisiones pendientes (discutir con Leo, no decidir)

1. **Debian 13 puro vs LMDE 7.** Recomendación previa: Debian puro (Leo quiere estabilidad
   y aprender; LMDE es "Mint sobre Debian"). Leo aún no confirmó.
2. **Particionado:** ext4 con `/` y `/home` separados (simple) vs btrfs con `@`/`@home`
   (snapshots baratos, más trabajo en la instalación; ver hechos abajo).
3. **Dónde vive Nextcloud:** en este desktop o en el ThinkCentre M910q Tiny que Leo compró
   para homelab 24/7 (también con Debian).
4. **Swap:** archivo o partición (con btrfs, partición es más simple).
5. **Driver NVIDIA (nuevo, 11-09):** aceptar la 550 de trixie (vieja e insegura pero empaquetada
   y mantenida por Debian, anda con el kernel 6.12) vs instalar la 580 desde el repo CUDA de NVIDIA
   o el `.run` (soporte al día, pero DKMS a mano y hay que enrolar MOK con Secure Boot).
   Para una GT 1030 en escritorio la 550 alcanza de sobra en rendimiento; es una decisión de
   seguridad y de mantenimiento, no de FPS.
6. **Organización del home** tras restaurar: `~/Projects`, `~/Docker`, `~/Archive`,
   `~/.local/bin` para scripts; dotfiles en un repo git plano (sin Stow ni chezmoi).

## Hechos verificados (septiembre 2026)

- Debian 13 "trixie": última versión menor 13.6 (11-07-2026). Kernel 6.12 LTS.
- LMDE 7 "Gigi": base Debian 13, kernel 6.12 LTS, solo Cinnamon; no recibe saltos de
  kernel ni de drivers mayores dentro de la misma versión.
- Instalador de Debian con btrfs crea el subvolumen `@rootfs`, no `@`. Timeshift en modo
  btrfs **exige** `@` y `@home` → hay que ajustar subvolúmenes, `fstab` y GRUB a mano.
- `nvidia-driver` en trixie y en trixie-backports es la **misma** `550.163.01` (non-free):
  **no hay 580 empaquetada en Debian 13**. La 550 sí soporta Pascal (la GT 1030 entra), pero el
  wiki de Debian la marca no mantenida, con problemas de seguridad, y **no funciona con kernel 6.16+**
  (trixie trae 6.12, así que anda; el problema aparece si se usa un kernel de backports).
  El flavor `open` **no sirve**: excluye Maxwell, Pascal y Volta. Va el propietario.
  Alternativa si Leo quiere la 580: el instalador `.run` de NVIDIA o el repo CUDA de NVIDIA para
  Debian 13 — más frágil con DKMS y Secure Boot, pero es la única vía a una rama con soporte.
- `compiz` 0.8.18 (Compiz Reloaded) está en trixie. Funciona con XFCE/MATE, no con Cinnamon.
- Debian 13 trae PostgreSQL 17. El host tenía 18 → usar el repo PGDG para instalar la 18.
- Mint 22.3 usa **netplan** de backend de NetworkManager: los perfiles de red viven en
  `/etc/netplan/90-NM-*.yaml` y las copias en `/run/NetworkManager/system-connections/` son
  efímeras (se borran al reiniciar). `/etc/NetworkManager/system-connections/` está vacío.
  **Debian 13 no usa netplan**: espera keyfiles `.nmconnection` en `/etc/NetworkManager/system-connections/`
  con permisos 600. Los `.nmconnection` de `/run` sirven tal cual en Debian; los `.yaml` no.
- Firmware en Debian: paquetes `firmware-*` de `non-free-firmware` (no `linux-firmware-*`).
  Para este equipo: **`firmware-mediatek`** (WiFi MT7601U) y `firmware-realtek` (Ethernet RTL8168).
- En Debian, `bat` se ejecuta como `batcat`. `lutris` está en `contrib`: verificar con
  `apt policy lutris` en trixie; si falta, usar Flatpak.
- Claude Code: `curl -fsSL https://claude.ai/install.sh | bash` (también hay paquete apt).
- `nextcloud:apache` es un tag flotante. Nextcloud no salta versiones mayores: restaurar
  con el tag exacto de `docker-state/nextcloud-version.txt` y actualizar después.
- Volúmenes de Compose se nombran `<proyecto>_<volumen>`: el directorio del compose debe
  seguir llamándose `nextcloud` (o fijar `name: nextcloud`) para reusar los nombres.

## Documentación: bitácora en GitHub

Leo documenta lo que hace en **https://github.com/leomenini/DocumentationLinuxJournal**, un repo
**público**.

- Al llegar a la Fase 4 (restauración), leer de ese repo antes de tocar nada:
  - `nextcloud-tailscale-goodnotes-setup.md` — cómo quedó armado el circuito Nextcloud + Tailscale + GoodNotes.
  - `postgreSQL_Conflicts.md` — conflictos de PostgreSQL que Leo ya resolvió una vez.
- Al terminar cada fase, proponerle a Leo una entrada de bitácora para ese repo. Proponer, no
  commitear: el texto se le muestra y él decide.
- Como el repo es público, la entrada **no** lleva: IPs (ni LAN ni tailnet), nombres de tailnet o
  de nodos `*.ts.net`, hostnames, usuarios, contraseñas, tokens, rutas con datos personales,
  contenido de `inspect-*.json` ni nada de `migration/system-connections/`. Van conceptos,
  comandos y errores con los valores reemplazados por marcadores (`<host>`, `<tailnet>`).

## Archivos de este proyecto

- `ESTADO.md`: checklist por fases. Fuente de verdad del avance.
- `docs/restauracion.md`: tabla de paquetes Mint → Debian y procedimientos de restauración
  (Docker, Nextcloud, Postgres, claves, redes, Tailscale). Leer al llegar a la Fase 4.
- `.claude/settings.json`: permisos (pide confirmación para `sudo`/`rm`, bloquea comandos
  destructivos y lectura de secretos).
