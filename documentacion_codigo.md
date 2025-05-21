## EXPLICACION DE ALGUNOS ARCHIVOS

Docker Compose (docker-compose.yml)
yaml
version: '3.8'
Define la versión de la sintaxis de Docker Compose que se está utilizando (3.8 es una versión reciente con todas las características necesarias).
```yaml
networks:
  red_ciberseg:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```
Define una red llamada red_ciberseg con el driver bridge (permite que los contenedores se comuniquen entre sí). IPAM (IP Address Management) configura la subred 172.20.0.0/16 para asignar direcciones IP a los contenedores.
yaml
services:
  # Servidor DNS`
```YAML
  dns:
    build: ./dns
    container_name: servidor_dns
    networks:
      red_ciberseg:
        ipv4_address: 172.20.0.2
    ports:
      - "53:53/udp"
      - "53:53/tcp"
    volumes:
      - ./dns/config:/etc/bind
      - ./dns/zones:/var/lib/bind
```
Define el servicio DNS:

- build: ./dns: Construye la imagen desde el directorio ./dns
- container_name: Asigna un nombre al contenedor
- networks: Conecta el contenedor a la red red_ciberseg con la IP fija 172.20.0.2
- ports: Mapea los puertos 53 UDP y TCP (estándar para DNS) del host al contenedor
- volumes: Monta los directorios de configuración y zonas DNS del host al contenedor
````yaml
  # Servidores Nginx
  nginx1:
    image: nginx:latest
    container_name: servidor_nginx1
    networks:
      red_ciberseg:
        ipv4_address: 172.20.0.10
    volumes:
      - ./web/nginx1/conf:/etc/nginx/conf.d
      - ./www:/var/www/html
    depends_on:
      - dns
````
Define el primer servidor Nginx:

- image: nginx:latest: Usa la imagen oficial más reciente de Nginx
- container_name: Asigna un nombre al contenedor
- networks: Conecta a la red con IP fija 172.20.0.10
- volumes: Monta la configuración específica de nginx1 y el directorio web compartido
- depends_on: Indica que este servicio depende del servicio DNS
````yaml
  nginx2:
    image: nginx:latest
    container_name: servidor_nginx2
    networks:
      red_ciberseg:
        ipv4_address: 172.20.0.11
    volumes:
      - ./web/nginx2/conf:/etc/nginx/conf.d
      - ./www:/var/www/html
    depends_on:
      - dns
````
Define el segundo servidor Nginx, similar al primero pero con IP 172.20.0.11 y configuración específica para nginx2.
yaml
  # Balanceador de Carga Apache
```yaml
  apache_lb:
    build: ./web/apache_lb
    container_name: balanceador_apache
    networks:
      red_ciberseg:
        ipv4_address: 172.20.0.5
    ports:
      - "80:80"
    depends_on:
      - nginx1
      - nginx2
```
Define el balanceador de carga Apache:

- build: Construye la imagen desde el directorio especificado
- container_name: Asigna un nombre al contenedor
- networks: Conecta a la red con IP fija 172.20.0.5
- ports: Mapea el puerto 80 (HTTP) del host al contenedor
- depends_on: Indica que depende de ambos servidores Nginx
```yaml
  # MariaDB
  mariadb:
    image: mariadb:latest
    container_name: servidor_mariadb
    networks:
      red_ciberseg:
        ipv4_address: 172.20.0.20
    environment:
      MYSQL_ROOT_PASSWORD: contraseñaroot
      MYSQL_DATABASE: bd_ciberseg
      MYSQL_USER: usuario_ciberseg
      MYSQL_PASSWORD: contraseña_ciberseg
    volumes:
      - ./database/data:/var/lib/mysql
      - ./database/init:/docker-entrypoint-initdb.d
      - ./database/conf:/etc/mysql/conf.d
    ports:
      - "3306:3306"
```
Define el servidor de base de datos MariaDB:

- image: Usa la imagen oficial más reciente de MariaDB
- container_name: Asigna un nombre al contenedor
- networks: Conecta a la red con IP fija 172.20.0.20
- environment: Define variables de entorno para configurar la base de datos (contraseñas, nombres)
- volumes: Monta directorios para datos persistentes, scripts de inicialización y configuración
- ports: Mapea el puerto 3306 (MySQL/MariaDB) del host al contenedor

