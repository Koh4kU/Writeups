¡Excelente! Como experto en pentesting y documentación, he revisado a fondo los datos proporcionados sobre la máquina Vulnyx - ADMIN. A continuación, presento un informe de pentesting detallado, estructurado de manera profesional y con recomendaciones claras, siguiendo las mejores prácticas en la industria.

---

# Informe de Pentesting: Vulnyx - ADMIN

**Fecha:** 30 de Diciembre de 2024
**Evaluador:** [Tu Nombre/Empresa - simulado]
**Versión del Informe:** 1.0

---

## 1. Introducción y Alcance

Este informe detalla los hallazgos y el proceso de una evaluación de seguridad (pentesting) realizada sobre un objetivo específico, identificado como "Vulnyx - ADMIN". El objetivo principal de esta evaluación fue identificar y explotar vulnerabilidades que pudieran comprometer la confidencialidad, integridad y disponibilidad del sistema, así como obtener acceso a nivel de usuario y, finalmente, a nivel de administrador.

**Tipo de Prueba:** Interna, tipo "Black Box" (inicialmente, sin conocimiento previo de la infraestructura interna), evolucionando a "Grey Box" (tras la identificación del host).

**Alcance de la Evaluación:**
*   **Dirección IP del Objetivo:** `192.168.1.58`
*   **Sistema Operativo Objetivo:** Microsoft Windows Server (IIS 10.0 detectado).
*   **Objetivos:**
    *   Identificar hosts activos en la red.
    *   Descubrir puertos y servicios abiertos.
    *   Enumerar recursos compartidos, directorios web y usuarios.
    *   Explotar vulnerabilidades para obtener acceso inicial de usuario.
    *   Escalar privilegios para obtener acceso de administrador.
    *   Documentar el proceso, las vulnerabilidades y las recomendaciones.

## 2. Metodología

La metodología empleada sigue las fases estándar de un pentesting, adaptadas al contexto de la red y el sistema objetivo:

1.  **Reconocimiento y Escaneo de Red:** Identificación de activos y servicios expuestos.
2.  **Enumeración:** Extracción de información detallada sobre los servicios y posibles puntos de entrada.
3.  **Explotación:** Aprovechamiento de vulnerabilidades para obtener acceso inicial.
4.  **Escalada de Privilegios:** Búsqueda y explotación de debilidades para elevar el nivel de acceso dentro del sistema comprometido.
5.  **Análisis y Documentación:** Evaluación de los hallazgos y formulación de recomendaciones.

## 3. Reconocimiento y Escaneo de Red

### 3.1 Identificación de Hosts Activos

Se inició la fase de reconocimiento con un escaneo de la red local para identificar posibles objetivos activos.

**Comando Ejecutado:**
```bash
sudo netdiscover -r 192.168.1.0/24
```

**Hallazgos:**
Se identificó la dirección IP `192.168.1.58` como un posible host activo para continuar la evaluación.

### 3.2 Escaneo Detallado de Puertos y Servicios

Una vez identificado el host, se procedió a un escaneo exhaustivo de puertos para determinar los servicios que se estaban ejecutando.

**Comandos Ejecutados:**

1.  **Primer Escaneo (Puertos Abiertos con Alta Velocidad):**
    ```bash
    nmap -p- --open --min-rate 5000 -sS -n -Pn 192.168.1.58 -oN firstNmap.txt
    ```
    **Resultados Principales:**
    ```
    PORT      STATE SERVICE
    80/tcp    open  http
    135/tcp   open  msrpc
    139/tcp   open  netbios-ssn
    445/tcp   open  microsoft-ds
    49665/tcp open  unknown
    49666/tcp open  unknown
    49667/tcp open  unknown
    49669/tcp open  unknown
    49670/tcp open  unknown
    ```

2.  **Segundo Escaneo (Versiones de Servicio y Detección de SO):**
    ```bash
    nmap -p 80,135,139,445,49665,49666,49667,49669,49670 -sVC 192.168.1.58 -oN secondNmap.txt
    ```
    **Resultados Clave:**
    *   **Port 80/tcp (HTTP):**
        *   **Servicio:** Microsoft IIS httpd 10.0
        *   **Título Web:** `IIS Windows`
        *   **Encabezado HTTP:** `Microsoft-IIS/10.0`
        *   **Métodos HTTP:** `TRACE` detectado como potencialmente riesgoso.
    *   **Port 135/tcp (MSRPC):** Microsoft Windows RPC
    *   **Port 139/tcp (NetBIOS-SSN):** Microsoft Windows netbios-ssn
    *   **Port 445/tcp (SMB/Microsoft-DS):**
        *   **Información SMB:** `NetBIOS name: ADMIN`, `NetBIOS user: <unknown>`, `MAC: 08:00:27:72:8D:13` (Oracle VirtualBox).
        *   **Seguridad SMB:** `Message signing enabled but not required`.
    *   **Ports 49665-49670/tcp (MSRPC):** Microsoft Windows RPC
    *   **Sistema Operativo:** Windows
    *   **Información de Host:** Oracle VirtualBox virtual NIC

