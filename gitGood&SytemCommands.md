# Comandos útiles



## Comandos de monitores (SETUP_ACTUAL_2026(xrandr)

Ver monitores conectados:

```bash
xrandr | grep " connected"
```

Solo monitor principal:

```bash
xrandr --output DVI-D-0 --auto --primary --output HDMI-0 --off
```

Solo monitor secundario:

```bash
xrandr --output HDMI-0 --auto --primary --output DVI-D-0 --off
```

Ambos extendidos:

```bash
xrandr --output DVI-D-0 --primary --auto --output HDMI-0 --auto --left-of DVI-D-0
```

---

## Comandos de sistema

Ver temperatura NVIDIA:

```bash
watch -n 2 nvidia-smi
```

Ver uso de RAM:

```bash
free -h
```

Ver discos:

```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
```

Analizar uso de disco:

```bash
ncdu /
```

Gestión de paquetes:

```bash
sudo aptitude
```

Ver servicios lentos al arrancar:

```bash
systemd-analyze blame | head -20
```

---

## IPv6
Puedes suceder que programas en beta o cosas raras les cueste o bloqueen conexiones por iPv6

Desactivar IPv6:

```bash
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
```

Activar IPv6:

```bash
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0
```

---

## SSH

Conectar y habilitar servidor SSH:

```bash
sudo systemctl enable --now ssh
```

---

## Comandos GitGood

### Inicializar repositorio

```bash
cd repoACommit
git init
git status
```

Crear `.gitignore`:

```bash
touch .gitignore
```

### Commits

```bash
git add .
git status
git commit -m "Comentario"
git push -u origin branchAcommit
```
(Hasta aca, luego desde github revisamos pull requests)
### Autenticar con SSH

```bash
ssh-keygen -t ed25519 -C "tu_correo@ejemplo.com"
```

Conectar repositorio remoto por SSH:

```bash
git remote set-url origin git@github.com:usuario/repo.git
git remote -v
git push -u origin main
```

### Clonar repos

```bash
git clone git@github.com:usuario/repo.git
```

### Branching

```bash
git checkout -b NombreBranch
git branch
git push -u origin experiment
git push
git checkout main
```

### Pulling

```bash
git pull
```

> `git pull` = `git fetch` (descarga cambios) + `git merge` (mezcla en current branch)

```bash
git pull --rebase
```

> Mantiene el historial limpio (reversible). Siempre hacer `git pull` antes de trabajar.
