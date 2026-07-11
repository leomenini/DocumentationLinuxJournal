# Instalación de Docker en Linux PC

## Verificar sistema operativo

```bash
cat /etc/os-release
```

Salida:

```
NAME="Linux Mint"
VERSION="22.3 (Zena)"
ID=linuxmint
ID_LIKE="ubuntu debian"
PRETTY_NAME="Linux Mint 22.3"
VERSION_ID="22.3"
HOME_URL="https://www.linuxmint.com/"
SUPPORT_URL="https://forums.linuxmint.com/"
BUG_REPORT_URL="http://linuxmint-troubleshooting-guide.readthedocs.io/en/latest/"
PRIVACY_POLICY_URL="https://www.linuxmint.com/"
VERSION_CODENAME=zena
UBUNTU_CODENAME=noble -----> ESTO PRECISAMOS PARA INSTRUCCIONES DE DOCKER
```

## Actualizar paquetes

```bash
sudo apt update
```

## Instalar certificados

```bash
sudo apt install ca-certificates curl
```

## Crear directorio para keyrings

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

## Descargar claves GPG de Docker

```bash
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
-o /etc/apt/keyrings/docker.asc
```

```bash
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

## Agregar repositorio de Docker

```bash
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

## Actualizar repositorios

```bash
sudo apt update
```

Salida esperada:

```
Get:6 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages [58,9 kB]
Hit:7 http://archive.ubuntu.com/ubuntu noble-updates InRelease                 
...
```

## Instalar Docker Engine

```bash
sudo apt install docker-ce docker-ce-cli containerd.io
```

## Verificar versión

```bash
docker --version
```

## Probar instalación

```bash
sudo docker run hello-world
```

Salida esperada:

```
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
4f55086f7dd0: Pull complete 
d5e71e642bf5: Download complete 
Digest: sha256:96498ffd522e70807ab6384a5c0485a79b9c7c08ca79ba08623edcad1054e62d
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/ --> Revisar
```

## Dar permisos de administrador (evitar sudo)

```bash
sudo usermod -aG docker $USER
```

> **Nota:** Cerrar sesión y volver a iniciar para aplicar los cambios de grupo.
