# Migración Linux Mint 22.3 → Debian 13: backup y preparación

Notas del 10/09/2026. Estado: backup hecho, instalación pendiente.
Máquina: desktop con un solo NVMe, GPU NVIDIA, WiFi por adaptador USB, Docker, Tailscale, libvirt.

---

## 1. Qué se hizo, en una línea

Respaldar todo lo que importa de un Mint que se va a formatear (archivos, claves, configs, contenedores, bases de datos y lista de paquetes) a un pendrive cifrado + Google Drive, y dejar anotado todo lo que va a morder en Debian.

---

## 2. Por qué migrar y a qué

### 2.1 El motivo

3 actualizaciones de kernel en 2 meses y bugs menores que desaparecían al reiniciar. Mint 22.x sigue los kernels **HWE** de Ubuntu, que saltan de serie (6.8 → 6.17 → 7.0): features y drivers nuevos, y ahí aparecen las regresiones.

Debian stable se queda en **una sola serie de kernel** (6.12 LTS en Debian 13) durante toda su vida: las actualizaciones son parches de seguridad dentro de la misma versión. Lo mismo con el resto del sistema: versiones congeladas, solo arreglos.

**⚠️ Gotcha importante:** los bugs que "se van al reiniciar" pueden no ser culpa de la distro. Después de actualizar el kernel, el kernel nuevo está instalado pero seguís corriendo el viejo hasta reiniciar. En esa ventana, cargar un módulo puede fallar (típico: dispositivos USB) porque los módulos del kernel viejo ya fueron reemplazados. Pasa en Debian también. Regla: **reiniciar pronto después de una actualización de kernel.**

### 2.2 Debian puro vs LMDE

| | LMDE 7 | Debian 13 |
|---|---|---|
| Base | Debian 13 + herramientas de Mint | Debian 13 |
| Escritorio | solo Cinnamon | el que elijas en el instalador |
| Se siente como | Mint | un sistema que armás vos |
| Drivers/kernel nuevos | recién en la siguiente versión de LMDE | backports si los pedís |

Elegí **Debian puro**: quiero estabilidad y aprender cómo encajan las piezas. LMDE era "Mint con otra base".

Dato: Compiz (fork Compiz Reloaded) está en los repos de Debian 13, pero funciona con XFCE/MATE, **no con Cinnamon** en ninguna distro, porque Cinnamon usa su propio window manager (Muffin).

---

## 3. ¿Instalar Debian borra mi home?

Depende de cómo está particionado el disco:

```
findmnt /home
lsblk -f
```

- `findmnt /home` no imprime nada → `/home` está en la misma partición que `/` → **instalar borra todo**.
- Imprime un dispositivo propio → `/home` está separado y el instalador puede conservarlo (particionado **manual**, sin formatear esa partición).

**⚠️ Gotcha importante:** la opción "Guiado – usar todo el disco" borra todo, incluida una partición `/home` separada. Y aun con `/home` separado: hacé backup igual, un click mal dado en el particionador lo formatea.

En mi caso: una partición EFI + una ext4 con todo adentro. Instalar = perder todo.

---

## 4. Timeshift no es un backup

- Por defecto guarda **archivos del sistema**, no `/home`.
- Si los snapshots están en el mismo disco, **formatear los borra**.
- Un snapshot de Mint no se puede restaurar sobre Debian (lo pisaría con Mint).

Sirve para deshacer una mala actualización, no para mudarse. Ver dónde guarda:

```
sudo timeshift --list
sudo cat /etc/timeshift/timeshift.json    # backup_device_uuid y exclude
```

---

## 5. Qué respaldar del home

### 5.1 Medir primero

`ls -la` muestra `4096` en todas las carpetas: es el tamaño de la entrada del directorio, **no de su contenido**. Para ver el peso real:

```
du -sh ~/* ~/.[!.]* 2>/dev/null | sort -h | tail -25
du -h --max-depth=3 ~/.local | sort -h | tail -30
```

### 5.2 Clasificar