## 2. Configuración DNS

### Dockerfile (dns/Dockerfile)
````dockerfile
FROM ubuntu/bind9:latest
#Usa la imagen oficial de BIND9 (servidor DNS) basada en Ubuntu como base.
RUN apt-get update && apt-get install -y bind9utils
#Actualiza los repositorios de paquetes e instala las utilidades de BIND9.
EXPOSE 53/tcp
EXPOSE 53/udp
#Expone el puerto 53 para TCP y UDP, que es el puerto estándar para DNS.
CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]
#Define el comando que se ejecutará cuando se inicie el contenedor:
````
- /usr/sbin/named: El ejecutable del servidor DNS BIND
- -g: Ejecuta en primer plano (necesario para Docker)
- -c /etc/bind/named.conf: Especifica el archivo de configuración
- -u bind: Ejecuta como el usuario "bind" por seguridad


### Archivo de configuración principal (dns/config/named.conf)
````shellscript
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
Incluye tres archivos de configuración separados:

- named.conf.options: Contiene opciones generales del servidor DNS
- named.conf.local: Contiene definiciones de zonas locales
- named.conf.default-zones: Contiene zonas predeterminadas como localhost
````

### Archivo de opciones (dns/config/named.conf.options)
````shellscript
options {
    directory "/var/cache/bind";
Define el directorio de caché para el servidor DNS.
shellscript
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
Configura servidores DNS externos (Google DNS) para resolver consultas que este servidor no puede resolver directamente.
shellscript
    listen-on { any; };
    listen-on-v6 { any; };
Configura el servidor para escuchar en todas las interfaces de red IPv4 e IPv6.
shellscript
    allow-query { any; };
    allow-recursion { any; };
Permite consultas y recursión desde cualquier dirección IP.
shellscript
    dnssec-validation auto;
};
````
Habilita la validación DNSSEC (DNS Security Extensions) en modo automático.

### Configuración de zonas locales (dns/config/named.conf.local)
````shellscript
zone "borjagarcia" {
    type master;
    file "/var/lib/bind/db.borjagarcia";
};
Define una zona DNS llamada "borjagarcia" donde este servidor es el maestro (autoritativo) y el archivo de zona está en la ruta especificada.
shellscript
zone "20.172.in-addr.arpa" {
    type master;
    file "/var/lib/bind/db.172.20";
};
Define una zona de resolución inversa para la subred 172.20.0.0/16, que permite la resolución de IP a nombre (PTR records).
````
### Archivo de zona (dns/zones/db.borjagarcia)

````shellscript
$TTL    604800
Define el TTL (Time To Live) predeterminado para todos los registros como 604800 segundos (7 días).
shellscript
@       IN      SOA     ns1.borjagarcia. admin.borjagarcia. (
                  2         ; Serial
             604800         ; Refresh
              86400         ; Retry
            2419200         ; Expire
             604800 )       ; Negative Cache TTL
Define el registro SOA (Start of Authority):

- @: Representa el dominio base (borjagarcia)
- IN SOA: Indica que es un registro SOA de clase Internet
- ns1.borjagarcia.: El servidor DNS primario
- admin.borjagarcia.: El correo del administrador (con @ reemplazado por .)
- 2: Número de serie (incrementar cuando se actualiza la zona)
- 604800: Tiempo de actualización para servidores secundarios (7 días)
- 86400: Tiempo de reintento si falla la actualización (1 día)
- 2419200: Tiempo de expiración si no se puede contactar al maestro (28 días)
- 604800: TTL para respuestas negativas (7 días)
shellscript
@       IN      NS      ns1.borjagarcia.
ns1     IN      A       172.20.0.2
Define el servidor de nombres (NS) para el dominio y su dirección IP (A record).
shellscript
; Servidores web
www     IN      A       172.20.0.5
nginx1  IN      A       172.20.0.10
nginx2  IN      A       172.20.0.11
lb      IN      A       172.20.0.5
Define registros A (dirección) para los servidores web:

- www apunta al balanceador de carga (172.20.0.5)
- nginx1 y nginx2 apuntan a sus respectivas IPs
- lb (load balancer) apunta al balanceador de carga
shellscript
; Servidor de base de datos
db      IN      A       172.20.0.20
Define un registro A para el servidor de base de datos.

