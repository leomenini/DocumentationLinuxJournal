# Backup automático de GoodNotes vía WebDAV + Nextcloud + Tailscale Serve

Notas de referencia de la configuración hecha el 14/07/2026. Server: `server-name`, tailnet `*.ts.net`.

---

## 1. Qué se armó, en una línea

Nextcloud corriendo en Docker (puerto interno 8080 del host) → expuesto de forma privada dentro del tailnet vía `tailscale serve` con HTTPS válido → GoodNotes en el iPad hace backup automático por WebDAV a ese endpoint. Nunca sale nada a internet público.

---

## 2. Comandos clave (para reconfigurar desde cero)

### 2.1 Ver el contenedor de Nextcloud

```bash
docker ps
```

### 2.2 Configurar Nextcloud para que confíe en el hostname de Tailscale

Usar siempre `occ` (el comando interno de Nextcloud), nunca editar `config.php` a mano — evita romper permisos o sintaxis.

```bash
docker exec -u www-data nextcloud-nextcloud-1 php occ config:system:set trusted_domains 1 --value="tu-maquina.tu-tailnet.ts.net"
docker exec -u www-data nextcloud-nextcloud-1 php occ config:system:set overwriteprotocol --value="https"
docker exec -u www-data nextcloud-nextcloud-1 php occ config:system:set overwrite.cli.url --value="https://tu-maquina.tu-tailnet.ts.net"
docker exec -u www-data nextcloud-nextcloud-1 php occ config:system:set trusted_proxies 0 --value="127.0.0.1"
```

**⚠️ Gotcha importante:** `trusted_domains` va **sin** `https://` adelante — solo el hostname pelado. Nextcloud lo compara contra el header `Host` de la request, que nunca trae el esquema. Si lo cargás con `https://` incluido, Nextcloud va a seguir rechazando el dominio como "no confiable".

Verificar:

```bash
docker exec -u www-data <NexcloudContainer> php occ config:list system
docker restart <NexcloudContainer>
```

### 2.3 Levantar Tailscale Serve

```bash
sudo tailscale serve --bg 8080
tailscale serve status
```

Esto expone `hhttps://tu-maquina.tu-tailnet.ts.net` (puerto 443 implícito) haciendo proxy interno a `http://127.0.0.1:8080` (donde Docker publica Nextcloud).

Para sacarlo:

```bash
tailscale serve --https=443 off
```

### 2.4 Forzar la emisión del certificado 

```bash
sudo tailscale cer tu-maquina.tu-tailnet.ts.net
```

