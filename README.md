# DocumentationLinuxJournal

Bitácora personal de problemas, soluciones y configuraciones que voy encontrando mientras uso, rompo y reinstalo Linux.

Cada nota nace de algo que me costó resolver: si me pasó una vez, probablemente me vuelva a pasar (a mí o a alguien más).

>  **Notas personales, no documentación oficial.** Los comandos se probaron en mi setup y en la fecha que indica cada nota. Leelos antes de copiar y pegar, sobre todo los que usan `sudo`, borran, formatean o tocan particiones.

---

## Índice

### Distros, migraciones y VMs

| Nota | De qué trata | Contexto |
|---|---|---|
| [migracion-mint-a-debian-backup.md](migracion-mint-a-debian-backup.md) | Backup completo antes de formatear: archivos, Docker, bases de datos, inventario de paquetes, rclone + Google Drive y lo que va a morder en Debian | Linux Mint 22.3 → Debian 13 |
| [archlinuxTTYconnection.md](archlinuxTTYconnection.md) | VM de Arch: consola serial con `virsh console`, AUR helper y setup de Sway | VM Arch en virt-manager |
| [configurarARCH.md](configurarARCH.md) | VM de Arch (parte 2): iwd, versionado del repo de Sway y clipboard host ↔ VM | VM Arch + Sway |
| [instalarSPICE.md](instalarSPICE.md) | Compartir carpetas entre host Linux y una VM Windows con SPICE WebDAV | VM Windows 10 en virt-manager |

### Servicios y self-hosting

| Nota | De qué trata | Contexto |
|---|---|---|
| [nextcloud-tailscale-goodnotes-setup.md](nextcloud-tailscale-goodnotes-setup.md) | Backup automático de GoodNotes por WebDAV a Nextcloud, expuesto con Tailscale Serve | Docker + Tailscale |
| [postgreSQL_Conflicts.md](postgreSQL_Conflicts.md) | Instalar PostgreSQL desde PGDG en Mint y el error `role does not exist` | Linux Mint 22.3 |
| [InstalarDockerLinuxPC.md](InstalarDockerLinuxPC.md) | Instalación de Docker Engine desde el repo oficial | Linux (base Ubuntu) |

### Cheatsheets

| Nota | De qué trata |
|---|---|
| [DockerCHEATSHEET.md](DockerCHEATSHEET.md) | Imágenes, contenedores, volúmenes, redes, Compose y Docker Hub |
| [tmux-cheatsheet.md](tmux-cheatsheet.md) | Config y atajos de tmux para manejar varios CLIs en paralelo |
| [gitGood&SytemCommands.md](gitGood%26SytemCommands.md) | Git, SSH, monitores y comandos de sistema |
| [ghCLI.md](ghCLI.md) | GitHub CLI: pull requests desde la terminal y `gh api` |

---

## Cómo están escritas las notas

La mayoría sigue la misma forma:

1. **Contexto:** fecha, distro y qué se quería lograr.
2. **Problema → causa → solución**, con los comandos que funcionaron.
3. **Gotchas:** los detalles que hacen perder una hora.
4. **Conceptos:** el "por qué", no solo el "cómo".
5. **Checklist** para repetirlo desde cero.

Plantilla para una nota nueva:

````markdown
# Título descriptivo del problema o setup

Notas del DD/MM/AAAA. Distro/entorno: ...

## 1. Qué se quería hacer, en una línea

## 2. Problema: <mensaje de error o síntoma>

### Causa

### Solución

```
comandos
```

** Gotcha importante:** ...

## 3. Conceptos

## 4. Checklist rápido
````

---

## Convenciones

- **Sin datos sensibles:** nada de contraseñas, tokens, IPs, nombres reales de máquinas o del tailnet. Se usan placeholders como `<usuario>`, `<contenedor>` o `tu-maquina.tu-tailnet.ts.net`.
- **Comandos en bloques de código**, para copiar sin arrastrar texto de más.
- **Fecha y entorno** al principio de cada nota: lo que funciona en una versión puede no funcionar en la siguiente.

---

## Entorno

Las notas salen de mi uso diario, así que reflejan el setup de cada momento:

- **Host:** Linux Mint 22.3 (base Ubuntu 24.04), en migración a Debian 13.
- **Virtualización:** QEMU/KVM con virt-manager (VMs de Arch y Windows).
- **Servicios:** Docker, Tailscale, Nextcloud, PostgreSQL.
- **Terminal:** bash, tmux, git y gh.
