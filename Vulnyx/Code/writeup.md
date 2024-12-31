Writeup


ip a atacar 192..168.1.56 (netdiscover)

first nmap -> 	22/tcp open  ssh     syn-ack ttl 64
		80/tcp open  http    syn-ack ttl 64
		
second nmap -> 

dirb no produce efecto, en este caso usar otros wordlisst ya que por defecto usa la common.txt
Con la big.txt, encontramos muchos más directorios
dirb http://192.168.1.56 /usr/share/dirb/wordlists/big.txt -o dirb.txt


probamos admin como password y voila!

Blacklist de archivos https://loopspell.medium.com/cve-2020-29607-remote-code-execution-via-file-upload-restriction-bypass-f5cff38d94c6

No le gusta exec, se usa un código php con system()

Tenemos acceso!

escalamos a dave (sudo -l)

sudo -l de dave

sudo nginx -h
Añadimos a /var/www/html el directorio nginx en el que alojaremos nuestra reverse shell para intentar escalar a root (ya que nginx se ejecuta con root), dentro metemos un index.php malicioso con una reverse shell

Cambiamos la configuracion de nginx

Capturas

Tenemos acceso a nginx desde fuera (no hay curl dentro de la máquina), intentamos activar php para conseguir pasarnos una reverse shell, pero no nos es posible. Otra forma, es cambiar el root (directorio raíz donde se ejecutará nginx), al cambiarlo por ejemplo a /home/dave, podemos visualizar el contenido de los archivos

imagen

Por lo que podemos intentar ver la flag de root posicionando el directorio root en /root, pero parece ser que así no se llama el archivo. Podríamos fuzzear el directorio entero, buscando archivos que nos sean utiles, pero antes de eso, podemos probar a ver si tiene claves privadas con el nombre por defecto

Tenemos el id_rsa de root! Probamos a entrar con él pero, nos pide una passphrase y no es "". Debido a que las passphrase se encuentran dentro de la id_rsa, se puede sacar pero no parece estar en ninguna wordlist

Vamos a realizar un fuzzing en la pagina para ver si conseuimos sacar algún archivo que nos de una pista.

dirb http://192.168.1.56:1234

Debido al intento de ejecutar php, el fuzzeo recoge varios archivos php con errores, asiqeu vamos a quitar la location de php de la configuracion.

Podemos hacer uno más rápido de forma interna en la máquina con el usuairo dave, con find / -name "*pass*" 2>/dev/null y encontramos un archivo pass.php dentro de /var/www/html/pluck/data/settings/, probamos las credenciales y lo tenemos!

Buscamos la flag y la encontramos en el directorio de root :)


******
sudo nginx -s quit
sudo nginx -c /home/dave/newConfigNginx

