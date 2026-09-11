# tmux — Cheatsheet

> Setup para manejar varios CLIs de agentes en paralelo.
> Linux Mint 22.3 (base Ubuntu 24.04) · prefijo configurado en `Ctrl+A`

---

## Instalación

```bash
sudo apt update && sudo apt install tmux xclip
tmux -V
```

---

## Config — `~/.tmux.conf`

```bash
# --- prefijo ---
set -g prefix C-a
unbind C-b
bind C-a send-prefix          # Ctrl+A dos veces = Ctrl+A real en la shell

# --- básico ---
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g history-limit 50000
set -sg escape-time 10        # sin esto el ESC se siente laggeado

# --- alertas: qué agente terminó ---
setw -g monitor-silence 30
set -g visual-silence on
set -g silence-action other   # avisa solo de ventanas que no estás mirando

# --- splits que no te hacen pensar ---
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# --- recargar config ---
bind r source-file ~/.tmux.conf \; display "config recargada"

# --- copiar al portapapeles del sistema ---
bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "xclip -sel clip -i"
```

---

## Desde la shell

| Comando | Qué hace |
| :--- | :--- |
| `tmux new -s agentes` | crear sesión llamada `agentes` |
| `tmux ls` | listar sesiones |
| `tmux a -t agentes` | volver a la sesión (attach) |
| `tmux kill-session -t agentes` | matar la sesión |

---

## Dentro de tmux

Todo va **después de `Ctrl+A`** — soltás y apretás la tecla.

### Ventanas — una por modelo

| Tecla | Qué hace |
| :---: | :--- |
| `c` | ventana nueva |
| `1` … `9` | saltar a esa ventana |
| `,` | renombrar la ventana actual |
| `n` / `p` | siguiente / anterior |
| `w` | listar ventanas y elegir |
| `&` | cerrar ventana |

### Paneles — splits dentro de una ventana

| Tecla | Qué hace |
| :---: | :--- |
| `\|` | split vertical |
| `-` | split horizontal |
| `←↑↓→` | moverte entre paneles |
| **`z`** | **maximizar el panel actual (toggle)** |
| `x` | cerrar panel |
| `{` / `}` | rotar posición del panel |

> `z` es el más útil de todos: tenés los cuatro agentes a la vista para ver el estado
> general, y cuando querés laburar con uno lo ponés a pantalla completa.

### Sesión

| Tecla | Qué hace |
| :---: | :--- |
| `d` | detach — deja todo corriendo |
| `r` | recargar `~/.tmux.conf` |
| `?` | ver todos los atajos |
| `t` | reloj (sí, existe) |

---

## Gotchas

**Copiar texto**
Con `mouse on`, la selección va al buffer de tmux y no al portapapeles del sistema.
Mantené **`Shift`** mientras seleccionás para usar la selección nativa de la terminal
de Mint. O usá el bind de `xclip` que está en la config.

**Quedaste trabado y no tipea nada**
Estás en *copy-mode* (te metió el scroll del mouse). Salís con **`q`**.

**Reinicio de la máquina**
tmux te sobrevive a cerrar la terminal, pero **no** a reiniciar. Las sesiones se pierden.

---

## Flujo sugerido

1. `tmux new -s agentes`
2. `Ctrl+A` `,` → renombrar a `claude`, arrancar el CLI ahí
3. `Ctrl+A` `c` → ventana nueva, renombrar, arrancar el siguiente
4. Saltar con `Ctrl+A` + número
5. `Ctrl+A` `d` para salir sin matar nada

Arrancá con **dos** modelos nomás hasta tener el reflejo de `Ctrl+A` + número.
Si el aviso de silencio a 30s te molesta, subilo a 60 en `monitor-silence`.
