# Bitácora VM Arch Linux — setup con repo de sway en wayland mediante paquete AUR

## 1. Intento de clipboard/transferencia con spice-vdagent

**Causa encontrada:** el agente SPICE en Linux tiene dos partes:
- `spice-vdagentd`: demonio del sistema (systemd), corre siempre.
- `spice-vdagent`: agente por sesión X11, que solo se autoarranca con un DE completo (GNOME, XFCE, KDE) o `gdm`. En un WM pelado o consola pura, no arranca solo.

- **SSH** desde el host (Mint) a la IP de la VM, cuando hay red configurada.
- **`virsh console`** como alternativa sin depender de red (ver sección 2).

## 2. Consola serial (`virsh console`)

Método para conectarse a la consola de texto de la VM directo desde una terminal del host, sin necesitar red ni SPICE.

### Requisitos usados (ya estaban en el XML de esta VM)
```xml
<serial type='pty'>
  <target type='isa-serial' port='0'>
    <model name='isa-serial'/>
  </target>
</serial>
<console type='pty'>
  <target type='serial' port='0'/>
</console>
```

### Del lado del guest, hay que habilitar el getty
```bash
sudo systemctl enable --now serial-getty@ttyS0.service
```

### Uso
```bash
virsh console archlinux
```

### Parámetro de kernel opcional (para ver también los logs de boot en esa consola)
Con systemd-boot, en `/boot/loader/entries/*.conf`, agregar al final de la línea `options`:
```
console=tty0 console=ttyS0,115200
```
(Agregado al archivo; reinicio pendiente para que tome efecto en el boot.)

### Por qué sirve
- Útil antes de tener red configurada (mitad de instalación).
- Útil si X/SPICE se rompe y hay que debuggear sin nada gráfico.
- No depende de IP ni sshd corriendo, solo del kernel escribiendo en ese puerto.


## 3. Instalar git

```bash
sudo pacman -S git
```

## 4. Instalar un AUR helper (yay)

Necesario porque el repo de Sway requiere un paquete de AUR (`iwgtk`).

```bash
sudo pacman -S --needed base-devel git
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si   # NUNCA con sudo — makepkg lo bloquea explícitamente por seguridad
```

Verificación:
```bash
yay --version
# yay v13.0.1 - libalpm v16.0.1
```

## 6. Clonar y armar el setup de Sway

Repo: [`carlosplanchon/sway-workstation`](https://github.com/carlosplanchon/sway-workstation) — dotfiles de Sway + Waybar + iwd manejados con GNU Stow.

```bash
git clone https://github.com/carlosplanchon/sway-workstation.git
cd sway-workstation
```

### Dependencias de repos oficiales
```bash
sudo pacman -S --needed - < packages.txt
```

### Dependencia de AUR (GUI de iwd)
```bash
yay -S iwgtk
```

### Bootstrap del repo
```bash
./bin/bootstrap.sh
```
Detecta hardware (sensor de temperatura — en esta VM no hay sensor real, usó fallback seguro), symlinkea configs de Sway/Waybar con Stow, instala wallpaper default. El warning de `perl`/locale que apareció es inofensivo 
(falta generar el locale `en_US.UTF-8`, cayó a `C` sin problema).

## 7. Arrancar Sway

Desde la consola **gráfica** de la VM (no la serial — Sway es Wayland, necesita la ventana de video de virt-manager):

```bash
sway
```

### Binds esenciales (custom de este repo + defaults de Sway)

`$mod` = tecla Super/Logo.

| Tecla | Acción |
|---|---|
| `Super + Enter` | Terminal |
| `Super + Shift + Q` | Cerrar ventana |
| `Super + Shift + C` | Recargar config |
| `Super + h/j/k/l` | Mover foco entre ventanas |
| `Super + D` / `Super + T` | Launcher (drun) |
| `Super + 1`…`0` | Workspaces 1-10 |
| `Super + Alt + 1`…`0` | Workspaces 11-20 |
| `Super + Shift + (número)` | Mover ventana a workspace |
| `Super + Tab` | Último workspace usado |
| `Super + N` / `Super + M` | Teclado latam / us |
| `Super + Shift + X` | Bloquear pantalla |
| `Super + U` / `Super + I` | Screenshot región / completa |
| `Super + Shift + P` / `O` | Volumen +/- |
| `Super + Shift + M` | Mute |
| `Super + R` | Modo resize |

Para salir de Sway: `swaymsg exit` desde una terminal dentro de la sesión.

---


###Conectar por SSH

- En vm:
```bash
sudo pacman -S openssh
ip addr show
```

Esperamos algo como: 192.168.122.x
si estás en la red NAT default de libvirt

- En host:
```bash
❯ ssh leo@192.168.122.x
```

###Se puede entrar directo desde host a cualquier VM con lo siguiente:

- En host:
```bash
❯ virsh console archlinux
```
- En vm:
```bash
sudo systemctl enable --now serial-getty@ttyS0.service
```
Crea un symlink que deja entrar desde el host por terminal
