¡Absolutamente! Permítame adoptar mi rol de experto en pentesting y documentación. He analizado con detalle los datos proporcionados sobre el laboratorio "VulNyx". A continuación, presento un informe estructurado y profesional que detalla cada fase de la evaluación de seguridad, desde el reconocimiento inicial hasta la escalada de privilegios a nivel de \`root\`, incluyendo hallazgos, metodologías y evidencia crucial. Este informe ha sido diseñado siguiendo las mejores prácticas de documentación en ciberseguridad, asegurando claridad, reproducibilidad y un enfoque metódico de los hallazgos. --- \`\`\`html <!DOCTYPE html>

# Informe de Evaluación de Seguridad - Laboratorio VulNyx

Este documento detalla la metodología, los hallazgos y las vulnerabilidades identificadas durante una evaluación de seguridad sobre el entorno del laboratorio VulNyx. El objetivo principal fue identificar y explotar debilidades que permitieran obtener acceso no autorizado y escalar privilegios hasta el nivel de `root`.

Los datos originales proporcionados han sido analizados y estructurados para presentar un informe claro y conciso, siguiendo las fases estándar de un pentest.

---

## 1\. Reconocimiento y Escaneo de Red

La fase inicial de reconocimiento se centró en la identificación del objetivo dentro de la red local. Se empleó la herramienta `netdiscover` para mapear la red y localizar la dirección IP de la máquina a atacar.

```
netdiscover -r 192.168.1.0/24
```

Tras la identificación de la IP **192.168.1.56** como objetivo, se procedió con un escaneo preliminar de puertos utilizando `nmap`. Este escaneo rápido y de amplio espectro (\`-p-\` para todos los puertos, \`--open\` para solo puertos abiertos, \`--min-rate 5000\` para velocidad, \`-sS\` para SYN scan, \`-n -Pn\` para no resolver DNS y no hacer ping, y \`-oN\` para guardar la salida) permitió identificar servicios en ejecución de manera eficiente.

```
nmap -p- --open --min-rate 5000 -sS -n -Pn 192.168.1.56 -oN firstNmap.txt
```

Los resultados del escaneo inicial revelaron la presencia de dos servicios clave:

```
	Port	State	Service		TTl
	22/tcp 	open  	ssh     	syn-ack ttl 64
	80/tcp 	open  	http    	syn-ack ttl 64

