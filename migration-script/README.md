# migration-script

Herramienta de backup determinístico para el próximo salto de distro de Leo. Nace de la
migración manual Mint 22.3 → Debian 13 (documentada en `~/migracion`); esta vez, en vez de
rehacer todo a mano, queda un script re-ejecutable y versionado en git.

## Filosofía

- **El backup es determinístico y verificable.** Mismo comando, mismo resultado (salvo
  timestamps). Cada módulo termina con un `checksums.sha256`, y hay un `manifest.json` en la
  raíz del backup con la versión exacta del script que lo generó.
- **El restore es asistido, no automático.** Los nombres de paquete cambian entre distros, así
  que `restore.sh` te muestra qué hay y el comando sugerido para cada sección — vos confirmás
  antes de correr cada bloque.
- **Nunca hace nada destructivo por su cuenta**: no formatea discos, no hace
  `docker volume rm/prune`, no hace `rclone sync/move/delete`. Ver `lib/common.sh` para las
  guardas.

## Uso

```bash
# Simular (no escribe nada persistente, salvo los módulos que no tienen modo seguro de simular)
./backup.sh --dest /media/<user>/USB/backup-2027 --dry-run

# Backup real
./backup.sh --dest /media/<user>/USB/backup-2027

# Verificar checksums de un backup ya hecho
./backup.sh --verify /media/<user>/USB/backup-2027

# Correr solo algunos módulos (útil para probar uno nuevo o re-hacer uno que falló)
./backup.sh --dest /media/<user>/USB/backup-2027 --only=40-docker,70-personal

# En la máquina nueva, ver el checklist de restauración
./restore.sh --from /media/<user>/USB/backup-2027
```

`--yes` en cualquiera de los dos scripts salta las confirmaciones interactivas (útil para correr
sin supervisión, pero pensado para usarse a propósito, no por default).

## Qué respalda cada módulo

| Módulo | Qué guarda |
|---|---|
| `00-inventory` | Paquetes manuales (apt/dnf/pacman), flatpaks, extensiones VS Code, `go/bin`, `.local/bin`, unidades systemd habilitadas, crontab, `fstab`, `hosts`, `os-release` |
| `10-dotfiles` | `.bashrc`/`.profile`/`.tmux.conf`/`.gitconfig`, `.config`, `.local/share`, temas/íconos (sin cachés) |
| `20-secrets` | `.ssh`, `.gnupg`, `.claude.json`, keyrings, `rclone.conf`, claves de host SSH, estado de Tailscale — todo empaquetado y **cifrado con GPG simétrico AES256**, nunca en texto plano |
| `30-network` | Perfiles de NetworkManager, detectando si el backend real es netplan (los keyfiles viven efímeros en `/run`) o nativo |
| `40-docker` | Por proyecto: dump SQL de la DB (contenedor corriendo), tar de cada volumen (contenedores parados durante el tar), `docker inspect` |
| `50-postgres-host` | `pg_dumpall` del PostgreSQL del host, si hay uno corriendo |
| `60-libvirt` | XML de VMs y redes definidas (discos opcionales, apagados por default — ver `config/paths.conf`) |
| `70-personal` | Directorios grandes (Documents, Videos, devTools, etc.) listados en `config/paths.conf` |

## Antes de cada backup real

Revisar `config/paths.conf` — no es genérico, tiene los proyectos Docker, directorios
personales y contenedores de DB **de la máquina actual**. Actualizarlo si algo cambió desde el
último backup (nuevo proyecto Docker, carpeta nueva, etc.).

## Estructura de un backup terminado

```
<DEST>/
├── manifest.json          # hostname, os-release, kernel, commit del script, módulos+checksums
├── 00-inventory/
├── 10-dotfiles/
├── 20-secrets/secretos.tar.gpg
├── 30-network/
├── 40-docker/{inspect,volumes,sql}/
├── 50-postgres-host/
├── 60-libvirt/xml/
└── 70-personal/
```

Ver `docs/manifest-schema.md` para el detalle de `manifest.json`.
