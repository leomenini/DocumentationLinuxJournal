#!/usr/bin/env bash
# Dump del PostgreSQL corriendo directo en el host (si hay uno). No toca contenedores.

module_50_postgres_host() {
  local out="$DEST/50-postgres-host"

  if ! command -v pg_dumpall >/dev/null 2>&1; then
    warn "no hay pg_dumpall en el host, salteo el módulo de PostgreSQL del host"
    return 0
  fi
  if ! sudo -n true 2>/dev/null && ! pg_isready >/dev/null 2>&1; then
    warn "no puedo confirmar que haya un PostgreSQL de host corriendo, salteo"
    return 0
  fi

  mkdir -p "$out"
  log "pg_dumpall del host -> $out/host.sql"
  if sudo -n -u postgres pg_dumpall > "$out/host.sql" 2>/dev/null; then
    :
  else
    warn "pg_dumpall como 'postgres' vía sudo falló (¿necesita contraseña?); probá a mano:"
    warn "  sudo -u postgres pg_dumpall > $out/host.sql"
    return 0
  fi

  [[ -d /etc/postgresql ]] && cp -a /etc/postgresql "$out/etc-postgresql"

  sha256_dir "$out"
  manifest_record_module "postgres-host" "50-postgres-host"
  ok "PostgreSQL del host listo"
}