### Archivo de zona inversa (dns/zones/db.172.20)
shellscript
$TTL    604800
@       IN      SOA     ns1.borjagarcia. admin.borjagarcia. (
                  1         ; Serial
             604800         ; Refresh
              86400         ; Retry
            2419200         ; Expire
             604800 )       ; Negative Cache TTL
Similar al registro SOA anterior, pero para la zona de resolución inversa.
shellscript
@       IN      NS      ns1.borjagarcia.
Define el servidor de nombres para la zona inversa.
shellscript
; Servidor DNS
2.0     IN      PTR     ns1.borjagarcia.
Define un registro PTR (Pointer) que mapea la IP 172.20.0.2 al nombre ns1.borjagarcia.
shellscript
; Servidores web
5.0     IN      PTR     lb.borjagarcia.
10.0    IN      PTR     nginx1.borjagarcia.
11.0    IN      PTR     nginx2.borjagarcia.
Define registros PTR para los servidores web.
shellscript
; Servidor de base de datos
20.0    IN      PTR     db.borjagarcia.
Define un registro PTR para el servidor de base de datos.
````
## 3. Configuración Nginx

### Configuración para el primer servidor Nginx (web/nginx1/conf/default.conf)
plaintext
server {
    listen 80;
    server_name nginx1.borjagarcia;
Define un bloque de servidor que escucha en el puerto 80 para el nombre de host nginx1.borjagarcia.
plaintext
    root /var/www/html;
    index index.php index.html;
Define el directorio raíz del sitio web y los archivos de índice predeterminados.
plaintext
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
Define cómo manejar las solicitudes:

- Intenta servir el archivo solicitado directamente
- Si no existe, intenta el directorio
- Si no existe, redirige a index.php con los argumentos de la URL
plaintext
    location ~ \.php$ {
        fastcgi_pass 172.20.0.20:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
Define cómo manejar los archivos PHP:

- ~: Indica una coincidencia de expresión regular
- \.php$: Coincide con archivos que terminan en .php
- fastcgi_pass: Envía solicitudes PHP al servidor FastCGI en la IP y puerto especificados
- fastcgi_index: Define el archivo de índice para FastCGI
- fastcgi_param: Define parámetros para FastCGI
- include: Incluye parámetros FastCGI predeterminados
plaintext
    # Añadir un encabezado personalizado para identificar qué servidor respondió
    add_header X-Server "nginx1";
}
Añade un encabezado HTTP personalizado para identificar que la respuesta vino del servidor nginx1.

### Configuración para el segundo servidor Nginx (web/nginx2/conf/default.conf)

Idéntica a la configuración del primer servidor, excepto por el nombre del servidor y el encabezado X-Server que muestra "nginx2".

## 4. Configuración del Balanceador de Carga Apache

### Dockerfile para Apache (web/apache_lb/Dockerfile)
dockerfile
FROM httpd:latest
Usa la imagen oficial más reciente de Apache HTTP Server como base.
dockerfile
RUN apt-get update && \
    apt-get install -y libapache2-mod-proxy-html libxml2-dev && \
    a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests
Actualiza los repositorios, instala las dependencias necesarias y habilita los módulos de Apache para el balanceo de carga:

- proxy: Módulo básico de proxy
- proxy_http: Para proxying HTTP
- proxy_balancer: Para balanceo de carga
- lbmethod_byrequests: Método de balanceo por número de solicitudes
dockerfile
COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY extra/httpd-vhosts.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf
Copia los archivos de configuración personalizados al contenedor.
dockerfile
EXPOSE 80
Expone el puerto 80 (HTTP).

### Archivo de configuración de Apache (web/apache_lb/httpd.conf)

Este archivo es extenso y contiene la configuración básica de Apache. Las partes más relevantes son:
plaintext
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule proxy_balancer_module modules/mod_proxy_balancer.so
LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
LoadModule lbmethod_byrequests_module modules/mod_lbmethod_byrequests.so
Carga los módulos necesarios para el balanceo de carga.
plaintext
ServerAdmin admin@borjagarcia
ServerName lb.borjagarcia
Define el correo del administrador y el nombre del servidor.
plaintext
Include conf/extra/httpd-vhosts.conf
Incluye el archivo de configuración de hosts virtuales.

### Configuración de hosts virtuales (web/apache_lb/extra/httpd-vhosts.conf)
plaintext
<VirtualHost *:80>
    ServerName lb.borjagarcia
    ServerAlias www.borjagarcia
Define un host virtual que responde a los nombres lb.borjagarcia y [www.borjagarcia](http://www.borjagarcia) en el puerto 80.
plaintext
    ProxyRequests Off
    ProxyPreserveHost On
- ProxyRequests Off: Deshabilita el modo de proxy directo (no queremos que actúe como proxy abierto)
- ProxyPreserveHost On: Preserva el encabezado Host original en las solicitudes reenviadas
plaintext
    <Proxy balancer://micluster>
        BalancerMember http://172.20.0.10:80 route=nginx1
        BalancerMember http://172.20.0.11:80 route=nginx2
        ProxySet lbmethod=byrequests
    </Proxy>
Define un grupo de balanceo llamado "micluster":

- Incluye dos miembros: los servidores Nginx en las IPs 172.20.0.10 y 172.20.0.11
- Asigna rutas para identificar cada servidor
- Establece el método de balanceo por número de solicitudes
plaintext
    ProxyPass / balancer://micluster/
    ProxyPassReverse / balancer://micluster/
- ProxyPass: Reenvía todas las solicitudes al grupo de balanceo
- ProxyPassReverse: Ajusta los encabezados de respuesta para que parezcan venir del balanceador
plaintext
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
Define los archivos de registro para errores y accesos### Configuración de optimización de MariaDB (database/conf/my.cnf)## Playbook de Ansible para Escaneo de Seguridad

````yaml
---
- name: Playbook de Escaneo de Seguridad
  hosts: all
  become: yes
  gather_facts: yes
````
Define el playbook:

- hosts: all: Se ejecuta en todos los hosts
- become: yes: Usa privilegios elevados (sudo)
- gather_facts: yes: Recopila información sobre los hosts
````yaml
  vars:
    directorio_logs: /var/log/escaneos_seguridad
    timestamp: "{{ lookup('pipe', 'date +%Y%m%d-%H%M%S') }}"
````
Define variables:

- directorio_logs: Ruta para almacenar logs
- timestamp: Marca de tiempo actual usando el comando date

````yaml
  tasks:
    - name: Asegurar que existe el directorio de logs
      file:
        path: "{{ directorio_logs }}"
        state: directory
        mode: '0750'
````
Primera tarea: crea el directorio de logs si no existe, con permisos 0750.



````yaml
    - name: Asegurar que nmap está instalado
      package:
        name: nmap
        state: present
        
    - name: Asegurar que lynis está instalado (herramienta de auditoría de seguridad)
      package:
        name: lynis
        state: present
      ignore_errors: yes
Instala herramientas necesarias:
````
- nmap: para escaneo de puertos
- lynis: para auditoría de seguridad
- ignore_errors: yes: Continúa si hay errores (por si lynis no está disponible)


````yaml
    - name: Ejecutar escaneo de puertos en localhost
      shell: nmap -sS -p- -T4 localhost > {{ directorio_logs }}/escaneo_puertos-{{ timestamp }}.log
      args:
        executable: /bin/bash
      register: escaneo_puertos
Ejecuta un escaneo de puertos con nmap:
````
- -sS: Escaneo SYN (semiabierto)
- -p-: Todos los puertos
- -T4: Velocidad agresiva
- Guarda la salida en un archivo de log con marca de tiempo
- register: Guarda el resultado en una variable


Las tareas siguientes realizan diversas comprobaciones de seguridad:

- Puertos en escucha
- Intentos fallidos de SSH
- Intentos fallidos de sudo
- Procesos inusuales
- Archivos con permisos de escritura para todos
- Archivos SUID/SGID
- Usuarios con contraseñas vacías
- Conexiones de red activas
- Auditoría completa con Lynis


````yaml
    - name: Crear informe resumen
      shell: |
        echo "Resumen de Escaneo de Seguridad - {{ timestamp }}" > {{ directorio_logs }}/resumen-{{ timestamp }}.log
        # ... (comandos para generar el resumen)
Crea un informe resumen con los hallazgos más importantes.

````

````yaml
    - name: Limpiar logs de escaneo antiguos (mantener últimos 14 días)
      shell: find {{ directorio_logs }} -type f -mtime +14 -delete
      args:
        executable: /bin/bash
````
Elimina logs antiguos (más de 14 días) para gestionar el espacio en disco.


## 8. Script PowerShell para Endurecimiento de Seguridad
````powershell
<#
.SYNOPSIS
    Script de Endurecimiento de Seguridad para Windows
.DESCRIPTION
    Este script implementa las mejores prácticas de seguridad para sistemas Windows.
    # ... (descripción detallada)
.NOTES
    Nombre del Archivo : endurecimiento_seguridad_windows.ps1
    Autor             : Equipo de Ciberseguridad
    Requisito Previo  : PowerShell 5.1 o posterior
    Copyright         : Ciberseguridad Borja García
.EXAMPLE
    .\endurecimiento_seguridad_windows.ps1
#>
Bloque de comentarios con información sobre el script (ayuda integrada).
powershell
# Crear un archivo de registro
$ArchivoLog = "C:\Logs\EndurecimientoSeguridad_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$DirLog = Split-Path $ArchivoLog -Parent

# Crear directorio de registro si no existe
if (-not (Test-Path $DirLog)) {
    New-Item -Path $DirLog -ItemType Directory -Force | Out-Null
}
Configura el registro (logging):
````
- Define la ruta del archivo de log con marca de tiempo
- Obtiene el directorio padre
- Crea el directorio si no existe
````powershell
# Función para escribir en el archivo de registro

function Escribir-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Mensaje,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "ADVERTENCIA", "ERROR")]
        [string]$Nivel = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $MensajeLog = "[$Timestamp] [$Nivel] $Mensaje"
    
    # Escribir en archivo de registro
    Add-Content -Path $ArchivoLog -Value $MensajeLog
    
    # También escribir en consola con código de color
    switch ($Nivel) {
        "INFO" { Write-Host $MensajeLog -ForegroundColor Green }
        "ADVERTENCIA" { Write-Host $MensajeLog -ForegroundColor Yellow }
        "ERROR" { Write-Host $MensajeLog -ForegroundColor Red }
    }
}
Define una función para escribir en el log:
```
- Acepta un mensaje y un nivel de severidad
- Añade marca de tiempo
- Escribe en el archivo y en la consola con colores según el nivel

````powershell
# Función para verificar si se ejecuta como administrador
function Test-Administrador {
    $usuarioActual = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $usuarioActual.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Verificar si se ejecuta como administrador
if (-not (Test-Administrador)) {
    Escribir-Log "Este script debe ejecutarse como Administrador. Por favor, reinicie PowerShell como Administrador." -Nivel "ERROR"
    exit 1
}
````
Verifica si el script se ejecuta con privilegios de administrador:

- Crea un objeto de seguridad para el usuario actual
- Comprueba si tiene rol de administrador
- Si no, registra un error y sale

````powershell
# Crear una copia de seguridad de la configuración de seguridad actual
Escribir-Log "Creando copia de seguridad de la configuración de seguridad actual..." -Nivel "INFO"
$DirCopiaSeguridad = "C:\Backups\ConfiguracionSeguridad_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
if (-not (Test-Path $DirCopiaSeguridad)) {
    New-Item -Path $DirCopiaSeguridad -ItemType Directory -Force | Out-Null
}

# Copia de seguridad de las políticas de cuenta actuales
secedit /export /cfg "$DirCopiaSeguridad\secpol.cfg" | Out-Null
Escribir-Log "Copia de seguridad de política de seguridad creada en $DirCopiaSeguridad\secpol.cfg" -Nivel "INFO"

# Copia de seguridad de la configuración actual del firewall
netsh advfirewall export "$DirCopiaSeguridad\firewall.wfw" | Out-Null
Escribir-Log "Copia de seguridad de configuración del firewall creada en $DirCopiaSeguridad\firewall.wfw" -Nivel "INFO"
Crea copias de seguridad de la configuración actual:
````
- Crea un directorio de backup con marca de tiempo
- Exporta la política de seguridad con secedit
- Exporta la configuración del firewall con netsh

````powershell
try {
    # 1. Política de Contraseñas: Longitud Mínima de Contraseña
    Escribir-Log "Estableciendo longitud mínima de contraseña a 12 caracteres..." -Nivel "INFO"
    net accounts /minpwlen:12
    
    # 2. Política de Contraseñas: Caducidad de Contraseña
    Escribir-Log "Estableciendo caducidad de contraseña a 90 días..." -Nivel "INFO"
    net accounts /maxpwage:90
    
    # 3. Política de Bloqueo de Cuenta
    Escribir-Log "Configurando política de bloqueo de cuenta..." -Nivel "INFO"
    net accounts /lockoutthreshold:5
    net accounts /lockoutduration:30
    net accounts /lockoutwindow:30`