| Tipo | Ejemplos | Qué hacer |
|---|---|---|
| Irremplazable | proyectos, documentos, fotos | backup + verificar |
| Identidad | `.ssh`, `.gnupg`, `.gitconfig`, `.local/share/keyrings` | backup **cifrado** |
| Setup (ahorra tiempo) | `.bashrc`, `.tmux.conf`, `.config`, temas, fuentes | backup, restaurar selectivo |
| Herramientas IA | `.claude`, `.claude.json`, `.gemini`... | backup cifrado: tienen tokens |
| Regenerable | `.cache`, `.npm`, `.nvm`, `node_modules`, `.venv`, `go/pkg` | no respaldar |

### 5.3 Dónde se escondían los gigas

De **55 GiB a 26 GiB** borrando de la copia cosas que no hacía falta guardar:

- `.local/share/Trash`: la papelera (6,5G).
- `.local/share/flatpak`: apps y runtimes Flatpak. Se reinstalan desde la lista (6,2G).
- `.local/share/umu`: runtime de Proton para juegos fuera de Steam (5,7G).
- `.local/share/Steam`: la biblioteca de juegos, si está ahí.
- `.var/app/<app>/cache`: caché de cada Flatpak.
- `.var/app/...` de juegos (launchers de Minecraft, Hytale) y apps de chat: se re-descargan o se vuelve a iniciar sesión.
- En Minecraft (PrismLauncher) lo único que importa son las `instances` (mundos y mods).

### 5.4 Cómo copiar

**⚠️ Gotcha importante:** copiar con Ctrl+C / Ctrl+V desde el gestor de archivos falla en silencio con archivos de root (en mi caso, datos del servidor de RustDesk en Docker) y puede perder symlinks. Usar `cp -a` o `rsync`.

Carpeta intermedia para recortar sin tocar los originales, **sin duplicar espacio**:

```
cp -al Documents devTools ~/backup-staging/    # hard links: instantáneo, 0 bytes extra
```

Borrar dentro del staging es seguro (solo quita ese nombre). **Editar** un archivo del staging modifica el original, porque es el mismo archivo.

Copiar al destino conservando permisos, ACLs, atributos y hard links:

```
rsync -aAXH --info=progress2 ~/Backup/ /media/usuario/BACKUP/
rsync -aAXHn ~/Backup/ /media/usuario/BACKUP/     # -n: dry run, para verificar
```

`-R` conserva la ruta relativa (`.local/share/keyrings` llega como `.local/share/keyrings`).

### 5.5 El pendrive

- **ext4, no FAT32/exFAT/NTFS.** Esos pierden permisos (`.ssh` deja de funcionar), no guardan symlinks (`.wine` depende de ellos) y FAT32 no acepta archivos de más de 4 GB.
- **Cifrado con LUKS** (app Discos → formatear → "Proteger volumen con contraseña"): lleva claves SSH, tokens y contraseñas de WiFi.
- Una partición ext4 nueva es de root: `sudo chown usuario:usuario /media/usuario/BACKUP`.

---

## 6. Docker: los datos no viven en el home

`~/docker` tenía los compose y bind mounts. Pero Docker guarda **volúmenes, imágenes y contenedores en `/var/lib/docker`**, fuera del home. Copiar el home no los respalda.

### 6.1 Ver qué hay

```
docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}'
docker system df -v
```

Separar lo que importa de lo que no: devcontainers de VS Code (`vsc-*`), volúmenes del tutorial `getting-started`, imágenes oficiales y build cache se regeneran solos.

### 6.2 Bases de datos: dump, no copia de archivos

Copiar los archivos de datos de Postgres con la base corriendo puede dejar una copia corrupta. Lo correcto es un **dump** en SQL, con el contenedor corriendo:

```
docker exec <contenedor> sh -c 'pg_dumpall -U "${POSTGRES_USER:-postgres}"' > dumpall.sql
docker exec <contenedor> sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' > base.sql
grep -c "CREATE TABLE" *.sql    # verificar que no esté vacío
```

- Las comillas simples hacen que `$POSTGRES_USER` se expanda **dentro** del contenedor, con sus variables de entorno: no hace falta saber el usuario.
- **⚠️ Gotcha:** no usar `docker exec -t` al redirigir a un archivo: la TTY puede meter caracteres raros en el dump.

