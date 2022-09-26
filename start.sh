#!/usr/bin/env bash

export KEYDIR=/etc/shibboleth/certs
if [ ! -f "$KEYDIR/sp-cert.pem" ]; then
	shib-keygen -o $KEYDIR -n sp
fi

# Disable everyones access to Business Processes and Reporting§
sed -i 's/^authorized_for_business_processes=.*/authorized_for_business_processes=/g' /etc/thruk/cgi.cfg
sed -i 's/^authorized_for_reports=.*/authorized_for_reports=/g' /etc/thruk/cgi.cfg

# Users with read only
sed -i "s/^authorized_for_all_services=.*/authorized_for_all_services=${READONLY_USERS}/g" /etc/thruk/cgi.cfg
sed -i "s/^authorized_for_all_hosts=.*/authorized_for_all_hosts=${READONLY_USERS}/g" /etc/thruk/cgi.cfg
sed -i "s/^authorized_for_read_only=.*/authorized_for_read_only=${READONLY_USERS}/g" /etc/thruk/cgi.cfg
# Admin users
sed -i "s/^authorized_for_admin=.*/authorized_for_admin=${ADMIN_USERS}/g" /etc/thruk/cgi.cfg

service shibd start

env APACHE_LOCK_DIR=/var/lock/apache2 APACHE_RUN_DIR=/var/run/apache2 APACHE_PID_FILE=/var/run/apache2/apache2.pid APACHE_RUN_USER=www-data APACHE_RUN_GROUP=www-data APACHE_LOG_DIR=/var/log/apache2 apache2 -DFOREGROUND