````
Configura políticas de contraseñas y bloqueo de cuentas:

- Longitud mínima de 12 caracteres
- Caducidad cada 90 días
- Bloqueo tras 5 intentos fallidos durante 30 minutos


El script continúa con numerosas configuraciones de seguridad:

- Deshabilitar SMBv1
- Habilitar Firewall de Windows
- Deshabilitar cuenta de Administrador local (si hay otras cuentas admin)
- Habilitar UAC
- Configurar auditoría de inicio de sesión
- Deshabilitar AutoRun
- Habilitar BitLocker
- Y muchas más medidas de seguridad
````powershell
} catch {
    Escribir-Log "Ocurrió un error durante el endurecimiento de seguridad: $_" -Nivel "ERROR"
}
Captura cualquier error durante la ejecución y lo registra.`
````
````powershell
# Mostrar resumen de cambios
Escribir-Log "Resumen de Endurecimiento de Seguridad:" -Nivel "INFO"
Escribir-Log "- Longitud mínima de contraseña: 12 caracteres" -Nivel "INFO"
# ... (más elementos del resumen)

Escribir-Log "Se recomienda reiniciar el sistema para aplicar todos los cambios." -Nivel "INFO"
Escribir-Log "El archivo de registro se ha guardado en: $ArchivoLog" -Nivel "INFO"
Muestra un resumen de los cambios realizados y recomienda reiniciar el sistema.
````
[mysqld]
# Configuración de InnoDB
innodb_buffer_pool_size = 256M
Define el tamaño del buffer pool de InnoDB (memoria principal para almacenar datos e índices).
ini
innodb_log_file_size = 64M
Define el tamaño del archivo de log de transacciones de InnoDB.
ini
innodb_flush_log_at_trx_commit = 2
Controla cuándo se escriben los logs de transacciones a disco:

- 0: Una vez por segundo (riesgo de pérdida de datos)
- 1: En cada commit (seguro pero más lento)
- 2: Una vez por segundo, pero con flush al sistema operativo en cada commit (equilibrio)
ini
innodb_flush_method = O_DIRECT
Método de escritura a disco que evita la caché del sistema operativo para mejor rendimiento.
ini
# Configuración de caché de consultas
query_cache_type = 1
query_cache_size = 32M
query_cache_limit = 1M
Habilita y configura la caché de consultas:

- type = 1: Habilita la caché
- size: Tamaño total de la caché
- limit: Tamaño máximo de resultados individuales a cachear
ini
# Configuración de conexiones
max_connections = 100
thread_cache_size = 8
Limita el número máximo de conexiones simultáneas y el tamaño de la caché de hilos.
ini
# Tablas temporales
tmp_table_size = 32M
max_heap_table_size = 32M
Define el tamaño máximo para tablas temporales en memoria.
ini
# Otras optimizaciones
key_buffer_size = 32M
join_buffer_size = 1M
sort_buffer_size = 2M
read_buffer_size = 1M
read_rnd_buffer_size = 1M
Configura varios buffers para optimizar diferentes operaciones:

- key_buffer_size: Para índices MyISAM
- join_buffer_size: Para operaciones JOIN
- sort_buffer_size: Para operaciones ORDER BY
- read_buffer_size y read_rnd_buffer_size: Para operaciones de lectura secuencial y aleatoria
ini
# Registro
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
Habilita el registro de consultas lentas:

- slow_query_log = 1: Habilita el registro
- slow_query_log_file: Ruta del archivo de registro
- long_query_time = 2: Registra consultas que tardan más

## 7. Playbook de Ansible para Escaneo de Seguridad

```yaml
---
- name: Playbook de Escaneo de Seguridad
  hosts: all
  become: yes
  gather_facts: yes
