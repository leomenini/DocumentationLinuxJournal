# Docker Cheat Sheet (Workshop)

## 1. Construcción de imágenes

Construir una imagen usando el Dockerfile del directorio actual:

```bash
docker build -t getting-started .
```

Construir una imagen con otro nombre:

```bash
docker build -t mi-app:v1 .
```

---

## 2. Ejecutar contenedores

Ejecutar un contenedor:

```bash
docker run getting-started
```

En segundo plano:

```bash
docker run -d getting-started
```

Publicar un puerto:

```bash
docker run -d -p 127.0.0.1:3000:3000 getting-started
```

Asignar un nombre:

```bash
docker run --name mi-app getting-started
```

---

## 3. Gestión de contenedores

Ver contenedores en ejecución:

```bash
docker ps
```

Ver todos (incluidos los detenidos):

```bash
docker ps -a
```

Detener un contenedor:

```bash
docker stop <container>
```

Iniciar uno detenido:

```bash
docker start <container>
```

Reiniciar:

```bash
docker restart <container>
```

Eliminar un contenedor:

```bash
docker rm <container>
```

Eliminar un contenedor detenido automáticamente al salir:

```bash
docker run --rm ...
```

---

## 4. Logs

Ver logs:

```bash
docker logs <container>
```

Seguir logs en tiempo real:

```bash
docker logs -f <container>
```

---

## 5. Entrar a un contenedor

Abrir una shell:

```bash
docker exec -it <container> sh
```

o

```bash
docker exec -it <container> bash
```

(según la imagen)

---

## 6. Inspección

Información completa del contenedor:

```bash
docker inspect <container>
```

Ver imágenes:

```bash
docker images
```

---

# Volúmenes

Crear:

```bash
docker volume create todo-db
```

Listar:

```bash
docker volume ls
```

Inspeccionar:

```bash
docker volume inspect todo-db
```

Eliminar:

```bash
docker volume rm todo-db
```

Montar un volumen:

```bash
docker run \
-v todo-db:/etc/todos \
getting-started
```

o

```bash
docker run \
--mount type=volume,src=todo-db,target=/etc/todos \
getting-started
```

---

# Bind Mounts

Compartir una carpeta del host:

```bash
docker run \
-v $(pwd):/app \
node:24-alpine
```

Sintaxis larga:

```bash
docker run \
--mount type=bind,src=$(pwd),target=/app \
node:24-alpine
```

---

# Redes

Crear una red:

```bash
docker network create todo-app
```

Conectar un contenedor:

```bash
docker network connect todo-app <container>
```

Listar redes:

```bash
docker network ls
```

Inspeccionar una red:

```bash
docker network inspect todo-app
```

---

# Docker Compose

Levantar todos los servicios:

```bash
docker compose up
```

En segundo plano:

```bash
docker compose up -d
```

Reconstruir imágenes:

```bash
docker compose up --build
```

Detener:

```bash
docker compose stop
```

Detener y eliminar contenedores y red:

```bash
docker compose down
```

Eliminar también los volúmenes:

```bash
docker compose down -v
```

Reiniciar un servicio:

```bash
docker compose restart app
```

Ver servicios:

```bash
docker compose ps
```

Ver logs:

```bash
docker compose logs
```

Logs de un servicio:

```bash
docker compose logs app
```

Seguir logs:

```bash
docker compose logs -f app
```

Entrar a un servicio:

```bash
docker compose exec app sh
```

---

# Docker Hub

Iniciar sesión:

```bash
docker login
```

Etiquetar una imagen:

```bash
docker tag getting-started usuario/getting-started:latest
```

Subir una imagen:

```bash
docker push usuario/getting-started:latest
```

Descargar una imagen:

```bash
docker pull usuario/getting-started:latest
```

---

# Limpieza

Eliminar imágenes no utilizadas:

```bash
docker image prune
```

Eliminar contenedores detenidos:

```bash
docker container prune
```

Eliminar todo lo que no se usa:

```bash
docker system prune
```

Eliminar absolutamente todo lo no utilizado (incluyendo imágenes):

```bash
docker system prune -a
```

---

# Conceptos importantes

**Image**

* Plantilla inmutable.
* Se construye con `docker build`.
* Se comparte con `docker push`.

**Container**

* Instancia en ejecución de una imagen.
* Puede eliminarse y recrearse.

**Volume**

* Datos persistentes administrados por Docker.
* Sobrevive aunque se elimine el contenedor.

**Bind Mount**

* Comparte una carpeta del host con el contenedor.
* Ideal para desarrollo.

**Docker Compose**

* Describe toda la aplicación en un archivo `compose.yml`.
* Evita escribir comandos largos de `docker run`.