**Análisis de Reconocimiento:**
Los servicios expuestos (HTTP, MSRPC, SMB/NetBIOS) son típicos de un entorno Windows. El servidor web IIS 10.0 y la configuración SMB (firmado habilitado pero no requerido) presentan puntos de interés para la enumeración y posible explotación. La presencia del método TRACE en HTTP es un hallazgo de seguridad menor pero a considerar.

## 4. Enumeración

### 4.1 Enumeración de Directorios Web (HTTP - Port 80)

Se realizó un escaneo de directorios en el servidor web para identificar recursos ocultos o sensibles.

**Herramienta Utilizada:** `dirb`
**Comando Ejecutado:**
```bash
dirb http://192.168.1.58 /usr/share/dirb/wordlist/big.txt
```

**Hallazgos:**
Se descubrió el archivo `/tasks.txt`. Al acceder a este archivo a través del navegador, se encontró el siguiente contenido (referencia a la captura de pantalla `task_web.png`):
```
Task for hope: "Fix the server config, it's not working properly."
```
Este hallazgo es crucial, ya que nos proporciona un posible nombre de usuario: `hope`.

### 4.2 Enumeración SMB (Ports 139, 445)

Se intentó enumerar usuarios y recursos compartidos a través de SMB utilizando el nombre de usuario `hope` y el usuario por defecto `guest`, pero no se logró acceder a recursos sin credenciales. Sin embargo, se confirmó el dominio NetBIOS como `ADMIN`.

## 5. Explotación (Compromiso Inicial)

### 5.1 Ataque de Fuerza Bruta a SMB

Dado el nombre de usuario `hope` y la falta de acceso sin credenciales a través de SMB, se procedió a realizar un ataque de fuerza bruta sobre este usuario, asumiendo una política de contraseñas débil.

**Vulnerabilidad:** Contraseña débil o predecible para un usuario de red.
**Herramienta Utilizada:** `nxc` (CrackMapExec)
**Comando Ejecutado:**
```bash
nxc smb 192.168.1.58 -u "hope" -p /usr/share/wordlists/rockyou.txt --ignore-pw-decoding
```

**Hallazgos:**
El ataque de fuerza bruta fue exitoso (referencia a la captura de pantalla `pass_user.png`). Se obtuvieron las siguientes credenciales:
*   **Usuario:** `hope`
*   **Contraseña:** `loser`

### 5.2 Listado de Recursos Compartidos SMB con Credenciales

Con las credenciales obtenidas, se listaron los recursos compartidos SMB disponibles.

**Comando Ejecutado (ejemplo con nxc):**
```bash
nxc smb 192.168.1.58 -u hope -p loser --shares
```

**Hallazgos:**
Se identificaron varios recursos compartidos (referencia a la captura de pantalla `shares.png`), incluyendo `IPC$`. Sin embargo, al intentar acceder a `IPC$`, no se encontró información útil ni se pudieron subir archivos, lo que indicaba permisos de solo lectura o nulos para este recurso en particular para el usuario `hope`.

### 5.3 Acceso Remoto vía WinRM (Port 5985)

Dado que RDP no estaba activo y los recursos SMB no ofrecían una vía clara para la escalada, se realizó un re-escaneo más exhaustivo de puertos, prestando especial atención a los servicios de gestión remota de Windows, como WinRM.

**Comando Ejecutado (revisión de puertos completa):**
```bash
nmap -p- -sVC 192.168.1.58 -oN recheck_nmap.txt
```
*Nota: En el dato original se menciona `192.168.1.19` en este comando, pero asumo que es una errata y el objetivo principal sigue siendo `192.168.1.58`.*

**Hallazgos del Re-escaneo:**
Se confirmó que el puerto `5985/tcp` (WinRM HTTP) estaba abierto y ejecutando el servicio `Microsoft IIS httpd 10.0`.