```

Define el playbook:

- `hosts: all`: Se ejecuta en todos los hosts
- `become: yes`: Usa privilegios elevados (sudo)
- `gather_facts: yes`: Recopila información sobre los hosts


```yaml
  vars:
    directorio_logs: /var/log/escaneos_seguridad
    timestamp: "{{ lookup('pipe', 'date +%Y%m%d-%H%M%S') }}"
```

Define variables:

- `directorio_logs`: Ruta para almacenar logs
- `timestamp`: Marca de tiempo actual usando el comando date


```yaml
  tasks:
    - name: Asegurar que existe el directorio de logs
      file:
        path: "{{ directorio_logs }}"
        state: directory
        mode: '0750'
```

Primera tarea: crea el directorio de logs si no existe, con permisos 0750.

```yaml
    - name: Asegurar que nmap está instalado
      package:
        name: nmap
        state: present
        
    - name: Asegurar que lynis está instalado (herramienta de auditoría de seguridad)
      package:
        name: lynis
        state: present
      ignore_errors: yes
```

Instala herramientas necesarias:

- nmap: para escaneo de puertos
- lynis: para auditoría de seguridad
- `ignore_errors: yes`: Continúa si hay errores (por si lynis no está disponible)


```yaml
    - name: Ejecutar escaneo de puertos en localhost
      shell: nmap -sS -p- -T4 localhost > {{ directorio_logs }}/escaneo_puertos-{{ timestamp }}.log
      args:
        executable: /bin/bash
      register: escaneo_puertos