En teoría Serve emite el certificado solo en el primer request, pero puede haber una carrera contra el tiempo (el primer handshake TLS llega antes de que Let's Encrypt termine de responder). Correr `tailscale cert` a mano fuerza la emisión de una y soluciona el error "conexión no privada" de forma inmediata. Los certificados de Tailscale se renuevan solos después (duran 90 días).

### 2.5 Requisitos previos en el admin console de Tailscale

En `https://login.tailscale.com/admin/dns`:
- **MagicDNS**: Enabled
- **HTTPS Certificates**: Enabled

Sin estos dos, `tailscale serve`/`cert` no puede emitir nada válido.

### 2.6 Contraseña de aplicación en Nextcloud (para no usar la contraseña real)

*Configuración personal → Seguridad → Crear nueva contraseña de aplicación* → nombre tipo "GoodNotes iPad" → guarda usuario + password específicos, revocable sin tocar la cuenta principal.

### 2.7 Configuración en GoodNotes

*Ajustes → Copia de seguridad automática → WebDAV*:

```
Server URL: hhttps://tu-maquina.tu-tailnet.ts.net/remote.php/dav/files/<usuario>/
Usuario:    <usuario>
Contraseña: <la contraseña de aplicación, no la real>
```

**⚠️ Gotcha importante:** NO poner `:8080` en la URL. Ese puerto es interno (donde Docker publica el contenedor en el host) — Serve lo mapea puertas adentro, pero hacia afuera todo vive en el 443 implícito de `https://`. Pegarle directo a `:8080` con HTTPS no tiene nada escuchando TLS ahí, porque Nextcloud en ese puerto habla HTTP plano.

**Nota sobre la barra final:** agregar el `/` al final de la URL (`.../<usuario>/`) — algunos clientes WebDAV, Nextcloud incluido, son quisquillosos con eso.

### 2.8 Requisito en el iPad

El iPad tiene que tener la **app de Tailscale conectada** para que resuelva `*.ts.net` y llegue al server. Confirmar en la app: *Settings → usar DNS de Tailscale* activado. Como es Serve (no Funnel), esto **solo funciona dentro del tailnet** — si el iPad no está conectado a Tailscale, GoodNotes no va a poder hacer el backup automático.

---

## 3. Conceptos: para entender el "por qué", no solo el "cómo"

### 3.1 WebDAV — cómo GoodNotes hace el backup

WebDAV es HTTP normal (el mismo protocolo del navegador) con verbos extra para *escribir*, no solo leer: `PUT` (subir archivo), `MKCOL` (crear carpeta), `PROPFIND` (listar contenido), `DELETE`, `MOVE`. Nextcloud expone su WebDAV en `/remote.php/dav/files/<usuario>/`, mapeado 1 a 1 con los archivos de la cuenta.

GoodNotes no sabe ni le importa que del otro lado haya Nextcloud — es un cliente WebDAV genérico. Le das URL + usuario + contraseña, y cada tanto hace un `PUT` con el archivo comprimido de las notas. El mismo endpoint serviría con un NAS Synology, ownCloud, o cualquier otro server WebDAV.

**Por qué esto reemplaza a iCloud/Google Drive:** esos servicios son ecosistemas cerrados, con API propietaria y autenticación atada a una cuenta de Apple/Google — no controlás dónde vive el dato. Con Nextcloud propio, sos dueño del hardware, el storage y la data. Como WebDAV es un estándar abierto, cualquier app compatible (GoodNotes, Finder, `rclone`, otras apps de notas) puede usar tu propio server como backend, sin depender de un gigante tech.

### 3.2 TLS — qué es realmente

TLS (Transport Layer Security) es lo que encripta el tráfico HTTP → HTTPS. Pero no es *solo* encriptación: también verifica identidad. El server manda un **certificado digital** firmado por una Autoridad Certificadora (CA) de confianza (Let's Encrypt, DigiCert, etc.). Si el certificado no está firmado por una CA que el cliente reconoce, o es para un dominio distinto, no hay garantía de que el server sea quien dice ser (podría ser un ataque man-in-the-middle) — de ahí la advertencia de "conexión no privada". No es un capricho, es el mecanismo de seguridad funcionando como corresponde.

### 3.3 Reverse proxy — qué hace y por qué existe

Un reverse proxy se para *adelante* de uno o varios servicios backend y reenvía las conexiones entrantes. Lo más común que hace es **terminar TLS**: recibe HTTPS desde afuera, lo descifra, y le habla al backend en HTTP plano puertas adentro (exactamente lo que hicimos: Serve en 443 → Nextcloud en 8080 sin TLS). También puede rutear por dominio/ruta, balancear carga, agregar headers de seguridad.

**nginx, Caddy, Traefik, HAProxy** son los jugadores clásicos: softwares de propósito general que instalás vos, configurás a mano (archivos `.conf`, bloques `server {}`/`location {}`), y para los cuales vos mismo tenés que conseguir el certificado — típicamente con `certbot` (cliente de Let's Encrypt), lo cual generalmente requiere dominio propio y a veces abrir puertos en el router.

### 3.4 Tailscale Serve vs. un reverse proxy tradicional

Conceptualmente es lo mismo (reverse proxy que termina TLS y reenvía a un puerto local), pero:

| | nginx / Caddy / Traefik | Tailscale Serve |
|---|---|---|
| Configuración | archivo `.conf` a mano | un comando (`tailscale serve <puerto>`) |
| Certificado | lo conseguís vos (`certbot`, dominio propio) | lo emite Tailscale automático para `*.ts.net` |
| Exposición | pública si abrís el puerto en el router | **solo dentro del tailnet**, nunca público |
| Setup para HTTPS casero | requiere dominio, DNS, a veces port-forwarding | cero configuración de red |

### 3.5 Serve vs. Funnel (para el futuro)

- **`tailscale serve`** → privado, solo alcanzable por dispositivos conectados a tu tailnet. Esto es lo que usamos.
- **`tailscale funnel`** → lo mismo, pero expuesto **públicamente a internet** (cualquiera con el link, sin necesitar Tailscale). Requiere habilitar el atributo `funnel` en la política del tailnet (admin console → Access controls). Solo tiene sentido si algún día necesitás que GoodNotes (u otra app) respalde **sin** tener la VPN de Tailscale activa en el dispositivo. Trae más superficie de exposición, usar con cuidado.

---

## 4. Checklist rápido para reconfigurar desde cero 

1. `docker ps` → confirmar nombre del contenedor Nextcloud
2. `occ config:system:set trusted_domains/overwriteprotocol/overwrite.cli.url/trusted_proxies` (hostname **sin** `https://` en trusted_domains)
3. `docker restart <contenedor>`
4. Admin console de Tailscale → confirmar MagicDNS + HTTPS Certificates habilitados
5. `sudo tailscale serve --bg <puerto-host-de-nextcloud>`
6. `sudo tailscale cert <hostname>.ts.net` (por las dudas, para forzar emisión inmediata del cert)
7. Probar en navegador de escritorio primero: `https://<hostname>.ts.net`
8. Generar contraseña de aplicación en Nextcloud para GoodNotes (no usar la real)
9. Configurar GoodNotes con la URL WebDAV **sin puerto**: `https://<hostname>.ts.net/remote.php/dav/files/<usuario>/`
10. Confirmar que el iPad tenga Tailscale conectado y usando su DNS
