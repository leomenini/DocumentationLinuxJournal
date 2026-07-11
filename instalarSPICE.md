# Compartir carpetas entre host Linux y VM Windows 10 (virt-manager/QEMU-KVM) vía SPICE WebDAV (NOMBRE DE LA VM ES win10)

Guía para reproducir el setup completo desde cero. Cubre las trampas típicas que aparecieron en el proceso real.

## Resumen del método

SPICE permite compartir una carpeta del host con el guest a través de un canal dedicado (`org.spice-space.webdav.0`) que expone la carpeta como un recurso WebDAV local dentro de la VM (`http://localhost:9843/`). Se necesitan piezas en **tres lugares**: el XML de la VM, el guest Windows, y el visor SPICE del lado host.

---

## 1. Instalar software en el guest Windows

Dos instaladores **separados** (uno no incluye al otro):

- **SPICE Guest Tools** (drivers + agente, para portapapeles/resolución):
  `https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe`

- **spice-webdavd** (el que habilita específicamente compartir carpetas):
  `https://www.spice-space.org/download/windows/spice-webdavd/` → elegir el `.msi` de 64 bits

Instalar los dos, en ese orden. Verificar en `services.msc` que **spice-webdavd** quede en estado "Running".

Un servicio para copiar y otro para transferir archivos entre host y VM, en qemu/KVM el XML se puede generar solo al instalar y hacer reboot de la VM.

## 2. Agregar el canal webdav en el XML de la VM

Con la VM apagada:

```bash
virsh shutdown win10
virsh edit win10
```

Junto al canal existente del agente (`com.redhat.spice.0`), agregar:

```xml
<channel type='spiceport'>
  <source channel='org.spice-space.webdav.0'/>
  <target type='virtio' name='org.spice-space.webdav.0'/>
  <address type='virtio-serial' controller='0' bus='0' port='2'/>
</channel>
```

> Nota: en versiones recientes de virt-manager este canal puede agregarse automáticamente al instalar los guest tools. Verificar antes de agregarlo a mano:
> ```bash
> virsh dumpxml win10 | grep -A5 webdav
> ```

## 3. Habilitar un socket SPICE accesible

Por default, virt-manager puede dejar `<graphics type='spice'><listen type='none'/></graphics>`, que **no expone ningún socket usable** por `remote-viewer` — solo permite la consola embebida de virt-manager (que no soporta compartir carpetas).

Editar el XML (VM apagada) y cambiar a:

```xml
<graphics type='spice'>
  <listen type='socket' socket='/var/lib/libvirt/qemu/spice-win10.sock'/>
  <image compression='off'/>
</graphics>
```

## 4. Prender la VM y abrir remote-viewer

**Importante:** virt-manager **no** tiene la opción de carpeta compartida en su consola embebida. Hay que usar el visor SPICE independiente (`remote-viewer`, del paquete `virt-viewer`):

Teniendo presente el siguiente fragmento de la configuracion de la VM
```xml
<graphics type='spice'>
  <listen type='socket' socket='/var/lib/libvirt/qemu/spic-<nombreVM>.sock'/>
  ...
</graphics>

```
Esa ruta (/var/lib/libvirt/qemu/spice-win10.sock) es la que elegiste vos al editar el XML — no es un valor fijo de libvirt.
El comando final tiene la estructura:
```bash
remote-viewer spice+unix://<la_ruta_que_pusiste_en_el_socket>
```

```bash
sudo apt install virt-viewer
virsh start (nombre_de_la_VM)
remote-viewer spice+unix:///var/lib/libvirt/qemu/spice-win10.sock
```
Para sacar el puerto, con la VM encendida haces:

```bash
virsh domdisplay nombre_de_tu_vm
```
Queda algo como `spice://127.0.0.1:5900`

## 5. Activar la carpeta compartida (cada sesión)

Dentro de la ventana de `remote-viewer` (no en virt-manager):

**File → Preferences → Share Folder** → tildar y elegir la carpeta del host (ej. `~/Public`).

**Esto no persiste entre reinicios de la VM.** Cada vez que se reinicia la VM, el canal vuelve a `disconnected` y hay que volver a tildar el share manualmente en remote-viewer. Se puede confirmar el estado con:

```bash
virsh dumpxml win10 | grep -A5 webdav
```
Debe decir `state='connected'`.

## 6. Acceder a la carpeta desde Windows

Debería aparecer sola en **Este equipo**. Si no:

- Probar en la barra de direcciones del explorador: `http://localhost:9843/`
- O mapear manualmente: `net use Z: http://localhost:9843/`
- Script de mapeo (si existe): `C:\Program Files\SPICE webdavd\map-drive.bat`
- Puede ser que exista tambien en `C:\Program Files (x86)\Spice webdav\` dependiendo la instalacion
---

## Problemas encontrados y solución

### Error 67 al hacer `net use` ("network name cannot be found")
Causa típica: el servicio **WebClient** de Windows (el redirector WebDAV nativo, distinto de spice-webdavd) no está corriendo.

```cmd
sc query webclient
sc start webclient
```

En algunas ediciones de Windows hay que habilitarlo desde "Activar o desactivar las características de Windows" → Cliente WebDAV.

### Error 0x800700DF ("the file size exceeds the limit allowed")
El cliente WebDAV de Windows limita transferencias a 50 MB por default. Para subir el límite (ej. a ~4GB):

```cmd
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WebClient\Parameters" /v FileSizeLimitInBytes /t REG_DWORD /d 4294967295 /f
net stop webclient
net start webclient
```

De otra manera el editor de variables del registro en el siguiente path:

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WebClient\Parameters

Editamos en el file FileSizeLimitInBytes con:
(4294967295) Bytes es el equivalente a 4GB de transferencia.

Luego reiniciamos el servicio en cmd como arriba.

---

## Alternativa más simple para transferencias puntuales

Si esto se necesita solo ocasionalmente y no vale la pena mantener el setup, una opción sin SPICE/red es montar un ISO con los archivos:

```bash
genisoimage -o /tmp/transfer.iso -J -r /ruta/con/tus/archivos
```

Agregarlo en caliente desde virt-manager: **Add Hardware → Storage → seleccionar el .iso → Device type: CDROM**. Aparece como unidad de DVD en Windows, de solo lectura.


Para intercambiar archivos 
En host habilitar por sesion en preferencias file transfer(public folder)

entrar en explorador en local VM:
\\localhost@9843\DavWWWRoot
O en navegador en:
http://localhost:9843/

- Localhost:XXXX puede variar por VM o SO instalado