```

Ejecuta un escaneo de puertos con nmap:

- `-sS`: Escaneo SYN (semiabierto)
- `-p-`: Todos los puertos
- `-T4`: Velocidad agresiva
- Guarda la salida en un archivo de log con marca de tiempo
- `register`: Guarda el resultado en una variable


Las tareas siguientes realizan diversas comprobaciones de seguridad:

- Puertos en escucha
- Intentos fallidos de SSH
- Intentos fallidos de sudo
- Procesos inusuales
- Archivos con permisos de escritura para todos
- Archivos SUID/SGID
- Usuarios con contraseñas vacías
- Conexiones de red activas
- Auditoría completa con Lynis


```yaml
    - name: Crear informe resumen
      shell: |
        echo "Resumen de Escaneo de Seguridad - {{ timestamp }}" > {{ directorio_logs }}/resumen-{{ timestamp }}.log
        # ... (comandos para generar el resumen)
```

Crea un informe resumen con los hallazgos más importantes.

```yaml
    - name: Limpiar logs de escaneo antiguos (mantener últimos 14 días)
      shell: find {{ directorio_logs }} -type f -mtime +14 -delete
      args:
        executable: /bin/bash
```

Elimina logs antiguos (más de 14 días) para gestionar el espacio en disco.

## 8. Script PowerShell para Endurecimiento de Seguridad

```powershell
<#
.SYNOPSIS
    Script de Endurecimiento de Seguridad para Windows
