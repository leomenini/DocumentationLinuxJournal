# Estado de la migración

Marcar `[x]` al completar, con fecha y resultado breve. No saltar de fase sin cerrar la anterior.

## Fase 1: Backup (antes de formatear)

- [x] `~/Backup` armado con archivos personales, claves, config y herramientas IA (10-09)
- [x] Recorte de cachés en `.local` y `.var`: de 55 a ≈26 GiB (10-09)
- [x] Dump `tgpg` → `postgres/tgpg.sql`, 257 tablas (10-09)
- [x] Dump Nextcloud → `postgres/nextcloud.sql`, 131 tablas; versión en `docker-state/nextcloud-version.txt` (10-09)
- [x] 6 volúmenes Docker en `docker-volumes/`, verificados con `gzip -t` (10-09)
- [x] Inventario en `migration/` (apt-agregados, flatpaks, vscode-ext, units, fstab, hosts) (10-09)
- [x] Redes WiFi respaldadas (11-09). Costó encontrarlas: Mint usa **netplan** de backend, así que
      `/etc/NetworkManager/system-connections/` está **vacío** y el primer `cp` copió nada sin dar error.
      Los perfiles viven en `/etc/netplan/90-NM-*.yaml` (3 WiFi, 600, con las PSK) y NM genera copias
      **efímeras** en `/run/NetworkManager/system-connections/`. Guardados los 4 `.nmconnection` de
      `/run` en `migration/network/` (lo que sirve en Debian) y los `.yaml` en `migration/netplan/`
- [x] `.gnupg` **no hace falta respaldar**: está vacío también en el home real (nunca se usó GPG).
      Sacado de la lista de secretos (11-09)
- [x] `rclone.conf` copiado a `~/Backup/.config/rclone/` (10-09)
- [x] Nextcloud levantado y modo mantenimiento en `disabled` (verificado 11-09: `Maintenance mode is currently disabled`; contenedores `nextcloud-nextcloud-1` y `nextcloud-db-1` Up)
- [x] Subida `Drive:Backup09-26` **cerrada por decisión de Leo** (11-09): cortó el `rclone copy` a propósito.
      Subieron 9 de 11 archivos (~44,6 GiB de 70,6 GiB). Faltan a propósito y no se van a subir:
      `Lust Theory Season 2 final.rar` (21 GiB) y `MidnightParadise-1.1b-pc-elite.zip` (8,5 GiB)
- [x] `rclone check --one-way` **no aplica**: la subida es parcial por decisión. Verificado con `rclone lsl Drive:Backup09-26`:
      los 9 archivos están arriba con su tamaño completo (11-09)
- [x] **PostgreSQL 18 del host** listo (11-09): `postgres/host-pg18.sql` (3,9K) con `CREATE ROLE leo` y
      `CREATE DATABASE freecodecamp`, más `/etc/postgresql` en `migration/etc-postgresql` (clusters 16 y 18).
      El dump no tiene datos porque **`freecodecamp` no tiene ninguna tabla** (verificado con `\dt`): está vacío
      de verdad, no es un dump fallido. El cluster 16 se ignora (parche de un tutorial que Leo no usa)
- [x] **libvirt: los discos de las VMs se DESCARTAN** (decidido por Leo 11-09). Son 52 GiB en
      `/var/lib/libvirt/images` y no entraban en el USB. Se pierde el **contenido** de `archlinux`,
      `win10` y `zorinOS`; los **XML sí están salvados** en `etc-full/` (`etc/libvirt/qemu/*.xml`),
      así que en Debian se redefinen con `virsh define` y se reinstala el sistema de cada una
- [x] Tailscale: guardados `migration/tailscale-serve.txt` y `.json` (11-09).
      Config: un solo proxy, `https://<host>.<tailnet>.ts.net/` → `http://127.0.0.1:8080` (Nextcloud), tailnet-only
