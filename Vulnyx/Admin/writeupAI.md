\`\`\`html <!DOCTYPE html>

# Análisis y Documentación de Pentesting

¡Saludos! Como su experto en pentesting y documentación, he recibido su solicitud para procesar los datos de su writeup de la máquina **"ADMIN - VULNYX"** y presentarlos en un formato HTML profesional. He analizado la información proporcionada y he procedido a estructurarla y documentarla de manera clara, concisa y técnica, tal como se espera en un informe de pentesting.

A continuación, encontrará el writeup completo y detallado, que abarca las fases de reconocimiento, enumeración, explotación y escalada de privilegios en la máquina objetivo.

---

# Writeup de Pentesting: ADMIN - VULNYX

![Banner ADMIN - VULNYX](https://private-user-images.githubusercontent.com/82893511/400241816-2f01f603-331f-49e7-a0e6-bbf14fb770a9.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NTY2NTI4ODUsIm5iZiI6MTc1NjY1MjU4NSwicGF0aCI6Ii84Mjg5MzUxMS80MDAyNDExMzEtMmYwMWY2MDMtMzMxZi00OWU3LWEwZTYtYmJmMTRmYjc3MGE5LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNTA4MzElMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjUwODMxVDE1MDMwNVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTU2MTNkOWMwNzdkN2ZmZGYxZTQyZTVkY2VlMjBkNDdlNDlkZThmOTExNjRiZDgyMWQ3ZTA1ZjY0NTdlYWZhZDImWC1BbXJ6LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.txW7qk1T_hKHfb-TSSo97rDfPNi0dDhbSDjEx3E_WGg) 

## Resumen Ejecutivo

Este informe detalla las fases de un pentesting realizado sobre la máquina **ADMIN - VULNYX**, identificada con la IP `192.168.1.58`. El objetivo fue evaluar la postura de seguridad de la máquina Windows, desde el descubrimiento de la red hasta la escalada de privilegios a la cuenta de Administrador. Se identificaron vulnerabilidades críticas relacionadas con configuraciones de servicios (SMB, WinRM) y una gestión inadecuada de credenciales, lo que permitió obtener acceso inicial y posteriormente el control total del sistema.

## 1\. Reconocimiento y Escaneo de Red

La fase inicial se centró en identificar sistemas activos y sus servicios expuestos en el segmento de red.

### 1.1\. Descubrimiento de Hosts

Se inició un escaneo de la red local para identificar posibles direcciones IP activas que pudieran ser objetivos dentro del rango.

```
sudo netdiscover -r 192.168.1.0/24
```

**Resultado:** Se identificó el host `192.168.1.58` como un objetivo potencial dentro del segmento de red.

### 1.2\. Escaneo Inicial de Puertos

Se realizó un escaneo rápido de todos los puertos TCP (1-65535) para identificar aquellos que estaban abiertos en el objetivo, optimizando la velocidad del escaneo con `--min-rate 5000` y evitando la resolución DNS con `-n`.

```
nmap -p- --open --min-rate 5000 -sS -n -Pn 192.168.1.58 -oN firstNmap.txt
```

Los siguientes puertos fueron detectados como abiertos:

```
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

### 1.3\. Escaneo Detallado de Servicios y Versiones

Con los puertos identificados, se procedió a un escaneo más exhaustivo para determinar los servicios, sus versiones y ejecutar scripts NSE básicos que pudieran revelar vulnerabilidades o información adicional relevante.

```
nmap -p 80,135,139,445,49665,49666,49667,49669,49670 -sVC 192.168.1.58 -oN secondNmap.txt
```