```

Con estos servicios identificados (SSH en el puerto 22 y HTTP en el puerto 80), se realizó un escaneo más exhaustivo para determinar las versiones de los servicios y obtener información adicional. Este paso es crucial para identificar posibles vulnerabilidades conocidas asociadas a versiones específicas de software.

```
nmap -p 22,80 -sVC 192.168.1.56 -oN secondNmap.txt
```

## 2\. Enumeración de Servicios Web

Mientras se ejecutaba el escaneo detallado de `nmap`, se procedió con la enumeración de directorios del servidor web en el puerto 80 utilizando la herramienta `dirb`. Esto nos permitió descubrir recursos ocultos o menos obvios.

```
dirb http://192.168.1.56 /usr/share/wordlists/big.txt -o dirb.txt
```

Durante la enumeración, se descubrió el directorio `/pluck`, el cual albergaba una aplicación web. La exploración de esta aplicación reveló una página de login. La captura de pantalla a continuación muestra la interfaz de la aplicación Pluck:

[ ![Página principal de la aplicación Pluck](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/pluck_web.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/pluck%5Fweb.png) 

Se identificó una interfaz de login en `/pluck/admin`, la cual es un punto de entrada potencial para la explotación:

[ ![Página de Login de Pluck](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/pluck_login.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/pluck%5Flogin.png) 

Se probó con credenciales por defecto comunes, como `admin:admin`. Sorprendentemente, estas credenciales fueron exitosas, otorgándonos acceso al panel de administración de la aplicación Pluck.

[ ![Panel de administración de Pluck tras login exitoso](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/admin_logued.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/admin%5Flogued.png) 

## 3\. Explotación Inicial

Dentro del panel de administración, se revisaron las diferentes opciones disponibles. Una de las funciones que llamó la atención fue la capacidad de "Subir Módulos" (Upload Modules) en la sección de módulos. Esto representa una vía potencial para la inyección de código si la validación de archivos es insuficiente.

[ ![Opción de Subir Módulos en Pluck](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/uploadModules.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/uploadModules.png) 

Se intentó subir un archivo de _reverse shell_ en PHP, sin éxito. La aplicación impone restricciones en el tipo de archivos que pueden subirse para módulos (presumiblemente esperando formatos específicos de Nginx o Pluck), lo que resultó en un error.

[ ![Error al subir shell PHP como módulo](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/errorUploading_shellphp.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/errorUploading%5Fshellphp.png) 

Posteriormente, se investigaron otros directorios y se descubrió una sección de subida de ficheros más genérica. En esta sección, aunque se permitió la subida de un archivo PHP, el servidor automáticamente le añadió la extensión `.txt` (ej., `shell.php.txt`), impidiendo su ejecución como código PHP. Esto indica una posible lista negra o filtro basado en la extensión.

[ ![Visualización de archivo subido con extensión .txt añadida](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/rfi.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/rfi.png) 

Para evadir esta restricción, se realizó una prueba de extensiones alternativas (probado manualmente o mediante un fuzzer/Burp Suite). Se descubrió que la extensión `.phar` no era censurada y permitía la subida de archivos PHP con su funcionalidad de ejecución intacta. Se subió una _reverse shell_ PHP (inicialmente con `exec()`, luego modificada a `system()` debido a problemas de ejecución) con la extensión `.phar`. La siguiente captura muestra la ejecución exitosa de `whoami` a través de la shell remota.

[ ![Ejecución de whoami a través de shell remota .phar](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/rce_whoami.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/rce%5Fwhoami.png) 

Finalmente, se configuró un _listener_ en la máquina atacante en el puerto especificado en la _reverse shell_ y se activó la ejecución del archivo `.phar`. Esto resultó en la obtención de una shell remota en el sistema objetivo bajo el usuario `www-data`.

[ ![Obtención de shell remota como www-data](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/remoteShell%5Fexecuted.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/remoteShell%5Fexecuted.png) 

## 4\. Escalada de Privilegios

### 4.1\. Escalada a usuario 'dave'

Una vez obtenida la shell como `www-data`, el siguiente paso fue la escalada de privilegios. Se comenzó por inspeccionar los permisos `sudo` del usuario actual.

[ ![Salida de sudo -l como www-data](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/sudo-l.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/sudo-l.png) 

El comando `sudo -l` reveló que el usuario `www-data` tenía permisos para ejecutar el comando `sudo -u dave bash`. Esto permitió una escalada directa al usuario `dave` sin necesidad de contraseña.

```
sudo -u dave bash
```

[ ![Escalada a usuario dave exitosa](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/dave_escalated.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/dave%5Fescalated.png) 

Con el acceso como `dave`, se pudo localizar y recuperar la primera _flag_ del laboratorio.

[ ![User flag obtenida](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/user_flag.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/user%5Fflag.png) 

### 4.2\. Escalada a 'root'

Con acceso como `dave`, se volvió a verificar los permisos `sudo` para identificar vías hacia el usuario `root`. Se encontró que `dave` podía ejecutar el servicio `nginx` como `root` sin necesidad de contraseña.

[ ![Página de manual de Nginx](https://github.Xcom/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/nginx_man.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/nginx%5Fman.png) 

Se consultó el manual de `nginx` para comprender sus opciones de configuración. Se observó que la flag `-c` permite cargar un archivo de configuración personalizado y `-T` permite probar y mostrar la configuración. Esto es clave, ya que podemos manipular el comportamiento de Nginx.

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

La estrategia inicial fue modificar la configuración de Nginx para que el servicio se ejecutara como `root` y permitiera la visualización de archivos del sistema a través del servidor web. Se detuvo el servicio Nginx existente y se recargó con una configuración personalizada (ej. `/home/dave/newConfigNginx`).

```
sudo nginx -s quit
sudo nginx -c /home/dave/newConfigNginx
```

La primera aproximación fue intentar habilitar PHP para Nginx bajo el usuario `root` para ejecutar código, pero no fue exitoso. En su lugar, se optó por una estrategia de lectura de archivos. Al modificar el parámetro `root` en la configuración de Nginx (ej. a `/` o `/root`), se podría exponer directorios sensibles a través del servidor web.

[ ![Visualización remota de Nginx con configuración personalizada](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/visualizacionRemota_nginx1.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/visualizacionRemota%5Fnginx1.png) 

Se modificó el archivo de configuración de Nginx para cambiar su directorio raíz (`root`) a `/root`. Esto permitió al servidor web servir archivos desde el directorio de `root`. Con esta configuración, se pudo acceder y visualizar archivos sensibles del sistema, como `.bashrc` del usuario `root`, a través de una petición HTTP.

[ ![Visualización de .bashrc de root a través de Nginx](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/seeing_bashrc_root_nginx.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/seeing%5Fbashrc%5Froot%5Fnginx.png) 

La configuración modificada de Nginx era similar a esta (con `root /root;`):

[ ![Nueva configuración de Nginx apuntando a /root](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/newNginx_conf.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/newNginx%5Fconf.png) 

Con la capacidad de leer archivos del directorio `/root` de forma remota, se buscó la clave SSH privada del usuario `root` (`id_rsa`), un objetivo común para la escalada de privilegios. Esta clave fue encontrada y recuperada.

[ ![Clave privada id_rsa de root encontrada](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/id_rsa_root.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/id%5Frsa%5Froot.png) 

Al intentar utilizar la clave `id_rsa` para acceder vía SSH como `root`, se solicitó una _passphrase_. La clave no estaba protegida por una _passphrase_ vacía, lo que impedía el acceso directo.

[ ![Error de passphrase al intentar SSH con id_rsa](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/passphrase_wrong.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/passphrase%5Fwrong.png) 

Aunque se intentó un ataque de fuerza bruta/diccionario sobre la _passphrase_ usando `ssh2john` y `john the ripper`, no se obtuvo éxito con las _wordlists_ estándar. Por lo tanto, se cambió el enfoque y se buscó la _passphrase_ directamente en el sistema de archivos del objetivo.

Se utilizó el comando `find` para buscar archivos que pudieran contener la palabra "pass", redirigiendo el error a `/dev/null` para una salida limpia.

```
find / -name "*pass*" 2>/dev/null
```

Esta búsqueda reveló un archivo llamado `pass.php` dentro del directorio `/var/www/html/pluck/data/settings/pas.php`. Este archivo contenía una posible credencial, que no fue descubierta previamente por `dirb` debido a restricciones de acceso o a que no estaba en las _wordlists_ típicas para esa profundidad de directorios.

[ ![Credenciales potenciales encontradas en pass.php](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/root_credsPosible.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/root%5FcredsPosible.png) 

Al utilizar la cadena de texto encontrada en `pass.php` como _passphrase_ para la clave SSH, se logró establecer una conexión SSH exitosa como el usuario `root`, obteniendo así el control total del sistema.

[ ![Acceso root obtenido vía SSH](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/root_shell.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/root%5Fshell.png) 

Finalmente, se localizó y recuperó la _flag_ de `root`, confirmando la completa escalada de privilegios.

[ ![Root flag obtenida](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Code/Content/root_flag.png) ](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Code/Content/root%5Fflag.png) 

---

## Conclusiones y Recomendaciones

Esta evaluación del laboratorio VulNyx ha demostrado una cadena de vulnerabilidades que, cuando se encadenan, permiten a un atacante obtener acceso completo al sistema.

### Hallazgos Clave:

* **Credenciales Débiles por Defecto:** La aplicación Pluck utilizaba credenciales por defecto (admin:admin), un punto de entrada trivial para cualquier atacante.
* **Falta de Validaciones Robustas en la Subida de Archivos:** Aunque existían filtros de extensiones, estos pudieron ser eludidos con extensiones menos comunes (como `.phar`), llevando a una Ejecución Remota de Código (RCE).
* **Configuración Insegura de Sudo:** El usuario `www-data` tenía permisos para escalar a `dave` sin contraseña, y `dave` tenía permisos para ejecutar Nginx como `root`, lo cual es una grave debilidad.
* **Exposición de Información Sensible:** La manipulación de la configuración de Nginx permitió la lectura de archivos del directorio `/root`, exponiendo la clave privada SSH de `root`.
* **Gestión de Credenciales Insegura:** La _passphrase_ de la clave SSH de `root` se encontraba almacenada en un archivo de configuración web accesible, lo que demuestra una práctica deficiente de seguridad de credenciales.

### Recomendaciones:

1. **Forzar Cambio de Credenciales por Defecto:** Asegurar que las aplicaciones web no utilicen credenciales por defecto o forzar el cambio de las mismas en el primer inicio.
2. **Implementar Whitelists de Extensiones:** En lugar de listas negras, implementar listas blancas estrictas para los tipos de archivo permitidos en las funciones de subida. Además, realizar validaciones de tipo de contenido MIME y un saneamiento de los nombres de archivo.
3. **Revisar y Restringir Permisos de Sudo:** Aplicar el principio de mínimo privilegio. Los usuarios no deben tener permisos de `sudo` para ejecutar servicios como `root` si no es estrictamente necesario, y cualquier permiso concedido debe ser granular.
4. **Configuración Segura de Servidores Web:** Nginx y otros servidores web deben configurarse con la seguridad en mente, evitando la exposición de directorios del sistema de archivos y ejecutándose con el menor privilegio posible.
5. **Protección Robusta de Claves SSH:** Las claves SSH privadas no deben almacenarse en el sistema de archivos de forma que puedan ser leídas por usuarios de menor privilegio. Las _passphrases_ deben ser robustas y no almacenarse en texto plano ni en ubicaciones predecibles.
6. **Monitorización y Auditoría:** Implementar soluciones de monitorización para detectar actividades inusuales o accesos no autorizados.

La implementación de estas recomendaciones es crucial para mitigar riesgos y fortalecer la postura de seguridad de cualquier sistema.

Agradezco la oportunidad de llevar a cabo esta evaluación. Quedo a su disposición para cualquier aclaración o discusión adicional.

\`\`\`