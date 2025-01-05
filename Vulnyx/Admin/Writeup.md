# Writeup - ADMIN - VULNYX #

![image](https://github.com/user-attachments/assets/2f01f603-331f-49e7-a0e6-bbf14fb770a9)
<!--
### Recon/Scanning network ###

Realizamos un escaneo de la red para identificar las posibles ips
```shell
Netdiscover -> 192.168.1.58
```

Encontramos una ip con la que poder empezar a escanear por puertos abiertos -> 192.168.1.58

```shell
nmap -p- --open --min-rate 5000 -sS -n -Pn 192.168.1.58 -oN firstNmap.txt

#Nos reconoce los siguientes puertos:

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
```
Realizamos un segundo escanéo ahora más focalizado en los puertos recogidos en el que analizaremos los posibles servicios que se hospedan en cada uno de los puertos:
```shell
nmap -p 80,135,139,445,49665,49666,49667,49669,49670 -sVC 192.168.1.58 -oN secondNmap.txt

PORT      STATE SERVICE       VERSION
80/tcp    open  http          Microsoft IIS httpd 10.0
|_http-title: IIS Windows
|_http-server-header: Microsoft-IIS/10.0
| http-methods: 
|_  Potentially risky methods: TRACE
135/tcp   open  msrpc         Microsoft Windows RPC
139/tcp   open  netbios-ssn   Microsoft Windows netbios-ssn
445/tcp   open  microsoft-ds?
49665/tcp open  msrpc         Microsoft Windows RPC
49666/tcp open  msrpc         Microsoft Windows RPC
49667/tcp open  msrpc         Microsoft Windows RPC
49669/tcp open  msrpc         Microsoft Windows RPC
49670/tcp open  msrpc         Microsoft Windows RPC
MAC Address: 08:00:27:72:8D:13 (Oracle VirtualBox virtual NIC)
Service Info: OS: Windows; CPE: cpe:/o:microsoft:windows

Host script results:
| smb2-time: 
|   date: 2024-12-30T11:10:02
|_  start_date: N/A
|_nbstat: NetBIOS name: ADMIN, NetBIOS user: <unknown>, NetBIOS MAC: 08:00:27:72:8d:13 (Oracle VirtualBox virtual NIC)
|_clock-skew: -1s
| smb2-security-mode: 
|   3:1:1: 
|_    Message signing enabled but not required
```
Vemos diferentes servicios con posibilidad de acceder y vulnerar: SMB y HTTP
###Enumeration
Realizamos un reconocimiento de directorios dentro del servicio web con dirb para identificar los directorios disponibles dentro del servicio web:
```shell
dirb http://191.168.1.58 /usr/share/dirb/wordlist/big.txt
```
Vemos que existe un archivo "/tasks.txt" por lo que lo revisamos y encontramos algo interesante

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/Admin/task_web.png>

### Exploitation ###

Tenemos un posible usuario "hope". Ahora intentaremos enumerar o acceder mediante SMB con dicho usuario sin credenciales pero no conseguimos enumerar ni usuarios ni shares, solo conseguimos el domain (admin). Con el usuario por defecto de SMB, "guest" tampoco es posible realizar nada sin credenciales. El único paso a seguir es realizar un ataque de fuerza bruta sobre dicho usuario en SMB (rezamos por que no se bloquee el usuario).
```shell
nxc smb 192.168.1.58 -u "hope" -p /usr/share/wordlists/rockyou.txt --ignore-pw-decoding
```
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/Admin/pass_user.png>

Tenemos las credenciales de nuestro compi y podemos listar los compartidos

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/Admin/shares.png>

Vemos que tenemos permisos de lectura en IPC$, pero no al entrar no encontramos nada dentro ni podemos subir ningún archivo.

RDP no está activo y parece ser que no vemos nada más que podamos hacer para conseguir entrar al servidor. Otra forma es a partir de winrm que está en el puerto 5985 (HTTP) o 5986 (HTTPS), aunque en el primer paso del escaneo por nmap no lo hemos visto, observamos que realizando otro chequeo más exhaustivo sobre todo el parque de puertos sí lo reconoce.
```shell
nmap -p- -sVC 192.168.1.19 -oN
```
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/Admin/recheck_nmap.png>

Siempre que veamos un windows, hay que asegurarse de que no se nos queda WINRM sin escanear exhaustivamente. Comprobamos si el usuario tiene permisos para acceder de forma remota con WINRM:
```shell
evil-winrm -i 192.168.1.58 -u hope -p loser
```
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/Admin/winrm_hope.png>

Con una pequeña búsqueda encontramos la flag del usuario

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/Admin/user_flag.png>

### Privilege escalation ###

Una vez dentro, buscamos posibles escalados con windows: 

En C:\inetpub\wwwroot es dónde se aloja el servicio http IIS pero no encontramos nada interesante

Buscamos posibles variables de entorno que nos den alguna informacion, ficheros en el home del usuario, intentar entrar al directorio del usuario administrator pero nada parece ser la clave.

POdemos ver si por algún casual en el historial de powershell tiene algo interesante, su directorio suele ser:
C:/Users/User/AppData\Roaming\Microsoft\Windows\PowerShell y ahí dentro se guardan posibles archivos interesantes, vemos que hay un directorio psreadline con un archivo consolehost_history.txt, y dentro voila!, una posible pass de administrator. Se puede encontrar con una búsqueda sencilla:
```shell
ls $env:userprofile -filter "*powershell*" -recurse -force
```
<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/Admin/administrator_creds.png>

Probamos a acceder nuevamente con WINRM pero ahora con el usuario administrator y las credenciales que acabamos de recoger:

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/Admin/administrator_login.png>

Estamos dentro!! Con una búsqueda rápida, encontramos la flag de administrator.

<img src=https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/Admin/admin_flag.png>

## PLUS ##
Debido a que primeramente había intentado la fuerza bruta con hydra pero no funcionó  y no conocía la herramienta nxc con sus opciones de smb, construí un script propio en bash para realizar la conexión mediante SMB.

### smbBruteUsersNoPass.sh

[smbBruteUsersNoPass.sh](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/smbBruteUsersNoPass.sh)

Uso: ./smbBrute.sh \<//IP/\> \<list users\> \<processes\>(optional: 2 default)

Script en bash el cuál consise en realizar fuerza bruta sobre la lista de usuarios que se pase como segundo parámetro a la función con crecenciales nulas (esto con enum4linux también se podría hacer). 

### smbBrutePass.sh

[smbBrutePass.sh](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/smbBrutePass.sh)

Uso: ./smbBrute.sh \<//IP/\> \<wordlist\> \<user\> \<processes\>(optional: 2 default)

Mismo script que el anterior pero la lista en este caso debe ser una wordlist de posibles contraseñas que ejecuta al usuario pasado como tercer argumento.
### Multiprocesos y bash
Los dos scripts se basan en la división de la lista pasada por parámetro en diferentes ejecuciones en background (diferentes procesos) para una eficiencia mayor que si simplemente fuese un código secuencial, usando un solo proceso. Por desgracia en bash no existe forma de utilizar "hilos" (al menos no la he encontrado yo) por lo que la opción es realizar un script multiproceso. Esto en un lenguaje como Java, C, C++ o Python, se podrían utilizar hilos y hacer el script mucho más eficiente. Obviamente la forma óptima de hacer esto es usar las herramientas existentes y apoyadas por la comunidad. En anteriores writeups hicimos algo parecido pero de forma secuencial y se me quedó pendiente poder implementar una solución más eficiente con el uso de multiprocesos/multihilos en bash, lo cuál nunca había hecho en bash y tenía curiosidad, ya que en otros lenguajes sí he trabajado con esta opción (multiprocesos en C con una metodología de padre/hijos y en Java con los hilos, mediante el uso de semáforos), pero en bash nunca había planteado la opción de implementar algo parecido.

En bash la forma de conseguir un script multiproceso es a través de las ejecuciones en segundo plano. Habrán tantos procesos como ejecuciones en segundo plano.
```shell
#Creamos tantas ejecuciones en background como procesos necesitamos
for i in $(seq 5)
do
  echo "Process: $i"
  #Creacion del proceso
  script.sh $i &
done
#Esperamos a que los procesos hijos (segundo plano) terminen para cerrar el programa
wait
```
Al ser multiproceso, hay que tener en cuenta las condiciones de carrera que se pueden producir cuando dos o más procesos utilizan algún dato compartido. En el caso de nuestros scripts, al no modificar posibles datos compartidos no nos preocupamos pero se dividen las listas de forma equitativa (aprox) para que ninguno de los procesos se pise o utilice un usuario/pass que vaya a usar otro proceso o ya haya utilizado. Si son 5 como en el ejemplo, las listas se dividen en 5 partes, una para que la use cada uno de los procesos.

### Importante

Añadir que hay que tener cuidado en este tipo de acciones (fuerza bruta) ya que con la ejecución de mis scripts, bloquee varias veces al usuario, teniendo que reestablecer la máquina.
-->
