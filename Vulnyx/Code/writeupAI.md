\`\`\`html <!DOCTYPE html>

**Saludos.** Como experto en pentesting y documentación de seguridad, he revisado minuciosamente el conjunto de datos proporcionado correspondiente al writeup de la máquina **VulNyx**. Mi tarea es transformar esta valiosa información técnica en un informe HTML estructurado, claro y profesional, que no solo cumpla con los estándares de documentación, sino que también facilite su comprensión y análisis.

Este informe detalla de manera exhaustiva el proceso de evaluación de seguridad, desde la fase inicial de reconocimiento de red hasta la escalada de privilegios a `root`. Cada paso, cada hallazgo y cada técnica de explotación se presentan con la evidencia correspondiente, reflejando una metodología sólida y un análisis profundo.

Es importante señalar que algunas de las URL de las imágenes adjuntas parecen ser enlaces temporales o privados de GitHub. Aunque las he incluido tal como se han recibido en el formato adecuado para su visualización, la accesibilidad de estas podría depender de la sesión o de la caducidad de los tokens JWT incrustados. Si experimenta dificultades para ver alguna imagen, le recomiendo verificar la accesibilidad de la fuente original.

A continuación, se presenta la documentación técnica formateada, lista para su consulta y uso:

# \# Writeup - Code - VulNyx

[![Imagen de cabecera del writeup](https://private-user-images.githubusercontent.com/82893511/400529265-f4c31131-c4b4-42a7-ac42-613559503b7d.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTY3NTU3OTEsIm5iZiI6MTc1Njc1NTQ5MSwicGF0aCI6Ii84Mjg5MzUxMS80MDA1MjkyNjUtZjRjMzExMzEtYzRiNC00MmE3LWFjNDItNjEzNTU5NTAzYjdkLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTA5MDElMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwOTAxVDE5MzgxMVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWFkZjJiNTc0YjFiYWJlNTc0ZmY3NzFiYTMxNTQ1YTJhM2IzMWJhNTYzMjZhYTZiOGM5ZjM2OTljZTU4MDdjODgmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.LbTwMLgJLonoAGdj2O6kmHcBFAhShh6BX-AFUJu2cho)](https://private-user-images.githubusercontent.com/82893511/400529265-f4c31131-c4b4-42a7-ac42-613559503b7d.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTY3NTU3OTEsIm5iZiI6MTc1Njc1NTQ5MSwicGF0aCI6Ii84Mjg5MzUxMS80MDA1MjkyNjUtZjRjMzExMzEtYzRiNC00MmE3LWFjNDItNjEzNTU5NTAzYjdkLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTA5MDElMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwOTAxVDE5MzgxMVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWFkZjJiNTc0YjFiYWJlNTc0ZmY3NzFiYTMxNTQ1YTJhM2IzMWJhNTYzMjZhYTZiOGM5ZjM2OTljZTU4MDdjODgmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.LbTwMLgJLonoAGdj2O6kmHcBFAhShh6BX-AFUJu2cho)

## Scanning network

El primer paso fue identificar el objetivo dentro de la red local. Para ello, se empleó `netdiscover`, resultando en la identificación de la IP objetivo: `192.168.1.56`.

```
netdiscover -r 192.168.1.0/24
```

Posteriormente, se realizó un escaneo inicial de puertos con `nmap` para detectar servicios abiertos de manera rápida.

```
nmap -p- --open --min-rate 5000 -sS -n -Pn 192.168.1.56 -oN firstNmap.txt
```

Los resultados revelaron dos puertos interesantes:

```
	Port	State	Service		TTl
	22/tcp 	open  	ssh     	syn-ack ttl 64
	80/tcp 	open  	http    	syn-ack ttl 64