### 6.3 Volúmenes: tar desde un contenedor, con todo parado

```
docker stop <contenedores>
docker run --rm -v <volumen>:/data:ro -v ~/Backup/docker-volumes:/backup alpine \
  tar -czf /backup/<volumen>.tar.gz -C /data .
sudo chown -R usuario:usuario ~/Backup/docker-volumes
gzip -t ~/Backup/docker-volumes/*.tar.gz    # verificar
```

Hacer el tar desde un contenedor conserva dueños y permisos, que Postgres y Nextcloud necesitan para arrancar.

Para saber qué volumen usa un contenedor:

```
docker inspect <contenedor> --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{end}}{{end}}'
```

**⚠️ Gotcha importante:** pegué un comando con un placeholder (`VOLUMEN_DE_X`) sin reemplazarlo. `docker run -v NOMBRE:/data` **crea un volumen vacío** si no existe, así que no dio error: generó un tar de 87 bytes. Un backup chiquito sospechoso = revisar. Limpieza: `docker volume rm VOLUMEN_DE_X`.

### 6.4 Nextcloud

1. Anotar la versión exacta: `docker exec -u www-data <nextcloud> php occ status`
2. Modo mantenimiento: `occ maintenance:mode --on`
3. Dump de su Postgres (6.2) y tar de los volúmenes de datos y de la base (6.3)
4. Levantar y `occ maintenance:mode --off`

**⚠️ Gotcha importante:** `nextcloud:apache` es un tag **flotante** (siempre la última). Nextcloud no salta versiones mayores: al restaurar, usar el tag exacto de la versión respaldada y actualizar después, de a una versión mayor.

Otros detalles:
- Lo que se suba a Nextcloud después del backup no está en él → repetirlo justo antes de formatear.
- Los volúmenes de Compose se llaman `<proyecto>_<volumen>`: el directorio del compose tiene que seguir llamándose igual (o fijar `name:`) para reusar los nombres.
- `docker inspect` guarda variables de entorno **con contraseñas**: esos JSON van al backup cifrado, no a la nube.

### 6.5 Imágenes

Las oficiales se vuelven a bajar. Solo guardar con `docker save` las construidas a mano cuyo Dockerfile no esté en ningún repo.

---

## 7. PostgreSQL instalado en el host

Aparte de los contenedores, tenía PostgreSQL 18 del repo PGDG (ver `postgreSQL_Conflicts.md`), con un rol propio y una base de desarrollo.

```
pg_lsclusters
sudo -u postgres psql -c '\l'
sudo -u postgres pg_dumpall > host-pg18.sql    # incluye roles
```

- Debian 13 trae PostgreSQL 17. Un dump de la 18 puede fallar en una versión anterior → instalar la 18 desde PGDG.
- En Debian el script de PGDG reconoce `trixie` directamente: no hace falta el truco de pasarle el codename de Ubuntu que necesitaba Mint.

---

## 8. Inventario: ¿qué instalé yo?

### 8.1 Lo que no funcionó

- `apt-mark showmanual` → **2116 paquetes**. Mint marca como "manual" casi todo lo preinstalado.
- Filtrar `/var/log/apt/history.log` → **3 paquetes**. Los logs rotan, las instalaciones desde la tienda de software no dejan `Commandline:` y el formato varía.

### 8.2 Lo que sí funcionó

Mint (y Ubuntu) guardan la lista de paquetes del momento de la instalación. Restando esa lista a los manuales actuales, queda lo agregado:

```
comm -23 <(apt-mark showmanual | sort -u) \
  <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) \
  > apt-agregados.txt
```

→ **227 paquetes**, la lista útil. Incluye ruido (kernels, headers, librerías), pero se filtra a mano.

### 8.3 El resto del inventario

