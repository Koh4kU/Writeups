Writeup


netdiscover -> 

PORT      STATE SERVICE      REASON
80/tcp    open  http         syn-ack ttl 128
135/tcp   open  msrpc        syn-ack ttl 128
139/tcp   open  netbios-ssn  syn-ack ttl 128
445/tcp   open  microsoft-ds syn-ack ttl 128
49667/tcp open  unknown      syn-ack ttl 128


Por máquinas anteriores, vemos que el smb y netbios están activos, pero no vemos un reconocimiento del puerto de WINRM, por lo que aunque no esté lo incluiremos en el segundo nmap (5985 (HTTP),5986 (HTTPS))

second nmap -> 

hay winrm! Como sospechabamos

HTTP
Hay una página, vamos a mirar mientras se realiza un gobuster. A través de gobuster encontramos una página speed (GOBUSTER no es recursivo)

usamos dirb de nuevo y nos encuentra más con la wordlist big.txt, pero nada interesante, solo páginas con acceso restringido

Revisando la página nos encontramos con unos posibles usuarios, además de un tal John Bond, por lo que añadimos todos a un archivo de posibles usuarios

Realizamos fuerza bruta sobre smb con cada usuario y nos encontramos con las credenciales de p.smith

enm4linux -a -u p.smith -p kissme 192.168.1.22 (-a no es por defecto)

sacamos nuevos usuarios, actualizamos la lista de posibles users para hacer otra fuerza bruta, cuidado con bloquear los usuarios. Tras haber bloqueado los usuarios y haber reiniciado la máquina

Probamos a entrar sin pass, no funciona

Dentro de la salida de enum4linux, nos aparece una descripción en uno de los users, probamos eso como pass en cada de uno de los usuarios hasta que vemos que el indicado es j.wilson, sabemos que jwilson tiene permisos de shell remota

imagenes jwilson


Ni history de powershell, ni txt en el servicio web con passwords, ni txt en el sistema con posibles paswords. Hemos visto anteriormente que j.wilson tenía permisos de backup, para ver cuáles exactamente introducimos

whoami /priv

Y vemos todos los permisos del usuario

Podemos hacer copias de seguridad de archivos y directorios, por lo que podemos de alguna forma extraer contenido de la máquina. En este caso, lo interesante para poder pasar a root, sería conseguir los archivos SAM (Security Account Manager) es una base de datos que almacena información de las cuentas de usuario locales, incluidos sus nombres y contraseñas (estas últimas de forma cifrada o con hashes).

Para el proposito de conseguir root.txt (flag de root) nos serviría con dumpear c:/Users/administrator/desktop/root.txt y ya, pero vamos a intentar conseguir una shell como administrator

No me ha dejado hacerlo con robocopy: robocopy C:\Windows\System32\config\SAM C:\Windows\temp /B 

Aunque chatgpt diga que no, sí se puede guardar mediante los registros:

reg save hklm\sam c:/Windows/temp/sam (cuidado con las barras al especificar el registro, deben ser invertidas)

con el comando download <archivo> nos descargamos el archivo en el directorio en el que hemos ejecutado evil-winrm

Es un archivo binario, existen diferentes formas de sacar el hash, vamos a probar varias de ellas:

samdump2 necesita sam y system, por lo que volvemos a la consola de windows y sacamos hklm\system

sudo samdump2 system.dump sam -o hashes (el orden importa, system antes de sam)

En vez de perder el tiempo intentando crackear los hashes (como yo hice), puedes entrar con evil-winrm directamente con el hash, hay que tener cuidado porque en mi caso, samdump2 y secretsdump me han dado hashes diferentes, parece que en este caso secretsdump ha conseguido realizarlo mejor por la diferencia de hashes

impacket-secretsdump -sam sam -system system.dump LOCAL > hashes2

Probamos y con el hash de samdump2 no es correcto, vemos que con el de secretsdump si


https://book.hacktricks.xyz/windows-hardening/stealing-credentials#stealing-sam-and-system

probamos otro

SMB
enum4linux no nos saca nada relevante, solo la información de nbstat

intentamos entrar con la cuenta por defecto