```
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

**Hallazgos Clave:**

* **Servidor HTTP:** Microsoft IIS httpd 10.0 en el puerto 80\. La cabecera `http-server-header` confirma `Microsoft-IIS/10.0` y se identifica el método `TRACE` como potencialmente riesgoso.
* **Servicios SMB/NetBIOS:** Puertos 139 (netbios-ssn) y 445 (microsoft-ds) están abiertos, indicando claramente un sistema operativo Windows.
* **Sistema Operativo:** Se confirma que el objetivo es un sistema **Windows**, probablemente un servidor, dada la versión de IIS.
* **Servicios RPC:** Múltiples puertos altos (49665-49670) están asociados a Microsoft Windows RPC.
* **Nombre NetBIOS:** El nombre del equipo es `ADMIN`.

## 2\. Enumeración

Esta fase se dedicó a recopilar información más específica sobre los servicios identificados para encontrar posibles puntos de entrada.

### 2.1\. Enumeración de Directorios Web (HTTP)

Se utilizó la herramienta `dirb` con un diccionario extenso para descubrir directorios y archivos ocultos o no listados en el servidor web IIS.

```
dirb http://192.168.1.58 /usr/share/dirb/wordlist/big.txt
```

Durante la enumeración, se encontró el archivo `/tasks.txt`.

![Contenido del archivo tasks.txt](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Admin/Admin/task_web.png) 

El contenido de `tasks.txt` reveló una posible pista crucial para futuras etapas: el nombre de usuario **"hope"**.

## 3\. Explotación

Con la información recopilada, se procedió a intentar obtener acceso al sistema objetivo.

### 3.1\. Acceso a SMB y Fuerza Bruta

Los intentos iniciales de enumerar usuarios y recursos compartidos SMB con el usuario "hope" o "guest" sin credenciales resultaron infructuosos. Dada la pista del usuario "hope", se decidió realizar un ataque de fuerza bruta contra el servicio SMB.

```
nxc smb 192.168.1.58 -u "hope" -p /usr/share/wordlists/rockyou.txt --ignore-pw-decoding
```

![Credenciales obtenidas por fuerza bruta](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Admin/Admin/pass_user.png) 

El ataque de fuerza bruta fue exitoso, revelando las credenciales para el usuario **"hope"**. Las credenciales obtenidas fueron: `hope:loser`.

Con estas credenciales, se pudieron listar los recursos compartidos SMB del objetivo.

![Listado de recursos compartidos SMB](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Admin/Admin/shares.png) 

Aunque se identificó el recurso compartido `IPC$`, no se encontró información útil dentro ni se pudo realizar ninguna operación de escritura o carga de archivos. El servicio RDP no estaba activo, lo que descartaba esta vía de acceso remoto.

### 3.2\. Descubrimiento y Acceso vía WinRM

Considerando que se trata de un sistema Windows, se realizó un re-escaneo exhaustivo de todos los puertos, una práctica recomendada para no pasar por alto servicios comunes como WinRM (Windows Remote Management), que a menudo opera en los puertos 5985 (HTTP) o 5986 (HTTPS), y que no fue visible en el escaneo inicial de puertos conocidos.

```
nmap -p- -sVC 192.168.1.58 -oN recheck_nmap.txt
```

_Nota: La IP `192.168.1.19` mencionada en el texto original ha sido corregida a `192.168.1.58` para mantener la consistencia con el objetivo identificado previamente._

![Re-escaneo de Nmap mostrando WinRM](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Admin/Admin/recheck_nmap.png) 

El re-escaneo confirmó la presencia del servicio WinRM en el puerto 5985\. Se procedió a intentar el acceso remoto con las credenciales del usuario "hope" obtenidas previamente.

```
evil-winrm -i 192.168.1.58 -u hope -p loser
```

![Acceso a WinRM con usuario hope](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Admin/Admin/winrm_hope.png) 

El acceso a WinRM fue exitoso, otorgando una shell de PowerShell como el usuario "hope". Tras una pequeña búsqueda en el directorio del usuario, se localizó la flag del usuario.

![Flag del usuario hope](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Admin/Admin/user_flag.png) 

**FLAG de Usuario:** `[Contenido de la flag del usuario]`

## 4\. Escalada de Privilegios

Con una shell de usuario de bajo privilegio, el siguiente paso fue buscar vectores para obtener privilegios de administrador del sistema.

### 4.1\. Búsqueda de Vectores de Escalada (Inicial)

Se realizaron búsquedas en ubicaciones comunes para la escalada de privilegios en sistemas Windows, incluyendo:

* `C:\inetpub\wwwroot`: Directorio raíz del servicio IIS, buscando archivos de configuración sensibles, credenciales o vulnerabilidades.
* Variables de entorno para información útil.
* Archivos en el directorio personal del usuario "hope".
* Intentos de acceder al directorio del usuario Administrator.

Ninguna de estas vías iniciales arrojó resultados concluyentes o información que pudiera llevar a una escalada de privilegios directa.

### 4.2\. Descubrimiento de Credenciales de Administrador en el Historial de PowerShell

Un vector común y a menudo descuidado en entornos Windows es la revisión del historial de comandos de PowerShell. Se buscó el directorio donde se guarda este historial utilizando el comando PowerShell `ls $env:userprofile -filter "*powershell*" -recurse -force`:

```
ls $env:userprofile -filter "*powershell*" -recurse -force
```

Se encontró un archivo crucial: `consolehost_history.txt`, ubicado en `C:\Users\hope\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine`. Este archivo contenía una contraseña en texto claro para el usuario Administrator.

![Credenciales de administrador encontradas en el historial de PowerShell](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Admin/Admin/administrator_creds.png) 

**Credenciales de Administrador Encontradas:** `Administrator:[Contraseña_descubierta]`

### 4.3\. Acceso como Administrador y Obtención de la Flag

Con las credenciales del administrador en mano, se procedió a intentar el acceso a través de WinRM nuevamente, esta vez con los privilegios más elevados.

```
evil-winrm -i 192.168.1.58 -u Administrator -p [Contraseña_del_Administrador]
```

![Acceso a WinRM como Administrador](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Admin/Admin/administrator_login.png) 

El acceso fue exitoso, obteniendo una shell de PowerShell con privilegios de Administrador. Rápidamente se localizó la flag final del sistema en el directorio del administrador.

![Flag de administrador](https://github.com/Koh4kU/Writeups/raw/main/Vulnyx/Admin/Admin/admin_flag.png) 

**FLAG de Administrador:** `[Contenido de la flag del administrador]`

## 5\. Notas Adicionales: Desarrollo de Scripts Personalizados

Esta sección documenta el desarrollo de herramientas personalizadas durante el pentesting, como una alternativa a herramientas existentes o para explorar conceptos específicos.

### 5.1\. Contexto y Motivación

Durante la fase de explotación inicial, se había intentado realizar fuerza bruta contra SMB con Hydra sin éxito. En ese momento, y desconociendo la efectividad y opciones de la herramienta `nxc` (`CrackMapExec`) para SMB, se optó por desarrollar scripts personalizados en Bash para abordar la tarea de forma controlada y explorar la implementación de técnicas de concurrencia.

### 5.2\. Script: `smbBruteUsersNoPass.sh`

**Descripción:** Un script en Bash diseñado para realizar fuerza bruta sobre una lista de usuarios SMB con credenciales nulas. Esta funcionalidad podría ser comparable a la enumeración de usuarios que ofrece `enum4linux`.

**Uso:**

```
./smbBruteUsersNoPass.sh <//IP/> <list users> <processes> (opcional: 2 por defecto)
```

**Enlace:** [smbBruteUsersNoPass.sh](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/smbBruteUsersNoPass.sh)

### 5.3\. Script: `smbBrutePass.sh`

**Descripción:** Este script es similar al anterior, pero está diseñado para realizar fuerza bruta sobre una lista de posibles contraseñas para un usuario específico pasado como argumento.

**Uso:**

```
./smbBrutePass.sh <//IP/> <wordlist> <user> <processes> (opcional: 2 por defecto)
```

**Enlace:** [smbBrutePass.sh](https://github.com/Koh4kU/Writeups/blob/main/Vulnyx/Admin/smbBrutePass.sh)

### 5.4\. Principios de Multiproceso en Bash

Ambos scripts implementan una técnica de multiproceso dividiendo la lista de entrada en múltiples partes y ejecutando cada una en segundo plano (como procesos separados) para mejorar la eficiencia, en comparación con una ejecución secuencial. Aunque Bash no soporta hilos de forma nativa como lenguajes de programación más avanzados (Java, C, C++, Python), se logra un efecto similar a través de la ejecución de comandos en segundo plano (uso del operador `&`).

```
# Ejemplo simplificado de implementación multiproceso en Bash
for i in $(seq 5)
do
  echo "Process: $i"
  # Creación del proceso en segundo plano
  script.sh $i &