**Herramienta Utilizada:** `evil-winrm`
**Comando Ejecutado:**
```bash
evil-winrm -i 192.168.1.58 -u hope -p loser
```

**Hallazgos:**
Se obtuvo acceso remoto exitoso al sistema como el usuario `hope` a través de WinRM (referencia a la captura de pantalla `winrm_hope.png`).

Una vez dentro, se localizó la flag del usuario (referencia a la captura de pantalla `user_flag.png`), confirmando el compromiso inicial.
**Ubicación de la flag de usuario:** `C:\Users\hope\Desktop\user.txt` (ubicación inferida de la captura).

## 6. Escalada de Privilegios

### 6.1 Búsqueda de Información Sensible para Escalada

Se exploraron varias ubicaciones y configuraciones del sistema en busca de vectores de escalada de privilegios:
*   `C:\inetpub\wwwroot`: Directorio raíz del servicio web IIS, no se encontró nada interesante.
*   Variables de entorno y directorios de usuario: No revelaron información útil inicialmente.
*   Acceso al directorio del usuario `Administrator`: Denegado.

### 6.2 Credenciales en el Historial de PowerShell

Se realizó una búsqueda específica de archivos de historial de PowerShell, ya que a menudo pueden contener credenciales en texto claro.

**Comando Ejecutado (ejemplo para localizar historial):**
```powershell
ls $env:userprofile -filter "*powershell*" -recurse -force
```

**Hallazgos:**
Se descubrió el archivo `ConsoleHost_history.txt` en la ruta `C:\Users\hope\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`. Al revisar su contenido, se encontró una contraseña en texto claro (referencia a la captura de pantalla `administrator_creds.png`), la cual correspondía al usuario `Administrator`.

**Credenciales Obtenidas:**
*   **Usuario:** `Administrator`
*   **Contraseña:** [Contraseña encontrada en el historial]

### 6.3 Acceso Administrativo vía WinRM

Con las credenciales del `Administrator`, se intentó nuevamente el acceso remoto a través de WinRM.

**Herramienta Utilizada:** `evil-winrm`
**Comando Ejecutado:**
```bash
evil-winrm -i 192.168.1.58 -u Administrator -p <contraseña_recopilada>
```

**Hallazgos:**
El acceso como `Administrator` fue exitoso (referencia a la captura de pantalla `administrator_login.png`), confirmando la escalada de privilegios a nivel de sistema.

Finalmente, se localizó la flag de administrador (referencia a la captura de pantalla `admin_flag.png`).
**Ubicación de la flag de administrador:** `C:\Users\Administrator\Desktop\root.txt` (ubicación inferida de la captura).

## 7. Hallazgos y Recomendaciones

A continuación se detallan las vulnerabilidades identificadas y las recomendaciones para mitigar los riesgos asociados.

### 7.1 Resumen de Hallazgos

| ID | Vulnerabilidad                                  | Riesgo | Impacto                 |
|----|-------------------------------------------------|--------|-------------------------|
| V01| Contraseña débil para el usuario `hope`         | Alto   | Compromiso inicial de usuario |
| V02| Credenciales en texto claro en historial de PowerShell | Crítico| Escalada de privilegios a administrador |
| V03| Firma de mensajes SMB habilitada pero no requerida | Medio  | Posibilidad de ataques MiTM |
| V04| Método HTTP TRACE habilitado en IIS             | Bajo   | Divulgación de encabezados |
| V05| Falta de monitoreo de intentos de fuerza bruta   | Medio  | Permite ataques de adivinación de contraseñas |

### 7.2 Recomendaciones Detalladas

#### V01: Contraseña débil para el usuario `hope`
*   **Recomendación:** Implementar y hacer cumplir una política de contraseñas robusta que incluya:
    *   Longitud mínima (ej. 12-16 caracteres).
    *   Complejidad (combinación de mayúsculas, minúsculas, números y caracteres especiales).
    *   Rotación periódica de contraseñas (cada 60-90 días).
    *   Prohibir contraseñas comunes, predecibles o basadas en diccionarios.
*   **Acción Inmediata:** Cambiar la contraseña del usuario `hope` por una fuerte y única.

