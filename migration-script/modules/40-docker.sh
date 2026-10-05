#!/usr/bin/env bash
# Por cada proyecto Docker: dump SQL del contenedor de DB (mientras corre), después para el/los
# contenedor(es), tarea los volúmenes con un contenedor helper (sin tocar /var/lib/docker a mano)
# y levanta todo de nuevo. Guarda también `docker inspect` de cada contenedor.

_docker_volume_names() {
  docker inspect -f '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{"\n"}}{{end}}{{end}}' "$1" 2>/dev/null
}

_tar_volume() {
  local volume="$1" dest_dir="$2"
  log "Empaquetando volumen $volume..."
  docker run --rm \
    -v "$volume":/data:ro \
    -v "$dest_dir":/backup \
    alpine:latest \
    tar czf "/backup/${volume}.tar.gz" -C /data . >/dev/null
}

_dump_volumes_for() {
  local voldir="$1"; shift
  local c v
  for c in "$@"; do
    [[ -z "$c" ]] && continue
    for v in $(_docker_volume_names "$c"); do
      _tar_volume "$v" "$voldir"
    done
  done
}

_pg_dump_container() {
  local container="$1" out_sql="$2"
  local running
  running=$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null || echo "false")
  if [[ "$running" != "true" ]]; then
    warn "$container no está corriendo, no puedo pg_dumpall (arrancalo primero con 'docker start $container' si hace falta el dump)"
    return 0
  fi
  local user
  user=$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$container" 2>/dev/null \
    | grep -m1 '^POSTGRES_USER=' | cut -d= -f2)
  user=${user:-postgres}
  log "pg_dumpall en $container (usuario $user) -> $out_sql"
  docker exec "$container" pg_dumpall -U "$user" > "$out_sql" 2>/dev/null \
    || warn "pg_dumpall falló en $container (¿usuario distinto de '$user'? revisar a mano)"
}

module_40_docker() {
  require_cmd docker
  local out="$DEST/40-docker"
  mkdir -p "$out/inspect" "$out/volumes" "$out/sql"

  local entry compose_dir main_c db_c
  for entry in "${DOCKER_PROJECTS[@]:-}"; do
    [[ -z "$entry" ]] && continue
    IFS=: read -r compose_dir main_c db_c <<<"$entry"
    docker inspect "$main_c" > "$out/inspect/${main_c}.json" 2>/dev/null || {
      warn "contenedor $main_c no existe, salteo proyecto $entry"; continue
    }
    [[ -n "$db_c" ]] && docker inspect "$db_c" > "$out/inspect/${db_c}.json" 2>/dev/null
    [[ -n "$db_c" ]] && _pg_dump_container "$db_c" "$out/sql/${db_c}.sql"

    with_containers_stopped "$main_c $db_c" _dump_volumes_for "$out/volumes" "$main_c" "$db_c"
  done

  local c
  for c in "${DOCKER_STANDALONE_DB_CONTAINERS[@]:-}"; do
    [[ -z "$c" ]] && continue
    docker inspect "$c" > "$out/inspect/${c}.json" 2>/dev/null || { warn "contenedor $c no existe"; continue; }
    _pg_dump_container "$c" "$out/sql/${c}.sql"
    with_containers_stopped "$c" _dump_volumes_for "$out/volumes" "$c"
  done

  docker ps -a > "$out/containers.txt"
  docker system df > "$out/df.txt"

  sha256_dir "$out"
  manifest_record_module "docker" "40-docker"
  ok "Docker listo"
}
