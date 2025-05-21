# tfg

Hola!, binevenido a mi tfg!

Para entender un poquito de que va este proyecto tendras que tener conocimientos en:
    - Docker
    - Ansible
    - Redes
    - Kubernetes
    - GithubActions


Esta es la estructura de archivos que seguira el proyecto:

```bash

cybersec-infra/
│
├── docker-compose.yml                      # Archivo principal de Docker Compose
│
├── dns/                                    # Configuración del servidor DNS
│   ├── Dockerfile
│   ├── config/
│   │   ├── named.conf                      # Configuración principal de BIND9
│   │   ├── named.conf.options              # Opciones generales del servidor DNS
│   │   └── named.conf.local                # Definición de zonas locales
│   └── zones/
│       ├── db.borjagarcia                  # Archivo de zona directa
│       └── db.172.20                       # Archivo de zona inversa
│
├── web/                                    # Configuración de servidores web
│   ├── nginx1/
│   │   └── conf/
│   │       └── default.conf                # Configuración del primer servidor Nginx
│   │
│   ├── nginx2/
│   │   └── conf/
│   │       └── default.conf                # Configuración del segundo servidor Nginx
│   │
│   └── apache_lb/                          # Balanceador de carga Apache
│       ├── Dockerfile
│       ├── httpd.conf                      # Configuración principal de Apache
│       └── extra/
│           └── httpd-vhosts.conf           # Configuración de hosts virtuales
│
├── database/                               # Configuración de base de datos
│   ├── data/                               # Directorio para datos persistentes de MariaDB
│   ├── init/
│   │   └── 01-schema.sql                   # Script de inicialización de la base de datos (modificado)
│   └── conf/
│       └── my.cnf                          # Configuración optimizada de MariaDB
│
├── www/                                    # Archivos de la aplicación web (modificados)
│   ├── index.html                          # Página de inicio simplificada
│   ├── login.php                           # Página de login para clientes y empleados
│   ├── cliente_dashboard.php               # Panel para clientes con paquetes de servicios
│   ├── empleado_dashboard.php              # Panel para empleados con clientes asignados
│   ├── logout.php                          # Script para cerrar sesión
│   └── css/
│       └── style.css                       # Estilos CSS simplificados
│
├── escaneo_seguridad.yml                   # Playbook de Ansible para escaneo de seguridad
├── configurar_cron_escaneo.sh              # Script para configurar el cron de escaneo
└── endurecimiento_seguridad_windows.ps1    # Script PowerShell para endurecimiento de Windows
```


## DESPLIEGUE DE LA INFRAESTRUCTURA:

## 1. Preparación del Entorno

Asegúrate de tener instalados Docker y Docker Compose en tu sistema. Si no los tienes, puedes instalarlos siguiendo las instrucciones oficiales:

- [Instalar Docker](https://docs.docker.com/get-docker/)
- [Instalar Docker Compose](https://docs.docker.com/compose/install/)


## 2. Crear la Estructura de Directorios

Primero, crea la estructura de directorios del proyecto:

```shellscript
mkdir -p cybersec-infra/{dns/{config,zones},web/{nginx1/conf,nginx2/conf,apache_lb/extra},database/{data,init,conf},www/css}
cd cybersec-infra
```

## 3. Crear los Archivos de Configuración

Crea todos los archivos mencionados en la estructura anterior con el contenido que hemos definido. Asegúrate de que los archivos tengan los permisos correctos:

```shellscript
chmod +x configurar_cron_escaneo.sh
```

## 4. Construir y Levantar los Contenedores

Una vez que hayas creado todos los archivos, ejecuta el siguiente comando desde el directorio raíz del proyecto para construir y levantar los contenedores:

```shellscript
docker-compose up -d
```

Este comando construirá las imágenes necesarias y levantará todos los contenedores en segundo plano.

## 5. Verificar que los Contenedores Están Funcionando

Verifica que todos los contenedores estén funcionando correctamente:

```shellscript
docker-compose ps
```

Deberías ver algo similar a esto:

```plaintext
         Name                       Command               State         Ports       
-----------------------------------------------------------------------------------
servidor_dns           /usr/sbin/named -g -c /etc/ ...   Up      53/tcp, 53/udp    
balanceador_apache     httpd-foreground                  Up      0.0.0.0:80->80/tcp
servidor_mariadb       docker-entrypoint.sh mysqld       Up      3306/tcp          
servidor_nginx1        nginx -g daemon off;              Up      80/tcp            
servidor_nginx2        nginx -g daemon off;              Up      80/tcp            
```

## 6. Configurar el Archivo Hosts Local (Opcional)

Para acceder al sitio web usando el nombre de dominio configurado, añade la siguiente línea a tu archivo hosts:

En Linux/Mac:

```shellscript
sudo nano /etc/hosts
```

En Windows:

```plaintext
C:\Windows\System32\drivers\etc\hosts
```

Añade esta línea:

```plaintext
127.0.0.1 www.borjagarcia
```

## 7. Acceder a la Aplicación Web

Ahora puedes acceder a la aplicación web de dos maneras:

- **Usando la dirección IP**: [http://localhost](http://localhost)
- **Usando el nombre de dominio** (si configuraste el archivo hosts): [http://www.borjagarcia](http://www.borjagarcia)


## 8. Credenciales de Acceso

### Para acceder como Cliente:

- **Correo**: [carlos@superlopez.es](mailto:carlos@superlopez.es)
- **Contraseña**: cliente123


### Para acceder como Empleado:

- **Correo**: [laura@ciberseguridad.es](mailto:laura@ciberseguridad.es)
- **Contraseña**: empleado123


## 9. Ejecutar el Playbook de Ansible (Opcional)

Si deseas ejecutar el playbook de Ansible para el escaneo de seguridad:

```shellscript
ansible-playbook escaneo_seguridad.yml
```

Para configurar la ejecución automática cada 2 horas:

```shellscript
./configurar_cron_escaneo.sh
```

## 10. Ejecutar el Script de PowerShell en Windows (Opcional)

Para ejecutar el script de endurecimiento de seguridad en un sistema Windows, copia el archivo `endurecimiento_seguridad_windows.ps1` a tu sistema Windows y ejecútalo como administrador:

```powershell
powershell -ExecutionPolicy Bypass -File endurecimiento_seguridad_windows.ps1
```

## 11. Detener el Proyecto

Cuando hayas terminado de usar el proyecto, puedes detener todos los contenedores con:

```shellscript
docker-compose down
```

Si quieres eliminar también los volúmenes (esto borrará los datos de la base de datos):

```shellscript
docker-compose down -v
```

## Solución de Problemas

### Si tienes problemas con la resolución DNS:

Verifica que el contenedor DNS esté funcionando:

```shellscript
docker logs servidor_dns
```

### Si no puedes acceder a la aplicación web:

Verifica que el balanceador de carga y los servidores Nginx estén funcionando:

```shellscript
docker logs balanceador_apache
docker logs servidor_nginx1
docker logs servidor_nginx2
```

### Si tienes problemas con la base de datos:

Verifica que el contenedor de MariaDB esté funcionando:

```shellscript
docker logs servidor_mariadb
```

Puedes conectarte directamente a la base de datos para verificar:

```shellscript
docker exec -it servidor_mariadb mysql -uusuario_ci
```