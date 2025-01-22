# WRITEUP - FIRE - VULNYX

![image](https://github.com/user-attachments/assets/4047d399-d6a3-40e4-9bb0-4375b62bc43e)

## Scanning Network
Realizamos un reconocimiento de la red para determinar la IP objetivo.
```shell
sudo netdiscover -r 192.168.1.0/24
```
Encontramos la ip 192.168.1.105 y pasamos a identificar los diferentes puertos abiertos que pueda tener la máquina.
```shell
nmap -p- --open -sS --min-rate 5000 -n -Pn 192.168.1.105 -oN firstNmap.txt
```
    PORT    STATE
    21      Open
    22      Open
    80      Open
    9090    Open
Una vez identificados los puertos, realizamos un segundo escaneo más intrusivo en el que le ejecutamos una serie de scripts por defecto y un reconocimiento de versiones de los servicios para determinar posibles vectores de ataque.
```shell
nmap -p 21,22,80,9090 -sVC 192.168.1.105 -oN secondNmap.txt
```

    PORT     STATE SERVICE         VERSION
    21/tcp   open  ftp             pyftpdlib 1.5.7
    | ftp-anon: Anonymous FTP login allowed (FTP code 230)
    |_-rw-r--r--   1 root     root      4442576 Sep 29  2023 backup.zip
    | ftp-syst: 
    |   STAT: 
    | FTP server status:
    |  Connected to: 192.168.1.105:21
    |  Waiting for username.
    |  TYPE: ASCII; STRUcture: File; MODE: Stream
    |  Data connection closed.
    |_End of status.
    22/tcp   open  ssh             OpenSSH 8.4p1 Debian 5+deb11u1 (protocol 2.0)
    | ssh-hostkey: 
    |   3072 f0:e6:24:fb:9e:b0:7a:1a:bd:f7:b1:85:23:7f:b1:6f (RSA)
    |   256 99:c8:74:31:45:10:58:b0:ce:cc:63:b4:7a:82:57:3d (ECDSA)
    |_  256 60:da:3e:31:38:fa:b5:49:ab:48:c3:43:2c:9f:d1:32 (ED25519)
    80/tcp   open  http            Apache httpd 2.4.56 ((Debian))
    |_http-server-header: Apache/2.4.56 (Debian)
    |_http-title: Apache2 Debian Default Page: It works
    9090/tcp open  ssl/zeus-admin?
    | ssl-cert: Subject: commonName=fire/organizationName=b8029c6b7a9c4c7d93fed3a3c6ab94bc
    | Subject Alternative Name: IP Address:127.0.0.1, DNS:localhost
    | Not valid before: 2024-12-27T10:32:25
    |_Not valid after:  2025-12-27T10:32:25
    |_ssl-date: TLS randomness does not represent time

Encontramos varios puertos abiertos, ya de primeras conseguimos ver gracias a los scripts por defecto lanzados en el nmap, que por el puerto 21 (FTP), podemos logearnos con el usuario "anonymous" sin credenciales y podemos decargarnos un comprimido "backup.zip"

Aunque antes de esto, mientras se estaba ejecutando el segundo nmap, revisamos los dos servicios web. En el puerto 80 (HTTP) se hospeda la página principal de un servicio Apache. En este caso, optamos a realizar un dirbuster por el servicio para poder determinar diferentes directorios. Mientras tanto, visitamos el otro servicio web que parece tratarse de HTTPS. En este servicio vemos una aplicación llamada: Cockpit. El cuál es una aplicación de administración de equipos de forma remota: https://cockpit-project.org/.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/webpage_cockpit.png>

Probamos diferentes cosas en el login de la página, pero no parece ser vulnerable a nada.

Ahora sí, toca pasar al servicio FTP y ver qué es eso de backup.zip. Nos lo descargamos fácilmente con wget:

```shell
wget ftp://191.168.1.105:21/backup.zip
```
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/ftp_backupZIP.png>

Descomprimimos el archivo:
```shell
unzip backup.zip
```
## Exploitation
Se nos creará un directorio mozilla en el que se habrán descomprimido los archivos. Realizando un pequeño análisis, nons encontramos con un archivo logins.json con contraseñas en él. Además, en la base de datos key4.db, obtenemos otros valores asociados a contraseñas. El directorio está plagado de archivos que nos pueden ir dando diferente información, aunque para este caso, es perder el tiempo intentando descifrar todo el contenido, intentar reestablecer las bases de datos y demás, que no es poco.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/logins_json.png>

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/key4_dump.png>

Si conocemos un poco cómo está gestionado firefox desde linux, encontraremos el arbol de directorios y archivos muy parecido a lo que tiene nuestro propio firefox, entre eso y el nombre de la capeta principal "mozilla/firefox" podemos suponer que es un backup de todas las configuraciones del navegador mozilla firefox. Una vez que sabemos esto, es fácil asumir el siguiente paso, importar las contraseñas antiguas a nuestro propio navegador. Para esto con una simple búsqueda encuentras que los dos únicos archivos necesarios para esto son: key3.db (en nuestro caso key4.db) y el famoso logins.json. Si visualizamos nuestro almacén de contraseñas, veremos que está vacio (a no ser que tengáis contraseñas guardadas aquí, que después de ver este writeup, seguro que se os quitan las ganas de guardar contraseñas en el navegador).

Antes:
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/firefox_passwords_blank.png>

Después de importar los dos ficheros a nuestro perfil de Firefox:
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/marco_password_firefox.png>

Tenemos a marco y unas posibles credenciales. Probamos estas credenciales en el login de Cockpit.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/login_credencialesMarco.png>

Voila! Tenemos acceso a la consola de management de cockpit.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/cockpit_system.png>

Una vez dentro, ojeamos un poco y vemos una pestaña llamada "Terminal", que nos abre una terminal interactiva dentro del sistema. Y obtenemos la flag de marco:

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/flag_user.png>

## Privilege Escalation
Ahora, intentaremos acceder a root para conseguir la última flag y así comprometer completamente el sistema.
```
sudo -l
```
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/sudo-l.png>

Observamos que tenemos permisos de utilizar units como root y sin contraseña. Analizamos qué hace units y cómo podemos realizar el escalado de privilegios a root.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/units-h.png>

Units -h ofrece un pequeño manual de su uso, ejecutamos !/bin/bash y tenemos una shell de root:

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/binBash_units-h.png>

Tenemos una shell como root y obtenemos su flag.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/root_whoami.png>

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Fire/Content/flag_root.png>
