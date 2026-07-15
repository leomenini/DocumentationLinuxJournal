# PostgreSQL en Linux Mint 22.3 (Zena) - Guía de instalación

## Problema 1: El script de PostgreSQL detecta `zena`

Al ejecutar:

```bash
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh
```

aparece:

```text
Your system is using the distribution codename zena...
```

### Causa

Linux Mint utiliza su propio **codename** (`zena`), mientras que el repositorio oficial de PostgreSQL solo reconoce los codenames de Ubuntu y Debian.

Linux Mint 22.3 **Zena** está basado en **Ubuntu 24.04 Noble Numbat**.

### Solución

Ejecutar el script indicando explícitamente el codename de Ubuntu:

```bash
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh noble
```

Luego:

```bash
sudo apt update
sudo apt install postgresql-18
```

(Instalar la versión disponible que se desee.)

---

# Problema 2: `psql` devuelve

```text
FATAL: role "leo" does not exist
```

### Causa

`psql` intenta conectarse utilizando el nombre del usuario de Linux.

Si el usuario del sistema es:

```text
leo
```

PostgreSQL intenta iniciar sesión con el rol:

```text
leo
```

Si ese rol todavía no existe, aparece ese error.

### Solución

Entrar como el superusuario de PostgreSQL:

```bash
sudo -u postgres psql
```

Crear el usuario:

```sql
CREATE ROLE leo WITH LOGIN CREATEDB PASSWORD 'tu_password';
```

Crear una base de datos propia:

```sql
CREATE DATABASE freecodecamp OWNER leo;
```

Salir:

```sql
\q
```

Conectarse con el nuevo usuario:

```bash
psql -U leo -d freecodecamp -h localhost
```

---

Por lo tanto:

* PostgreSQL del host → desarrollo personal
* PostgreSQL del contenedor → únicamente Nextcloud.

Ambos funcionan de forma independiente.

---

# Comandos útiles de `psql`

```sql
\l          -- listar bases de datos
\c nombre   -- conectarse a una base
\dt         -- listar tablas
\d tabla    -- describir una tabla
\du         -- listar usuarios (roles)
\conninfo   -- mostrar la conexión actual
\q          -- salir
```