```
ls /etc/apt/sources.list.d              # repos de terceros
flatpak list --app --columns=application
code --list-extensions
npm ls -g --depth=0
uv tool list; pipx list --short; ls ~/go/bin; ls ~/.cargo/bin
systemctl list-unit-files --state=enabled
systemctl --user list-unit-files --state=enabled
crontab -l
cp /etc/fstab /etc/hosts .
sudo cp -r /etc/NetworkManager/system-connections .    # WiFi con contraseñas: solo a backup cifrado
```

### 8.4 Qué cambia en Debian

| Mint/Ubuntu | Debian |
|---|---|
| `linux-firmware-*` | `firmware-*` (componente `non-free-firmware`) |
| `nvidia-driver-580` | `nvidia-driver` (rama 550 en trixie, `non-free`) |
| `language-pack-es*` | `task-spanish` |
| `bat` | se ejecuta como `batcat` |
| PPAs | no funcionan: repo del proveedor, Flatpak o `.deb` |
| `steam-installer` | `contrib` + `dpkg --add-architecture i386` |
| Docker de Mint | repo oficial de Docker para Debian |

Antes de dar por hecho que un paquete existe: `apt policy <paquete>` o packages.debian.org.

---

## 9. Cosas que van a morder en Debian (anotadas antes de instalar)

### 9.1 btrfs y Timeshift

- El instalador de Debian con btrfs crea el subvolumen **`@rootfs`**, no `@`.
- Timeshift en modo btrfs **exige** el layout de Ubuntu: `@` y `@home`.
- Opciones: ajustar los subvolúmenes desde una consola durante la instalación (practicar antes en una VM), arreglarlo después desde un live USB (donde más se rompe GRUB/fstab), o usar **Snapper** que no depende de los nombres.

Layout que estoy considerando:

| Subvolumen | Montaje | Por qué separado |
|---|---|---|
| `@` | `/` | el sistema: lo que se snapshotea |
| `@home` | `/home` | sobrevive reinstalaciones |
| `@log` | `/var/log` | un rollback no borra los logs que explican qué falló |
| `@docker` | `/var/lib/docker` | bases de datos fuera de los snapshots |
| `@libvirt` | `/var/lib/libvirt/images` | sin copy-on-write (`chattr +C`) para discos de VM |
| `@steam` | biblioteca de Steam | 100+ GB de juegos fuera de los snapshots |

Con btrfs:
- Vigilar el espacio con `sudo btrfs filesystem usage /` (`df` engaña) y no llenar el disco: los snapshots retienen lo borrado.
- Swap: partición chica aparte es lo más simple.
- Nunca `btrfs check --repair` a ciegas.
- Un subvolumen creado dentro de otro queda fuera de sus snapshots (truco para `~/.cache`).

Otras opciones evaluadas: ext4 con particiones separadas (simple), LVM thin (volúmenes flexibles), ZFS como raíz (el más sólido, pero instalación manual y módulo DKMS en `contrib`). bcachefs descartado: salió del kernel principal en la 6.18.

### 9.2 NVIDIA y WiFi USB

- Debian 13 trae la rama **550** del driver; Mint tenía la 580. Confirmar que la GPU está soportada o buscar en `trixie-backports`.
- Identificar hardware antes de formatear: `lspci -nn | grep -Ei 'vga|3d|network'` y `lsusb`.
- Probar el **live USB** en el hardware real antes de tocar el disco.
- Con Secure Boot: el módulo DKMS pide enrolar una clave MOK al reiniciar.

### 10.3 Tailscale y Nextcloud (ver `nextcloud-tailscale-goodnotes-setup.md`)

**⚠️ Gotcha importante:** el hostname `.ts.net` está grabado en `trusted_domains`, `overwrite.cli.url` y en la URL WebDAV de GoodNotes. Si Debian se loguea a Tailscale con el nodo viejo todavía registrado, la máquina nueva recibe otro nombre (`maquina-1`) y el backup del iPad se rompe.

Opciones:
- Borrar el nodo viejo en el panel de Tailscale **antes** de loguear la instalación nueva. Después: `tailscale serve --bg <puerto>` y `tailscale cert <hostname>`.
- O respaldar `/var/lib/tailscale/tailscaled.state` y restaurarlo antes de iniciar Tailscale: vuelve como el mismo nodo. Es la clave de la máquina: solo backup cifrado.