- [x] `tailscaled.state` respaldado en `migration/tailscale-state/` (11-09). Es secreto → va solo en el tar cifrado
- [x] Claves de host SSH en `migration/ssh-host-keys/` (11-09): las 6 (ecdsa, ed25519, rsa + .pub). Secreto → tar cifrado
- [~] `devTools`: 10 repos con trabajo sin guardar (11-09). **Leo decide y pushea:**
      `Heard/heard` DIRTY(4) + 5 commits sin push ← el único con commits sin subir
      `jarvis/jarvisAssistant` DIRTY(1) + SIN UPSTREAM ← no tiene remoto, si no se pushea se pierde
      `jarvis/jarvis0.01` DIRTY(10), `Tgchatbot/TgChatbot` DIRTY(10), `JSDEV/jscamp` DIRTY(3),
      `octaveDev/Octave` DIRTY(1), `freecodecamp/BinBashWorkshop/rdb-alpha` DIRTY(2),
      `freecodecamp/studentsDB/rdb-alpha` DIRTY(1), `freecodecamp/universeDBSQL/rdb-alpha-fresh` DIRTY(1),
      `freecodecamp/universeDBSQL/universeDB` DIRTY(1)
      (el `rsync` a `~/Backup` ya copió los working trees, así que nada se pierde aunque no se pushee;
      pushear es para no depender del USB)
- [x] `devTools`: 7 `.env` reales + 3 `.env.example` (11-09, solo rutas, sin leer contenido):
      `goodnotesOCR`, `kiosco/CronExtractor`, `Tgchatbot/{TgChatbot,TgChatbot-turno,TgChatbot-imagenes}`,
      `JSDEV/jscamp/{04-node, 07-inteligencia-artificial/frontend, 05-testing/ai-e2e-test}`.
      Son secretos: van al USB cifrado, no a Drive ni a los repos
- [x] Listas extra en `migration/herramientas-extra.txt` (11-09): uv sin tools instaladas, pipx no instalado,
      sin `.cargo` (no hay rustup), `~/go/bin`: lazydocker + lazygit,
      `~/.local/bin`: agy, claude, git-filter-repo, glab, rclone, tectonic, uv, uvx
- [x] `migration/debs-externos.txt` escrito (11-09) con versión y origen de los 4:
      claude-desktop 1.46388.2 (build de la comunidad, no oficial → en Debian usar solo Claude Code),
      urserver 3.14.0.2574, zoom 7.1.0.3715, omniget 0.9.1 (el .deb está en `~/Downloads`, copiarlo al USB)
- [~] Este proyecto está en el USB suelto como `Migration-docs/` (11-09) y también dentro del tar
      del grupo 2. **Recopiarlo al final de cada sesión de doc**, porque la versión del USB se
      queda atrás: `cp -a ~/devTools/Migration/. /media/<user>/KINGSTON/Migration-docs/`
- [x] `/etc` entero en `~/Backup/etc-full/etc-09-26.tar.zst`: **2,0 MiB** (14,2 MiB al 13,4%) (11-09 14:20).
      Contiene los XML de las 3 VMs (`archlinux`, `win10`, `zorinOS`) y `networks/default.xml`
- [x] Redes copiadas (11-09): `migration/network/` con los 3 `*<ssid>*.nmconnection` +
      `Wired connection 1.nmconnection`, y `migration/netplan/` con los 4 `.yaml`
- [x] ~~USB de 64 GB: GPT + ext4 con LUKS~~ **descartado el 11-09**: el USB ya tenía el respaldo de
      junio y formatearlo lo habría borrado. Se resolvió con el plan C sobre el exfat existente
      (blobs sueltos + tar para permisos + tar cifrado para secretos), sin formatear nada
- [ ] **Segunda copia de lo irremplazable y chico** en otro medio: hoy `.ssh`, `postgres/` y `/etc`
      viven en **un solo pendrive**. Si ese USB muere, se pierden. El `secretos-09-26.tar.gpg` son
      2,1 MiB: entra en cualquier parte, y como ya está cifrado se puede guardar en Drive sin riesgo
      (es el único secreto que puede ir a Drive, justamente porque está cifrado)
