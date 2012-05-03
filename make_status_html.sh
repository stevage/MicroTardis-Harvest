#!/bin/bash
HTML='<html><head><link rel="stylesheet" type="text/css" href="http://rmmf.isis.rmit.edu.au/static/css/microtardis.css"/></head><body><div class="statusbox">'
HTML=$HTML'<ul>'
HTML=$HTML'<h3>Data harvesting status</h3>'
for MACHINE in NovaNanoSEM Quanta200 XL30; do
  if [ -e "${MACHINE}_status_ok.txt" ]; then
    TEXT=`cat ${MACHINE}_status_ok.txt`
    HTML=$HTML'<li>'${MACHINE}': <span class="statusbox_item_ok" title="'$TEXT'">Active</span></li>'
  else
    TEXT=`cat ${MACHINE}_status_down.txt`
    HTML=$HTML'<li>'${MACHINE}': <span class="statusbox_item_error" title="'$TEXT'">Offline</span></li>'
  fi
done
HTML=$HTML'</ul>'
HTML=$HTML'<small>Last update: '`date`
HTML=$HTML'</div></body></html>'
echo "$HTML" > status.html
echo "$HTML" > /var/www/html/status.html

