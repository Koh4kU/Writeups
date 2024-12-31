Writeup


Netdiscover -> 192.168.1.58

first nmap->
PORT      STATE SERVICE      REASON                                                          
80/tcp    open  http         syn-ack ttl 128                                                 
135/tcp   open  msrpc        syn-ack ttl 128                                                 
139/tcp   open  netbios-ssn  syn-ack ttl 128                                                 
445/tcp   open  microsoft-ds syn-ack ttl 128                                                 
49665/tcp open  unknown      syn-ack ttl 128                                                 
49666/tcp open  unknown      syn-ack ttl 128                                                 
49667/tcp open  unknown      syn-ack ttl 128                                                 
49669/tcp open  unknown      syn-ack ttl 128                                                 
49670/tcp open  unknown      syn-ack ttl 128

second nmap -> nmap -p 80,135,139,445,49665,49666,49667,49669,49670 -sVC 192.168.1.58 -oN secondNmap.txt

dirb -> sin resultados

Dejare de usar dirbuster para empezar a usar gobuster
gobuster dir -u 192.168.1.58 -w /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt

En tasks.txt tenemos un usuario hope

Vamos a por SMB: pero no conseguimos enumerar ni usuarios ni shares, solo conseguimos el domain (admin), pero ahora podemos hacer otro dirb sobre este nuevo dominio, sin resultados

Con este usuario, con una fuerza bruta conseguimos comprometerlo (sin password no se entraba a smb)

Hydra no sirve pero nxc sí:
nxc smb 192.168.1.58 -u "hope" -p /usr/share/wordlists/rockyou.txt --ignore-pw-decoding

Tenemos las credenciales de nuestro compi y podemos listar los compartidos

Vemos que tenemos permisos de lectura en IPC$, pero no encontramos nada dentro

revisamos si es vulnerable a winrm

nxc winrm 192.168.1.19 -u hope -p loser

Sí, probamos a obtener una shell con evil-winrm y la obtenemos

winrm está en el puerto 5985 (HTTP) o 5986 (HTTPS), aunque en el primer paso del escaneo por nmap no lo hemos visto, observamos que realizando otro chequeo más exhaustivo sobre todo el parque de puertos sí lo pilla
nmap -p- -sVC 192.168.1.19

Con una pequeña búsqueda encontramos la flag del usuario

Una vez dentro, buscamos posibles escalados con windows

En C:\inetpub\wwwroot es dónde se aloja el servicio http IIS pero no encontramos nada interesante

Buscamos posibles variables de entorno que nos den alguna informacion, ficheros en el home del usuario, intentar entrar al directorio del usuario administrator pero nada parece ser la clave.

POdemos ver si por algún casual en el historial de powershell tiene algo interesante, su directorio suele ser:
C:/Users/User/AppData\Roaming\Microsoft\Windows\PowerShell y ahí dentro se guardan posibles archivos interesantes, vemos que hay un directorio psreadline con un archivo consolehost_history.txt, y dentro voila!, una posible pass de administrator 

se puede encontrar con una búsqueda sencilla:
ls $env:userprofile -filter "*powershell*" -recurse -force

Con una búsqueda rápida, encontramos la flag de administrator

PLUS
Debido a que no se podía con hydra, construí uno propio, cuidado con el bloqueo del usuario EXPLICAR EN GITHUB LOS DOS SCRIPTS