- [ ] **Justo antes de formatear** (el backup de Nextcloud de hoy va a tener días): mantenimiento on →
      `pg_dump` → parar el contenedor → `tar` de los 2 volúmenes → `gzip -t` → copiar al USB.
      Es el único dato que cambia solo (lo que el iPad suba por GoodNotes mientras tanto)

### Mudanza a USB (decidido 11-09: plan C, el USB queda exfat, no se formatea)

El USB `KINGSTON` (57,7 GiB, **exfat**, en `/media/<user>/KINGSTON`) ya tiene `Backup6.11.26` (25 GiB,
el respaldo de junio) y **no se toca**. Quedan 34 GiB libres para los 35 GiB de `~/Backup`,
así que el tar del grupo 2 va comprimido con zstd. Medido con dry-run el 11-09:

- Grupo 1, `rsync` suelto (blobs ya comprimidos): **15,8 GiB** (`total size is 16.941.885.672`)
- Grupo 2, un tar + zstd (archivos chicos, permisos y symlinks): **207.894 archivos**, 19 GiB → ~15 GiB
- Grupo 3, tar cifrado **simétrico** AES256 (secretos): ~250 KiB
- Total al USB: **~31 GiB de 34**. Si el ratio de zstd sale peor, sacar `Files/mc` (2,1 GiB)

Cifrado simétrico y **no** con la clave GPG de Leo: la passphrase es lo único que hace falta para
descifrar (y de paso `.gnupg` está vacío). Passphrase anotada **fuera del USB**; probar
`gpg -d ... | tar -tv` **antes** de formatear el nvme.
Descifrado: `gpg -d /media/<user>/KINGSTON/secretos-09-26.tar.gpg | tar -xv -C ~`

**Los comandos, en orden. `$U` = `/media/<user>/KINGSTON`.**

```bash
U=/media/<user>/KINGSTON
```

1. Esperar el tar del grupo 2 y verificarlo:
   `pgrep -a zstd` (vacío = terminó); después `zstd -t "$U/Backup09-26/home-chico-09-26.tar.zst"`
2. Redes (sudo). Mint usa netplan: los keyfile están en `/run`, no en `/etc/NetworkManager`:
   ```bash
   sudo -s -- <<'EOF'
   set -e
   mkdir -p ~/Backup/migration/network ~/Backup/migration/netplan
   cp -a /run/NetworkManager/system-connections/netplan-NM-*<ssid>*.nmconnection ~/Backup/migration/network/
   cp -a "/run/NetworkManager/system-connections/Wired connection 1.nmconnection" ~/Backup/migration/network/
   cp -a /etc/netplan/*.yaml ~/Backup/migration/netplan/
   chown -R <user>:<user> ~/Backup/migration/network ~/Backup/migration/netplan
   ls ~/Backup/migration/network/ ~/Backup/migration/netplan/
   EOF
   ```
   No copiar los de `docker0`, `virbr0`, `br-*`, `lo`, `tailscale0`: se regeneran y chocan en Debian.
3. `/etc` entero (21 MB, trae los XML de las 3 VMs) (sudo):
   ```bash
   sudo -s -- <<'EOF'
   set -e
   mkdir -p ~/Backup/etc-full
   tar -c -C / etc | zstd -3 -T0 -o ~/Backup/etc-full/etc-09-26.tar.zst
   chown -R <user>:<user> ~/Backup/etc-full
   ls -lh ~/Backup/etc-full/
   zstd -dc ~/Backup/etc-full/etc-09-26.tar.zst | tar -t | grep 'libvirt/qemu/.*xml'
   du -sh /var/lib/libvirt/images
   EOF
   ```
   El `du` final es el dato que falta para decidir las VMs.
4. Rehacer el tar cifrado (el de 12:59 no tiene redes ni `/etc`). Misma passphrase:
   ```bash
   tar -c -C ~ .ssh .claude.json .local/share/keyrings .config/rclone \
          -C ~/Backup docker-state migration/network migration/netplan \
             migration/tailscale-state migration/ssh-host-keys etc-full \
     | gpg --symmetric --cipher-algo AES256 -o "$U/secretos-09-26.tar.gpg"
   ```
