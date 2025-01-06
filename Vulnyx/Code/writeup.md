# Writeup - Code - VulNyx

<img src="https://github.com/user-attachments/assets/f4c31131-c4b4-42a7-ac42-613559503b7d">


## Scanning network

Escaneamos la red para encontrar la ip a atacar y la encontramos -> 192.168.1.56
```shell
netdiscover -r 192.168.1.0/24
```
Una vez descubierta la ip, realizamos un escaneo sencillo de todos los puertos para identificar posibles vectores de ataque:
```shell
nmap -p- --open --min-rate 5000 -sS -n -Pn 192.168.1.56 -oN firstNmap.txt
```
		Port	State	Service		TTl
		22/tcp 	open  	ssh     	syn-ack ttl 64
		80/tcp 	open  	http    	syn-ack ttl 64
		
Reconociendo los puertos 22 (SSH) y 80 (HTTP) podemos realizar un escanéo más exhaustivos sobre los puertos para poder visualizar los servicios alojados y sus versiones.
```shell
nmap -p 22,80 -sVC 192.168.1.56 -oN secondNmap.txt
```
## Enumeration

Mientras se ejecuta, podemos listar los directorios disponibles de la página web
```shell
dirb http://192.168.1.56 /usr/share/wordlists/big.txt -o dirb.txt
```
Encontramos una página /pluck que aloja una aplicación

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/pluck_web.png">

Y en uno de los directorios, tenemos un login:

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/pluck_login.png">

Probamos credenciales por defecto como admin:admin voila! Estamos dentro.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/admin_logued.png">

## Exploitation

Tenemos diferentes páginas para revisar, pero una de ellas, dentro de módulos tenemos una opción de subir módulos.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/uploadModules.png">

Estos módulos, tienen que ser específicos de Nginx para poder cargarlos, pero podemos probar a cargar una reverse shell para ver si se refleja de alguna forma, todo esto sin lograrlo

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/errorUploading_shellphp.png">

Revisando más directorios, nos encontramos con uno de subida de ficheros, en este sí se va a poder subir una reverse shell con php. El único problema es que al subir un archivo con extension php, el servidor te añade la extensión txt y no se refleja la ejecución del código.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/rfi.png">

Por lo que podemos probar a ver qué tipos de php (hay muchos) están en la blacklist. Podemos probar a mano o podemos automatizarlo a partir de un script o de BurpSuite. En mi caso, probé con una extensión phar y pasó el control y se subió de forma correcta.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/rce_whoami.png">

El archivo phar, tenía en un principio la función exec() pero parece ser que no lo reconocía por lo que se le cambió a system().

Nos ponemos en escucha en el puerto específico de la reverse shell y ejecutamos el comando.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/remoteShell_executed.png">

Tenemos acceso!

## Privilege escalation

Tenemos acceso como www-data, ahora nos toca escalar privilegios a root y los usuarios disponibles, que vemos que es Dave ya que lo primero que intentamos es ver los permisos de sudo que tiene www-data.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/sudo-l.png">

Escalamos a dave con un sencillo:
```shell
sudo -u dave bash
```
<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/dave_escalated.png">

Y tenemos la primera flag del laboratorio.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/user_flag.png">

Ahora toca escalar a root. Miramos los permisos de sudo de dave y encontramos que tiene permisos de ejecutar Nginx sin contraseña como root. Revisamos lo primero el manual de Nginx para poder identificar alguna forma de explotar los permisos y escalar a root.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/nginx_man.png">

Vemos que con la flag "-c" podemos cargar un archivo de configuración propio y diferente al por defecto. Para poder cargar uno, tenemos que ver qué estructura tiene y cómo funciona, y esto con la flag de "-T" que te carga el archivo de configuración indicado y busca posibles problemas y te lo muestra.

	user root;
	server {
       listen [::]:65000 default_server;

       server_name _;

       root /var/www/html;
       index index.html index.htm index.nginx-debian-html;

       location / {
               try_files $uri $uri/ =404;
       }
	}

Quitamos y recargamos el servicio con el nuevo archivo:

```shell
sudo nginx -s quit
sudo nginx -c /home/dave/newConfigNginx
```

Aquí, podemos observar varias cosas, además de la configuración del server, podemos observar que podemos determinar qué usuario ejecuta el servicio web. Nos interesa que sea root el que ejecute el proceso, para así si conseguimos vulnerar el servidor web, tendremos acceso como root. Por otro lado, vemos que solo se está ejecutando de forma local, por eso al principio con nuestros escaneos de Nmap, no habíamos sido capaces de identificar el servicio web. Y vemos que hay una línea "root /var/www/html" que nos puede indicar dónde se ejecuta el servicio. Por lo que cambiamos la configuración. Y ejecutamos:

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/visualizacionRemota_nginx1.png">

Con esta configuración, mi idea fue activar php para Nginx y que fuese root el que ejecutase el código, pero no fue posible por lo que tuve que encontrar otra forma. Cambié el root de la configuración para ver si se podrían visualizar ficheros locales desde el servicio web.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/seeing_bashrc_root_nginx.png">

Podemos ver archivos de forma remota, por lo que vamos a cambiar el root a /root para que se ejecute en el propio directorio de root (aunque podríamos simplemente intentar listarlo desde el root establecido en la configuración anterior).

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/newNginx_conf.png">

Con esta configuración, podemos intentar visualizar la flag de root, pero parece que el nombre no es el genérico de "root.txt". Además, los directorios no se pueden listar. En este caso podemos hacer dos cosas FUZZING de archivos dentro del directorio de root o probar a ver si existe una clave id_rsa de root para acceder de forma remota (solo es posible si sshd_config no está configurado para repeler el login de root).

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/id_rsa_root.png">

Tenemos la clave privada de root! Nos la pasamos a nuestro directorio dentro de nuestra máquina atacante y probamos acceder mediante SSH y la clave.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/passphrase_wrong.png">

Nos pide una passphrase y por desgracia no es una vacía. Lo "gracioso" es que la passprhase aparece hasheada dentro de la clave, por lo que podemos realizar un ataque de fuerza bruta/diccionario sobre el archivo para sacar la passphrase. Os adelanto, que no sirve de nada ya que no parece estar en las wordlists. Para esto usaremos ssh2john y john the ripper.

Desgraciadamente, no sirve, por lo que esperar a que acabe no será la opción. Vamos a buscar por posibles archivos dentro de la máquina que puedan albergar la passphrase de root.
```shell
find / -name "*pass* 2>/dev/null
```
Encontramos un archivo "pass.php" dentro del antiguo servicio web, pluck. Este archivo está en: "/var/www/html/pluck/data/settings/pas.php". No lo habíamos visto con el primer dirb, debido a que no teníamos permisos de acceso a /data y no hemos realizado una segunda pasada con las credenciales de admin.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/root_credsPosible.png">

Introducimos las posibles credenciales en la passphrase de SSH y tenemos acceso.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/root_shell.png">

Tenemos acceso como root. Buscamos la flag.

<img src="https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/root_flag.png">