done
# Esperamos a que todos los procesos hijos (en segundo plano) terminen
wait
```

Es crucial tener en cuenta las **condiciones de carrera** en entornos multiproceso, donde múltiples procesos acceden a recursos compartidos. En el caso de estos scripts, el riesgo se minimiza al dividir las listas de trabajo de forma equitativa, asegurando que cada proceso maneje un conjunto de datos independiente. Esta implementación representó un ejercicio práctico para explorar la concurrencia en Bash, un concepto previamente aplicado en otros lenguajes (ej., multiprocesos padre/hijo en C, hilos con semáforos en Java).

### 5.5\. Consideraciones Importantes

**Advertencia:** Es fundamental ejercer precaución extrema al realizar ataques de fuerza bruta, especialmente con herramientas personalizadas. Durante las pruebas y el desarrollo de estos scripts, fue necesario restablecer la máquina objetivo en varias ocasiones debido a bloqueos de cuentas causados por intentos fallidos de autenticación. En entornos de producción o en pruebas de penetración reales, estas acciones pueden tener consecuencias severas, como denegación de servicio o detección por sistemas de seguridad.

## 6\. Conclusiones y Recomendaciones

La máquina **ADMIN - VULNYX** presentó múltiples vulnerabilidades que permitieron un acceso inicial y una escalada de privilegios completa, culminando en el control total del sistema. Los puntos clave de compromiso fueron:

* **Información Sensible en Archivos Públicos:** La exposición del archivo `tasks.txt` en el servidor web reveló un nombre de usuario válido ("hope"), facilitando enormemente el inicio del ataque.
* **Contraseñas Débiles/Predecibles:** La contraseña del usuario "hope" fue susceptible a un ataque de diccionario, lo que permitió el acceso inicial a través de SMB y WinRM.
* **Persistencia de Credenciales Sensibles:** La inadecuada gestión y persistencia de credenciales sensibles (incluida la del Administrador) en archivos de historial de PowerShell es una vulnerabilidad crítica que facilita la escalada de privilegios.
* **Configuración de Servicios Abiertos:** Aunque no son vulnerabilidades intrínsecas, la accesibilidad de servicios como SMB y WinRM sin una protección robusta (como bloqueo de cuentas o autenticación multifactor) permitió la ejecución de los ataques.

**Recomendaciones para Mitigación:**

Para fortalecer la postura de seguridad de la máquina ADMIN - VULNYX y prevenir futuros compromisos, se recomiendan las siguientes acciones:

1. **Revisión y Hardening de Contenido Web:** Implementar revisiones periódicas y automatizadas del contenido de los servidores web para asegurar que no se exponga información sensible (como nombres de usuario, contraseñas, o archivos de configuración) accidentalmente. Considerar el uso de listas blancas para el contenido publicado.
2. **Políticas de Contraseñas Fuertes:** Enforzar políticas de contraseñas estrictas que incluyan requisitos de complejidad, longitud mínima (superior a 12 caracteres), uso de múltiples tipos de caracteres, y rotación regular para todos los usuarios, especialmente aquellos con acceso a servicios críticos.
3. **Gestión Segura de Credenciales:** Evitar almacenar credenciales sensibles en archivos de historial de comandos, scripts o texto plano. Implementar soluciones de gestión de secretos seguras (ej., HashiCorp Vault, Azure Key Vault) para almacenar y acceder a credenciales de forma controlada y cifrada.
4. **Configuración de Seguridad de PowerShell:** Configurar políticas de grupo para limpiar o cifrar automáticamente el historial de PowerShell. Si no es estrictamente necesario, deshabilitar la persistencia del historial para usuarios con privilegios elevados. Educar a los usuarios sobre las mejores prácticas de seguridad al usar la línea de comandos.
5. **Monitoreo y Bloqueo de Cuentas:** Implementar mecanismos de bloqueo de cuentas tras un número definido de intentos fallidos (ej., 3-5 intentos) para mitigar ataques de fuerza bruta contra usuarios de dominio o locales. Configurar alertas para intentos fallidos repetidos.
6. **Hardening de Servicios de Red:** Aplicar hardening a servicios como SMB y WinRM. Restringir el acceso a estos servicios solo a direcciones IP y usuarios autorizados mediante firewalls y listas de control de acceso. Asegurar el uso de firmas SMB (SMB Signing Required) para prevenir ataques de retransmisión.
7. **Principios de Mínimo Privilegio:** Asegurarse de que los usuarios y servicios solo tengan los permisos estrictamente necesarios para realizar sus funciones, reduciendo el impacto de un posible compromiso.

\`\`\`