#### V02: Credenciales en texto claro en historial de PowerShell
*   **Recomendación:** Implementar políticas de seguridad que impidan el almacenamiento de credenciales sensibles en texto claro, especialmente en archivos de historial de comandos.
    *   Utilizar soluciones de gestión de secretos (ej. HashiCorp Vault, Azure Key Vault) para almacenar y recuperar credenciales de forma segura.
    *   Educación y concienciación del personal sobre las prácticas seguras de manejo de credenciales.
    *   Configurar PowerShell para limpiar el historial regularmente o deshabilitar el registro de comandos sensibles.
    *   Para scripts automatizados, utilizar credenciales almacenadas de forma segura o tokens de acceso en lugar de credenciales hardcodeadas.
*   **Acción Inmediata:**
    *   Limpiar el historial de PowerShell del usuario `hope`.
    *   Cambiar la contraseña del usuario `Administrator` inmediatamente.
    *   Revisar otros perfiles de usuario en busca de vulnerabilidades similares.

#### V03: Firma de mensajes SMB habilitada pero no requerida
*   **Recomendación:** Configurar el servidor Windows para **requerir** la firma de mensajes SMB. Esto mitiga ataques de retransmisión (SMB Relay) y ataques Man-in-the-Middle (MiTM) donde un atacante podría interceptar y modificar el tráfico SMB.
    *   **Configuración:** Habilitar la política de seguridad "Microsoft network server: Digitally sign communications (always)" a "Enabled".

#### V04: Método HTTP TRACE habilitado en IIS
*   **Recomendación:** Deshabilitar el método HTTP TRACE en el servidor IIS, ya que puede ser utilizado para ataques de Cross-Site Tracing (XST) y para obtener información sobre encabezados HTTP internos, lo que puede ayudar a eludir mecanismos de seguridad como `HttpOnly` en cookies.
    *   **Configuración:** Esto se puede hacer a través del `web.config` o el `IIS Manager` restringiendo los verbos HTTP permitidos.

#### V05: Falta de monitoreo de intentos de fuerza bruta
*   **Recomendación:** Implementar un sistema de monitoreo y alertas que detecte y responda a intentos repetidos de autenticación fallidos (fuerza bruta) en servicios como SMB y WinRM.
    *   Configurar umbrales de bloqueo de cuenta después de un número específico de intentos fallidos.
    *   Integrar logs de eventos de seguridad de Windows con un SIEM (Security Information and Event Management) para una correlación y análisis de eventos centralizados.

## 8. Apéndice: Scripts Personalizados (PLUS)

Se incluyen dos scripts personalizados en Bash, desarrollados durante la fase de explotación, que demuestran la capacidad de realizar ataques de fuerza bruta sobre SMB de manera rudimentaria y con soporte de multiprocesamiento.

### 8.1 `smbBruteUsersNoPass.sh`
*   **Propósito:** Realiza fuerza bruta sobre una lista de usuarios con contraseñas nulas o vacías en SMB.
*   **Uso:** `./smbBruteUsersNoPass.sh <//IP/> <list users> [processes (default: 2)]`

### 8.2 `smbBrutePass.sh`
*   **Propósito:** Realiza fuerza bruta sobre una contraseña específica para un usuario dado en SMB.
*   **Uso:** `./smbBrutePass.sh <//IP/> <wordlist> <user> [processes (default: 2)]`

### 8.3 Multiprocesamiento en Bash
Ambos scripts utilizan una implementación básica de multiprocesamiento en Bash, dividiendo la carga de trabajo (listas de usuarios o contraseñas) entre múltiples procesos ejecutados en segundo plano. Esto mejora la eficiencia en comparación con una ejecución secuencial. La técnica se basa en el uso del bucle `for` y el operador `&` para ejecutar comandos en segundo plano, y `wait` para sincronizar la terminación de los procesos hijos.

**Consideraciones:**
*   Aunque es un ejercicio valioso para comprender el multiprocesamiento en Bash, para pentesting en entornos productivos, se recomienda el uso de herramientas especializadas y bien mantenidas como `nxc` (CrackMapExec), que ofrecen mayor robustez, eficiencia y manejan mejor las condiciones de red y las políticas de bloqueo de cuentas.
*   **Importante:** La fuerza bruta, especialmente con scripts personalizados que no gestionan el bloqueo de cuentas, puede llevar al bloqueo de usuarios legítimos, lo que impactaría en la disponibilidad del servicio. Esto se experimentó durante la prueba, requiriendo el restablecimiento de la máquina en varias ocasiones.

---

Este informe concluye la evaluación de seguridad de Vulnyx - ADMIN. Se recomienda encarecidamente la implementación de todas las recomendaciones para mejorar significativamente la postura de seguridad del sistema.