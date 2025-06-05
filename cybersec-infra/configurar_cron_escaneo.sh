#!/bin/bash

(crontab -l 2>/dev/null; echo "0 */2 * * * /usr/bin/ansible-playbook /home/bgarcia/escaneo_seguridad.yml >> /var/log/cron_escaneo_seguridad.log 2>&1") | crontab -

echo " el cron de escaneo de seguridad ha sido configurado para ejecutarse cada 2 horas."