```

Con estos puertos identificados (SSH y HTTP), se procedió a un escaneo más detallado para obtener información sobre las versiones de los servicios y configuraciones.

```
nmap -p 22,80 -sVC 192.168.1.56 -oN secondNmap.txt
```

## Enumeration

Paralelamente al escaneo de versiones, se inició una enumeración de directorios web en el puerto 80 utilizando `dirb` para descubrir rutas ocultas o no enlazadas.

```
dirb http://192.168.1.56 /usr/share/wordlists/big.txt -o dirb.txt
```

El escaneo reveló la existencia del directorio `/pluck`, el cual albergaba una aplicación web.

[![Vista de la aplicación web Pluck en /pluck](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/pluck_web.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/pluck%5Fweb.png)

Dentro de la estructura de `/pluck`, se encontró un panel de inicio de sesión.

[![Página de login de la aplicación Pluck](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/pluck_login.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/pluck%5Flogin.png)

Se intentaron credenciales por defecto, siendo `admin:admin` exitosas, otorgando acceso al panel de administración.

[![Panel de administración de Pluck tras el login](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/admin_logued.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/admin%5Flogued.png)

## Exploitation

Dentro del panel de administración de Pluck, se exploraron las diversas funcionalidades. Se identificó una opción para "subir módulos", que requería módulos específicos de Nginx.

[![Opción para subir módulos en el panel de Pluck](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/uploadModules.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/uploadModules.png)

Intentos de subir una reverse shell PHP a través de esta funcionalidad fallaron, generando un error.

[![Error al intentar subir una shell PHP](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/errorUploading_shellphp.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/errorUploading%5Fshellphp.png)

Se continuó la búsqueda de otras funcionalidades de subida de archivos y se encontró un directorio específico para ello. Al intentar subir una reverse shell PHP, se observó que el servidor automáticamente añadía la extensión `.txt` al archivo, impidiendo su ejecución como código PHP.

[![Archivos subidos, con .php renombrado a .txt](https://github.kohaku/Writeups/raw/main/Vulnyx/Code/Content/rfi.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/rfi.png)

Este comportamiento sugería una lista negra de extensiones. Se probó con diferentes extensiones de PHP y finalmente la extensión **`.phar`** eludió la validación del servidor y permitió la subida de la shell. Inicialmente, la shell contenía `exec()`, pero se modificó a `system()` para asegurar su funcionamiento.

[![Demostración de RCE con 'whoami' a través de shell PHAR](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/rce_whoami.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/rce%5Fwhoami.png)

Con la shell cargada, se configuró un listener en la máquina atacante y se ejecutó la reverse shell desde el navegador, obteniendo acceso exitoso.

[![Reverse shell obtenida y ejecutada](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/remoteShell_executed.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/remoteShell%5Fexecuted.png)

¡Acceso inicial al sistema logrado como usuario `www-data`!

## Privilege escalation

Una vez dentro como `www-data`, el objetivo era escalar privilegios. Se verificaron los permisos `sudo` del usuario actual.

[![Listado de permisos sudo para www-data](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/sudo-l.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/sudo-l.png)

Se descubrió que `www-data` podía ejecutar comandos como el usuario `dave` sin contraseña. Esto permitió una escalada horizontal de privilegios.

```
sudo -u dave bash
```

[![Acceso como usuario Dave](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/dave_escalated.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/dave%5Fescalated.png)

Con el usuario `dave`, se pudo recuperar la primera flag del laboratorio.

[![Flag de usuario (user.txt) encontrada](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/user_flag.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/user%5Fflag.png)

### Escalada a Root

El siguiente paso fue la escalada a `root`. Al revisar los permisos `sudo` de `dave`, se encontró que tenía la capacidad de ejecutar Nginx como `root` sin requerir contraseña. Esto presentaba un vector de ataque directo.

[![Manual de Nginx](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/nginx_man.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/nginx%5Fman.png)

El manual de Nginx reveló que la flag `-c` permite especificar un archivo de configuración alternativo y la flag `-T` permite probar la configuración. Se examinó la configuración predeterminada de Nginx para entender su estructura.

```
user root;
server {
   listen [::]:65000 default_server;

   server_name _;

   root /var/www/html;
   index index.html index.htm index.nginx-debian-html;

   location / {
           try_files $uri $uri/ =404;
   }
}
```

Se decidió manipular la configuración de Nginx. Primero, se detuvo el servicio existente y se reinició con un archivo de configuración modificado, ubicado en `/home/dave/newConfigNginx`.

```
sudo nginx -s quit
sudo nginx -c /home/dave/newConfigNginx
```

La estrategia inicial de activar PHP como `root` no tuvo éxito. Por ello, se modificó el `root` del servidor Nginx para apuntar a `/root`, con la intención de visualizar archivos del directorio `root`.

[![Modificación de la configuración de Nginx para visualización remota](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/visualizacionRemota_nginx1.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/visualizacionRemota%5Fnginx1.png)

Con esta configuración, se logró visualizar archivos locales, como el `.bashrc` de `root`, a través del servidor web.

[![Visualización del .bashrc de root a través de Nginx](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/seeing_bashrc_root_nginx.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/seeing%5Fbashrc%5Froot%5Fnginx.png)

Se modificó nuevamente la configuración para que el `root` del servidor Nginx fuera directamente `/root`.

[![Nueva configuración de Nginx apuntando a /root](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/newNginx_conf.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/newNginx%5Fconf.png)

Aunque la enumeración directa de la flag `root.txt` no fue posible, se optó por buscar la clave SSH privada de `root` (`id_rsa`), asumiendo que el login de `root` por SSH no estaba deshabilitado.

[![id_rsa de root encontrada a través de Nginx](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/id_rsa_root.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/id%5Frsa%5Froot.png)

Se obtuvo la clave privada `id_rsa` de `root`. Al intentar conectarse por SSH con esta clave, se solicitó una passphrase. Los intentos de fuerza bruta/diccionario con `ssh2john` y `john the ripper` no fueron fructíferos.

[![Error de passphrase al intentar acceder con SSH](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/passphrase_wrong.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/passphrase%5Fwrong.png)

Ante la imposibilidad de crackear la passphrase, se realizó una búsqueda de archivos que pudieran contenerla dentro del sistema comprometido.

```
find / -name "*pass*" 2>/dev/null
```

Esta búsqueda reveló un archivo `"pass.php"` en la ruta `"/var/www/html/pluck/data/settings/pas.php"`. Este archivo no se había detectado en el `dirb` inicial debido a la falta de permisos y a que no se realizó una enumeración recursiva tras obtener las credenciales de administrador de Pluck.

[![Contenido de pass.php con posibles credenciales de root](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/root_credsPosible.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/root%5FcredsPosible.png)

La información en `pass.php` contenía la passphrase de `root`. Al introducirla en el prompt de SSH, se obtuvo acceso completo al sistema como `root`.

[![Shell de root obtenida vía SSH](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/root_shell.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/root%5Fshell.png)

Finalmente, se localizó la flag de `root`, completando el proceso de pentesting.

[![Flag de root (root.txt) encontrada](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/root_flag.png)](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/root%5Fflag.png)

\`\`\`