5. Probar el descifrado **con el sistema viejo vivo** (único chequeo que no se puede postergar):
   ```bash
   gpg -d "$U/secretos-09-26.tar.gpg" | tar -tv | grep -E 'network/|etc-full/'
   ```
6. Grupo 1, los blobs (15,8 GiB). Chequear espacio antes: `df -h "$U"`
   ```bash
   rsync -rtv -L --modify-window=2 --no-perms --no-owner --no-group --info=progress2 \
     ~/Backup/Videos ~/Backup/Music ~/Backup/Pictures \
     ~/Backup/Downloads ~/Backup/Public ~/Backup/docker-volumes \
     ~/Backup/postgres ~/Backup/Documents ~/Backup/Files \
     "$U/Backup09-26/"
   ```
7. Verificación final:
   ```bash
   zstd -t "$U/Backup09-26/home-chico-09-26.tar.zst"
   rsync -rtvn -L --modify-window=2 --no-perms --no-owner --no-group \
     ~/Backup/Videos ~/Backup/Music ~/Backup/Pictures \
     ~/Backup/Downloads ~/Backup/Public ~/Backup/docker-volumes \
     ~/Backup/postgres ~/Backup/Documents ~/Backup/Files \
     "$U/Backup09-26/" | grep -v '/$'
   ```
   El `rsync -n` no debe listar ningún archivo (solo directorios, que el `grep -v` filtra).
8. Decidir las VMs con el `du` del punto 3.
9. Flashear el pendrive de 8 GB con `debian-live-13.6.0-amd64-cinnamon.iso`
   (está en `~/devTools/linuxJournal/`, **no** se respalda: se vuelve a bajar con `wgetCommand`).
   Etcher: `~/devTools/linuxJournal/balenaEtcher-linux-x64/balena-etcher`.
   Confirmar el device con `lsblk` antes de escribir: el disco interno también es marca Kingston.
10. Fase 2: probar la live en el hardware real.

- [x] Dry-runs de los 3 comandos corridos y verificados (11-09)
- [x] Grupo 1 al USB (11-09): los 9 directorios copiados. USB al 92%: **53 GiB usados, 5,0 GiB libres**
      (menos margen que los 7 calculados: los clusters de 128 KiB de exfat desperdician con los
      3.054 archivos chicos de `Documents`)
- [x] Grupo 2 al USB: `home-chico-09-26.tar.zst`, **11 GiB** (19,2 GiB crudos, ratio 0,57 — mejor
      que el 0,79 estimado). Verificado con `zstd -t`: exit 0, `20616243200 bytes` (11-09 13:29).
      Tardó 30m. Con esto quedan **23 GiB libres** → el grupo 1 (16 GiB) entra con 7 GiB de margen
      y **no hace falta sacar `Files/mc`**
- [x] Grupo 3 al USB: `secretos-09-26.tar.gpg` rehecho 14:40, **2,1 MiB** (el de 12:59 tenía 102 KiB y
      le faltaban las redes y `/etc`). Validado sin passphrase con `gpg --list-packets`:
      `AES256.CFB`, `encrypted with 1 passphrase`. Contiene `.ssh`, `.claude.json`, keyrings,
      `rclone.conf`, `docker-state`, `migration/{network,netplan,tailscale-state,ssh-host-keys}` y `etc-full`
- [x] Verificado todo (11-09):
      - `zstd -t` del grupo 2: exit 0, `20616243200 bytes`
      - `rsync -n` del grupo 1: **ningún archivo listado**. El `total size` dio 16.941.889.577 contra
        16.941.885.672 del primer dry-run: +3.905 bytes, exactamente el `host-pg18.sql` agregado después
      - `zstd -t` del `/etc`: OK
