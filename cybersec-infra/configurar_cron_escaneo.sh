#!/bin/bash

# Crear un trabajo cron para ejecutar el escaneo de seguridad cada 2 horas
(crontab -l 2>/dev/null; echo "0 */2 * * * /usr/bin/ansible-playbook /ruta/a/escaneo_seguridad.yml >> /var/log/cron_escaneo_seguridad.log 2>&1") | crontab -

echo "El trabajo cron de escaneo de seguridad ha sido configurado para ejecutarse cada 2 horas."