Antes de formatear: guardar la salida de `tailscale serve status`.

### 9.4 Redes WiFi guardadas

Al restaurar `system-connections`: dueño `root`, permisos `600`, `sudo nmcli connection reload`. Si una conexión tiene fijada la interfaz o MAC vieja, editarla.

---

## 10. Conceptos: el "por qué"

### 11.1 Snapshot vs backup

Un snapshot vive **en el mismo disco**: te salva de una mala actualización o un `rm` equivocado, no de un disco muerto, un robo o un formateo. Un backup vive **en otro medio**.

| Capa | Te protege de | Herramienta |
|---|---|---|
| Snapshots en el mismo disco | actualización rota, borrar por error | Timeshift / Snapper |
| Copia a disco externo | disco muerto, formateo | restic / btrbk |
| Copia fuera de casa | robo, incendio, perder el externo | restic → Drive, cifrado |

### 10.2 Por qué dump y no copiar la carpeta de la base

Una base de datos escribe en varios archivos a la vez. Copiarlos mientras corre puede capturar unos antes y otros después de una transacción: la copia queda inconsistente. El dump le pide a la base una foto coherente en SQL, que además se restaura en otra máquina o en una versión más nueva.

### 10.3 Hard links

Dos nombres para el mismo archivo en disco. `cp -al` crea una "copia" instantánea que no ocupa espacio: borrar un nombre no afecta al otro, pero modificar el contenido cambia ambos. Solo funciona dentro de la misma partición.

### 10.4 Flags de rsync

- `-a`: archivo (recursivo, permisos, dueños, fechas, symlinks)
- `-A`: ACLs
- `-X`: atributos extendidos
- `-H`: hard links
- `-n`: dry run
- `-R`: rutas relativas

---

## 11. Lecciones → reglas para el sistema nuevo

Esta mudanza costó un día entero porque nada estaba escrito. Cada problema tiene una regla que lo evita:

| Lo que pasó | Regla |
|---|---|
| 2116 paquetes "manuales" y hubo que investigar cuáles eran míos | lo que instalo queda escrito en una lista **antes** de instalarlo |
| Datos dispersos: `/var/lib/docker`, Postgres del host, redes en `/etc` | cada servicio declara dónde guarda sus datos y cómo se respalda |
| Cachés mezcladas con datos (55 → 26 GB a mano) | los datos que importan viven en lugares conocidos |
| `nextcloud:apache` sin versión | tags de imagen fijos en cada compose |
| Claves y tokens mezclados con todo | los secretos tienen un lugar propio y cifrado |
| Un servidor de RustDesk corriendo sin usarlo | si no está documentado, no debería estar en la máquina |
| Un placeholder sin reemplazar creó un volumen vacío | verificar cada backup (tamaño, `gzip -t`, conteo de tablas) |

Plan: después de instalar y asentarme en Debian, un repo que describa el sistema (paquetes, repos, configs, servicios) para que la próxima reinstalación sea clonar y aplicar. Mientras tanto, anotar todo lo que haga a mano.

---

## 12. Checklist rápido para la próxima mudanza

1. `findmnt /home` → ¿se borra el home?
2. `du` para medir; clasificar irremplazable / identidad / setup / regenerable
3. Inventario de paquetes con `initial-status.gz` (no `apt-mark showmanual`)
4. Listas de Flatpak, extensiones, herramientas de cada lenguaje, repos, units, `/etc` relevante
5. `docker system df -v` → dumps con contenedores corriendo, tar de volúmenes con contenedores parados, `gzip -t`
6. Postgres del host → `pg_dumpall`
7. Versión exacta de Nextcloud; `tailscale serve status`; state de Tailscale si hace falta
8. Pendrive ext4 + LUKS; `rsync -aAXH`; verificar con `-n`
9. Lo pesado y no privado → comprimir y `rclone copy` + `rclone check --one-way`
10. Segunda copia de lo irremplazable y chico
11. Identificar GPU y WiFi; probar live USB
12. Justo antes de formatear: repetir el backup de lo que siguió cambiando (Nextcloud, proyectos)