- [x] **Descifrado probado y funcionando** (11-09, con el sistema viejo todavía intacto).
      Salieron las 4 `.nmconnection` con permisos `-rw-------` preservados y `etc-full/etc-09-26.tar.zst`.
      Confirma las dos cosas: la passphrase anotada es la correcta, y el tar preservó los permisos
      que exfat no guarda. **La passphrase vive solo fuera del USB; sin ella no hay recuperación.**

**FASE 1 CERRADA (11-09-2026).** En el USB `KINGSTON` (53 GiB usados, 5,0 GiB libres):
`Backup09-26/` (9 directorios sueltos + `home-chico-09-26.tar.zst` de 11 GiB),
`secretos-09-26.tar.gpg` (2,1 MiB, AES256 simétrico, descifrado probado), `Migration-docs/`,
y `Backup6.11.26` (el respaldo de junio, intacto).
Queda afuera **a propósito:** los 52 GiB de discos de VMs y los 2 archivos que faltaron en Drive.
Lo que **no** está respaldado y se pierde al formatear: nada más que eso.

## Fase 2: Decisión y prueba de hardware

- [x] **Debian 13 puro**, edición live con Cinnamon (11-09): Leo bajó
      `debian-live-13.6.0-amd64-cinnamon.iso` (4,1 GiB, en `~/devTools/linuxJournal/`, con su
      SHA256SUMS — ver `wgetCommand`). Queda descartado LMDE 7
- [x] Hardware identificado (11-09): GPU **NVIDIA GeForce GT 1030** (GP108, Pascal, `10de:1d01`), driver 580.173.02.
      WiFi USB: **Ralink/MediaTek MT7601U** (`148f:7601`). También hay Ethernet Realtek RTL8168 integrada
- [x] GPU soportada por la 550 (Pascal entra), **pero con reservas** (verificado 11-09 en packages.debian.org + wiki):
      trixie y trixie-backports tienen los dos la misma `550.163.01` — **no hay 580 en ningún lado**.
      El wiki de Debian marca la 550 como no mantenida, con problemas de seguridad conocidos, y **rota con kernel 6.16+**.
      El flavor `open` **no sirve**: excluye explícitamente Pascal. Hay que usar el propietario.
      → decisión pendiente para Leo (ver abajo)
- [x] Firmware del WiFi: **`firmware-mediatek`** (verificado 11-09: contiene `/usr/lib/firmware/mt7601u.bin`).
      Ojo, **no** es `firmware-misc-nonfree` como suponíamos. Está en `non-free-firmware`.
      El driver `mt7601u` es in-kernel desde 4.2, así que el 6.12 de trixie lo trae
- [~] Opcional: probar la distro en una VM de virt-manager para ver el escritorio — salteado,
      se fue directo a probar y quedarse con el hardware real (11-09)
- [x] Live USB en el hardware real (11-09, confirmado post-hoc): WiFi USB conecta (activo en
      Debian ya instalado) y video anda (nouveau, sesión gráfica arriba). Audio y suspensión
      no se verificaron a propósito, quedan para revisar en Fase 4/uso normal

## Fase 3: Instalación

- [x] Decidido y hecho: **btrfs con `@`/`@home`** (11-09, verificado post-hoc en el sistema ya
      instalado, no lo decidí yo). `fstab` confirma `subvol=/@` en `/` y `subvol=/@home` en
      `/home`, ambos sobre `nvme0n1p3`. Swap en partición aparte (`nvme0n1p2`, 12G)
- [x] Subvolúmenes `@`/`@home` correctos, no quedó en `@rootfs` (verificado en `fstab`, 11-09)
- [x] Instalado con `nvme0n1p1` reutilizada como EFI (verificado 11-09: `/boot/efi` vfat, mismo UUID)
- [~] Fuentes de apt: **falta `contrib` y `non-free`**. `/etc/apt/sources.list.d/debian.sources`
      solo tiene `main non-free-firmware` en trixie/trixie-updates/trixie-security y
      trixie-backports. Hace falta para `nvidia-driver` (paquete en `non-free`), `steam-installer`
      y `lutris` (en `contrib`) — pendiente de Fase 4 §1-2 (11-09)