.DESCRIPTION
    Este script implementa las mejores prácticas de seguridad para sistemas Windows.
    # ... (descripción detallada)
.NOTES
    Nombre del Archivo : endurecimiento_seguridad_windows.ps1
    Autor             : Equipo de Ciberseguridad
    Requisito Previo  : PowerShell 5.1 o posterior
    Copyright         : Ciberseguridad Borja García
.EXAMPLE
    .\endurecimiento_seguridad_windows.ps1
#>
```

Bloque de comentarios con información sobre el script (ayuda integrada).

```powershell
# Crear un archivo de registro
$ArchivoLog = "C:\Logs\EndurecimientoSeguridad_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$DirLog = Split-Path $ArchivoLog -Parent

# Crear directorio de registro si no existe
if (-not (Test-Path $DirLog)) {
    New-Item -Path $DirLog -ItemType Directory -Force | Out-Null
}
```

Configura el registro (logging):

- Define la ruta del archivo de log con marca de tiempo
- Obtiene el directorio padre
- Crea el directorio si no existe


```powershell
# Función para escribir en el archivo de registro
function Escribir-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Mensaje,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "ADVERTENCIA", "ERROR")]
        [string]$Nivel = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $MensajeLog = "[$Timestamp] [$Nivel] $Mensaje"
    
    # Escribir en archivo de registro
    Add-Content -Path $ArchivoLog -Value $MensajeLog
    
    # También escribir en consola con código de color
    switch ($Nivel) {
        "INFO" { Write-Host $MensajeLog -ForegroundColor Green }
        "ADVERTENCIA" { Write-Host $MensajeLog -ForegroundColor Yellow }
        "ERROR" { Write-Host $MensajeLog -ForegroundColor Red }
    }
}
```

Define una función para escribir en el log:

- Acepta un mensaje y un nivel de severidad
- Añade marca de tiempo
- Escribe en el archivo y en la consola con colores según el nivel


```powershell
# Función para verificar si se ejecuta como administrador
function Test-Administrador {
    $usuarioActual = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $usuarioActual.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Verificar si se ejecuta como administrador
if (-not (Test-Administrador)) {
    Escribir-Log "Este script debe ejecutarse como Administrador. Por favor, reinicie PowerShell como Administrador." -Nivel "ERROR"
    exit 1
}
```

Verifica si el script se ejecuta con privilegios de administrador:

- Crea un objeto de seguridad para el usuario actual
- Comprueba si tiene rol de administrador
- Si no, registra un error y sale


```powershell
# Crear una copia de seguridad de la configuración de seguridad actual
Escribir-Log "Creando copia de seguridad de la configuración de seguridad actual..." -Nivel "INFO"
$DirCopiaSeguridad = "C:\Backups\ConfiguracionSeguridad_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
if (-not (Test-Path $DirCopiaSeguridad)) {
    New-Item -Path $DirCopiaSeguridad -ItemType Directory -Force | Out-Null
}

# Copia de seguridad de las políticas de cuenta actuales
secedit /export /cfg "$DirCopiaSeguridad\secpol.cfg" | Out-Null
Escribir-Log "Copia de seguridad de política de seguridad creada en $DirCopiaSeguridad\secpol.cfg" -Nivel "INFO"

# Copia de seguridad de la configuración actual del firewall
netsh advfirewall export "$DirCopiaSeguridad\firewall.wfw" | Out-Null
Escribir-Log "Copia de seguridad de configuración del firewall creada en $DirCopiaSeguridad\firewall.wfw" -Nivel "INFO"
```

Crea copias de seguridad de la configuración actual:

- Crea un directorio de backup con marca de tiempo
- Exporta la política de seguridad con secedit
- Exporta la configuración del firewall con netsh


```powershell
try {
    # 1. Política de Contraseñas: Longitud Mínima de Contraseña
    Escribir-Log "Estableciendo longitud mínima de contraseña a 12 caracteres..." -Nivel "INFO"
    net accounts /minpwlen:12
    
    # 2. Política de Contraseñas: Caducidad de Contraseña
    Escribir-Log "Estableciendo caducidad de contraseña a 90 días..." -Nivel "INFO"
    net accounts /maxpwage:90
    
    # 3. Política de Bloqueo de Cuenta
    Escribir-Log "Configurando política de bloqueo de cuenta..." -Nivel "INFO"
    net accounts /lockoutthreshold:5
    net accounts /lockoutduration:30
    net accounts /lockoutwindow:30
```

Configura políticas de contraseñas y bloqueo de cuentas:

- Longitud mínima de 12 caracteres
- Caducidad cada 90 días
- Bloqueo tras 5 intentos fallidos durante 30 minutos


El script continúa con numerosas configuraciones de seguridad:

- Deshabilitar SMBv1
- Habilitar Firewall de Windows
- Deshabilitar cuenta de Administrador local (si hay otras cuentas admin)
- Habilitar UAC
- Configurar auditoría de inicio de sesión
- Deshabilitar AutoRun
- Habilitar BitLocker
- Y muchas más medidas de seguridad


```powershell
} catch {
    Escribir-Log "Ocurrió un error durante el endurecimiento de seguridad: $_" -Nivel "ERROR"
}
```

Captura cualquier error durante la ejecución y lo registra.

```powershell
# Mostrar resumen de cambios
Escribir-Log "Resumen de Endurecimiento de Seguridad:" -Nivel "INFO"
Escribir-Log "- Longitud mínima de contraseña: 12 caracteres" -Nivel "INFO"
# ... (más elementos del resumen)

Escribir-Log "Se recomienda reiniciar el sistema para aplicar todos los cambios." -Nivel "INFO"
Escribir-Log "El archivo de registro se ha guardado en: $ArchivoLog" -Nivel "INFO"
```

Muestra un resumen de los cambios realizados y recomienda reiniciar el sistema