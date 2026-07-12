# Bitácora VM Arch Linux (parte 2) — iwd, git, y clipboard host↔VM

Continuación de `arch-vm-bitacora.md`, desde justo después de arrancar Sway por primera vez.

---

## 1. Aviso de "iwd is down" en iwgtk

Al abrir `iwgtk` (la GUI de Wi-Fi que instala el repo de Sway), avisaba que `iwd` estaba caído.

### Se activó el servicio
```bash
sudo systemctl enable --now iwd.service
```

El `preset: disabled` que muestra `systemctl status` es solo informativo (el estado "de fábrica" si nunca se tocara el servicio) — no afecta que esté `enabled`/`active (running)` de verdad, que es lo que importa.

### Diagnóstico final: no aplica a esta VM
```bash
iwctl device list
```
devolvió vacío — la VM no tiene ninguna tarjeta Wi-Fi (ni real ni virtual), solo la Ethernet virtual (`enp1s0`) que ya daba conexión. El repo de Sway está pensado para un ThinkPad físico con Wi-Fi real; en esta VM, `iwgtk`/`iwd` simplemente no tienen nada que gestionar. **Se decidió ignorar el cartel**, sin necesidad de arreglar nada más.

## 2. Cómo funciona el versionado del repo de Sway (dudas conceptuales)

- **Stow "as-is"**: la mayoría de los archivos del repo se symlinkean tal cual desde `~/sway-workstation` hacia `$HOME` (ej. `~/.config/sway/config` es un link al archivo real dentro del repo). Editar el archivo en `$HOME` es editar el repo mismo.
- **Excepción**: wallpaper y el módulo de temperatura de Waybar son generados/copiados (no symlinkeados), porque dependen del hardware específico de cada máquina — viven en `~/.config`, fuera del repo, y están en `.gitignore`.
- **Sobre poder editar y "commitear"**: se aclaró que clonar el repo da una copia completa con toda su historia — se pueden hacer `git commit` locales sin ningún permiso especial. Lo que **no** se puede hacer sin acceso de colaborador es `git push` directo al repo del autor (`carlosplanchon`). Para guardar cambios propios en GitHub, las opciones son: (a) hacer **fork** del repo, o (b) crear un **repo propio** y cambiar el `origin`. Por ahora, decisión pendiente — no se guardó nada todavía.

## 3. Clipboard bidireccional entre host (Mint) y VM (Arch + Sway)

**Contexto:** `spice-vdagent` no funciona en Wayland/Sway — es una limitación conocida y sin solución nativa (a diferencia de GNOME/Mutter, wlroots no tiene esa integración). Se descartó SPICE para esto y se armó un puente manual vía SSH + herramientas de clipboard nativas de cada lado (`xclip` en Mint/X11, `wl-clipboard` en Arch/Wayland).

### Instalación
En la VM Arch:
```bash
sudo pacman -S wl-clipboard
```
En el host Mint:
```bash
sudo apt install xclip
```

### Dato clave: nombre del socket de Wayland
```bash
echo $WAYLAND_DISPLAY
```
En esta VM dio `wayland-1` (no `wayland-0`) — necesario porque una sesión SSH no interactiva no hereda esta variable sola, hay que pasarla explícita en cada comando.

### Problema encontrado: el comando "se queda pensando"
Causa: `wl-copy` se queda corriendo en segundo plano por diseño (necesita seguir vivo para "servir" el contenido copiado). Por SSH, sus descriptores de salida heredados mantienen la sesión abierta indefinidamente aunque el copiado ya haya funcionado.

**Solución:** redirigir explícitamente la salida de `wl-copy` a `/dev/null` en el comando remoto.

### Host → VM (llevar el clipboard del host hacia la VM)
```bash
xclip -o | ssh leo@192.168.122.X "WAYLAND_DISPLAY=wayland-1 wl-copy >/dev/null 2>&1"
```

### VM → Host (traer el clipboard de la VM hacia el host)
No tiene el mismo problema — `wl-paste` lee y termina solo, sin quedar corriendo:
```bash
ssh leo@192.168.122.X "WAYLAND_DISPLAY=wayland-1 wl-paste" | xclip -selection clipboard
```

### Aliases guardados en `~/.bashrc` (del host Mint)

Nota: se detectó que un primer intento de alias tipeado directo en terminal **no persistió** (vive solo en memoria de esa sesión, no en ningún archivo) — de ahí la importancia de agregarlo con `echo >> ~/.bashrc` o editando el archivo directo, y no solo tipear el `alias` suelto en la shell.

```bash
alias pegar='xclip -o | ssh leo@192.168.122.X "WAYLAND_DISPLAY=wayland-1 wl-copy >/dev/null 2>&1"'
alias copiar='ssh leo@192.168.122.X "WAYLAND_DISPLAY=wayland-1 wl-paste" | xclip -selection clipboard'
```

- `pasteVM` → empuja lo copiado en el host, hacia el clipboard de la VM.
- `copyVM` → trae lo copiado en la VM, hacia el clipboard del host.


