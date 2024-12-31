netdiscover de siempre, encontramos la ip 192.168.1.105

firstnmap -> nmap -p- --open -sS --min-rate 5000 -n -Pn 192.168.1.105

secondnmap -> nmap -p 21,22,80,9090 -sVC 192.168.1.105

**Revisar el fichero de nmap para explicar mejor en el writeup**
21 -> ftp
22 -> ssh
80 -> http (apache index)
9090 -> https (cockpit) Explicacion en el writeup

Revisando la página, no llegamos a gran cosa con el cockpit (capturas de localhost, root, servicio cockpit)...

Probamos FTP, con el FTP sin credenciales en forma anónima, podemos descargarnos un archivo "backup.zip"

imagen curl

imagen wget

Descomprimimos el archivo

unzip backup.zip

Se nos creará un directorio mozilla en el que se habrán descomprimido los archivos. Realizando un pequeño análisis, nons encontramos con un archivo logins.json con contraseñas en él. Además, en la base de datos key4.db, obtenemos otros valores asociados a contraseñas. El directorio está plagado de archivos que nos pueden ir dando diferente información, aunque para este caso, es perder el tiempo intentando descifrar todo el contenido que no es poco.

Si conocemos un poco cómo está gestionado firefox desde linux, encontraremos el arbol de directorios y arhcivos muy parecido a lo que tiene nuestro propio firefox, entre eso y el nombre de la capeta principal "mozilla/firefox" podemos suponer que es un backup de todas las configuraciones del navegador mozilla firefox. Una vez que sabemos esto, es fácil asumir el siguiente paso, importar las contraseñas antiguas a nuestro propio navegador. Para esto con una simple búsqueda encuentras que los dos únicos archivos necesarios para esto son: key3.db (en nuestro caso key4.db) y el famoso logins.json. Si vizualizamos nuestro almacen de contraseñas, veremos que está vacio (a no ser que tengáis contraseñas guardadas aquí, que después de ver este writeup, seguro que se os quitan las ganas de guardar contraseñas en el navegador)

imagen pass firefox

imagen pass marco firefox
probamos credenciales
imagen login marco

Voila! Tenemos acceso a la consola de management de cockpit

imagen system cockpit

Intentamos entrar por ssh

imagen marco ssh

Pero está dshabilitado el uso de contraseñas para el acceso

Por lo que analizamos el sitio web y encontramos una forma de levantar una terminal interactiva

sudo -l

Observamos que tenemos permisos de utilizar units como root. Analizamos qué hace units y cómo podemos ver para escalar privilegios a root. units -h ofrece un pequeño manual de su uso, ejecutamos !/bin/bash y tenemos una shell de root


MAL CAMINO

INtentar vulnerar la web al saber que tiene cockpit, mediante el uso de peticionnes maliciosas http con burpsuite o vulnerabilidades conocidas de cockpit
