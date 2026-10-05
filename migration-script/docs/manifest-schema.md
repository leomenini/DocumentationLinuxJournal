# `manifest.json`

Generado por `backup.sh` al final de una corrida completa (no en `--dry-run`, ni con `--only`
salvo que decidas que un subconjunto también es un "backup" válido — el manifest solo registra
los módulos que efectivamente corrieron en esa invocación).

```jsonc
{
  "created_at": "2027-03-01T10:00:00-03:00",   // ISO 8601, momento en que se armó el manifest
  "hostname": "<host>",
  "os_release": "NAME=\"Debian GNU/Linux\" VERSION=\"13 (trixie)\" ",
  "kernel": "6.12.0-amd64",
  "pkg_manager": "apt",                         // apt | dnf | pacman | zypper | desconocido
  "tool_commit": "a1b2c3d",                     // commit corto de este repo al momento del backup
  "modules": [
    {
      "module": "inventory",
      "dir": "00-inventory",                    // relativo a la raíz del backup
      "size_bytes": 45210,
      "checksums": "00-inventory/checksums.sha256"
    }
    // ... uno por cada módulo que corrió
  ]
}
```

## Para qué sirve cada campo

- **`pkg_manager`**: lo primero que chequea `restore.sh` contra el gestor de la máquina nueva.
  Si difiere, avisa que los nombres de paquete van a necesitar traducción manual.
- **`tool_commit`**: si algún día un backup se ve raro, `git show <tool_commit>` en este mismo
  repo muestra exactamente qué versión de los módulos lo generó — clave para el determinismo:
  el backup queda atado a una versión específica y auditable de la herramienta, no a "lo que
  el script hacía esa semana".
- **`modules[].checksums`**: `backup.sh --verify <dest>` recorre esta lista y corre
  `sha256sum -c` en cada uno. Si un módulo no corrió en esa invocación, simplemente no aparece
  acá — no es un error, es información de qué se respaldó esa vez.