- [~] WiFi: firmware andando, conectado a `Auto <ssid> 2.4` (11-09). **NVIDIA sigue con `nouveau`**
      (el driver libre): falta instalar `nvidia-driver` — es la decisión pendiente #5 (550 vs 580)
- [x] Usuario `leo` con sudo confirmado (grupo `sudo` en `groups`, 11-09). Contraseña de root
      no verificada (no se puede chequear sin intentar loguear como root)

## Fase 4: Restauración (ver `docs/restauracion.md`)

- [x] §0 desempacado completo en `~/Restore` (11-09): grupo 1 (blobs, 16.941.889.577 bytes,
      verificado con `rsync -n` sin archivos pendientes), grupo 2 (tar chico, `zstd -t` OK,
      208k archivos), grupo 3 (secretos, `.ssh` con permisos 700/600 confirmados, keyrings,
      `.claude.json`, redes, claves de host SSH, `tailscaled.state`, `docker-state`, `rclone.conf`,
      `etc-full/` — todo verificado solo por existencia/permisos, sin leer contenido)
- [x] Proyecto restablecido en `~/devTools/Migration` desde la copia más fresca del USB (11-09)
- [x] Claude Code ya estaba instalado (11-09, de una sesión anterior)
- [ ] Copiar `~/Restore/migracion` a `~/migracion` (pendiente, si Leo lo quiere ahí también)
- [~] Fuentes de apt: falta habilitar `contrib non-free` (Leo lo corre con `!`, en curso)
- [ ] Claves: `.ssh` (700/600), `.gnupg` (700), `.gitconfig`, keyrings
- [ ] Redes WiFi: copiar los `.nmconnection` de `migration/network/` a `/etc/NetworkManager/system-connections/`
      (root:root 600) y `nmcli connection reload`. Son 4: `Auto <ssid> 2.4` (la que se usa), `<ssid>`,
      `Auto <ssid>`, `Wired connection 1`. Ojo: el de 2.4 tiene `%20` en el nombre del archivo →
      renombrarlo limpio y revisar el campo `id=`. Los `.yaml` de `migration/netplan/` son **solo referencia**:
      Debian no usa netplan
- [ ] Paquetes apt de los repos de Debian (desde la tabla de `docs/restauracion.md`)
- [ ] Repos de proveedores: Brave, VS Code, Docker CE, Tailscale, gh, Spotify
- [ ] Flatpak + Flathub; reinstalar desde `flatpaks.txt`
- [ ] Shell: `.bashrc`, `.profile`, `.tmux.conf` (con eza, zoxide, fzf, bat ya instalados)
- [ ] Docker: restaurar volúmenes, Nextcloud con tag exacto, `tgpg`
- [ ] PostgreSQL 18 del host (PGDG) y restaurar `host-pg18.sql` (rol `leo`, base `freecodecamp`)
- [ ] Tailscale: borrar el nodo viejo del panel **antes** de loguear (o restaurar `tailscaled.state`),
      rehacer `tailscale serve` y `tailscale cert`, y revisar `trusted_domains` de Nextcloud
- [ ] Configs de apps: Brave, VS Code (extensiones), `.config` selectivo, `.var`, fuentes, temas, applets de Cinnamon
- [ ] Herramientas IA: `.claude`, `.gemini`, `.copilot`, `.opencode`, `.mcp` (o volver a iniciar sesión)
- [ ] `.wine`, Steam (i386 + contrib), Lutris
- [ ] Unified Remote (`urserver`) y puertos 9511/9512
- [ ] libvirt/virt-manager y VMs conservadas
- [ ] Timeshift configurado (rsync o btrfs según el layout)
- [ ] Restaurar archivos personales en el layout nuevo del home
- [ ] Bajar de Drive y verificar `Backup09-26`
- [ ] Dotfiles en repo git plano (fase posterior, a discutir)
