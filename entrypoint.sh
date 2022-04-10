#!/bin/sh

log_for_task() {
    echo ["$1"] [$(date -Isecond)] "$2"
}

log() {
    log_for_task "ENTRYPOINT" "$1"
}

if [ "$DOMAIN" == "" ]; then
    log "DOMAIN environment variable is required."
    exit 1
else
    log "DOMAIN = $DOMAIN"
fi

if [ "$EMAIL" == "" ]; then
    log "EMAIL environment variable is required."
    exit 1
else
    log "EMAIL = $EMAIL"
fi


# if there is no config dir, then there was no volume mapped to the right place, so bail.
if [ ! -d "/config" ]; then
    log "/config does not exist, did you forget to map a volume to /config?"
    exit 1
else
    log "/config exists, continuing."
fi

# check if we have a /config/nginx/ dir, if not - copy it from the template
if [ ! -d "/config/nginx" ]; then
    log "/config/nginx does not exist, creating from template."
    cp -R /config_template/nginx /config/nginx
else
    log "/config/nginx exists, we'll assume it's correct and continue."
fi

# check if we have a /config/nginx/nginx.conf file, if not - bail
if [ ! -f "/config/nginx/nginx.conf" ]; then
    log "/config/nginx/nginx.conf does not exist, something is wrong with your configuration."
    exit 1
else
    log "/config/nginx/nginx.conf exists, we'll use it to run nginx."
fi

# check if we have a /config/cloudflare.ini file, if not - bail
if [ ! -f "/config/cloudflare.ini" ]; then
    log "/config/cloudflare.ini does not exist, please update and restart the container. See /config/cloudflare.ini.example."
    cp "/config_template/cloudflare.ini.example" "/config/cloudflare.ini.example"
    exit 1
else
    log "/config/cloudflare.ini exists, we'll assume it is setup correctly."
fi

# check if we have a /config/sites folder, if not create from template
if [ ! -d "/config/sites" ]; then
    log "/config/sites does not exist, creating from template"
    cp -R /config_template/sites /config/sites
else
    log "/config/sites exists, using as-is."
fi

# check if we have a /config/nginx/dhparem.pem file
if [ ! -f "/config/nginx/dhparam.pem" ]; then
    log "/config/nginx/dhparem.pem does not exist, generationg. (this will take awhile)"
    openssl dhparam -out "/config/nginx/dhparam.pem" 2048
    # for stronger security, but may take over 10 minutes to generate 
    # openssl dhparam -out "/config/nginx/dhparam.pem" 4096
else
    log "/config/nginx/dhparem.pem exists, we'll use it."
fi

# if we don't have a letsencrypt dir, then we need to obtain a cert.  Otherwise we just need to try to renew it (the renewal script will check if it's necessary
if [ ! -d "/config/letsencrypt" ]; then
    log "/config/letsencrypt does not exist, obtaining initial certificate..."
    certbot certonly --non-interactive --dns-cloudflare --dns-cloudflare-credentials "/config/cloudflare.ini" --agree-tos --config-dir /config/letsencrypt -d "$DOMAIN" -d "*.$DOMAIN" --cert-name https --email "$EMAIL" 2>&1 | while read line; do log_for_task "CERTBOT" "$line"; done

    # update /config/nginx/http.d/default with the right domain path for the certificate
else
    log "/config/letsencrypt exists, renewing certificate."
    certbot renew --config-dir /config/letsencrypt 2>&1 | while read line; do log_for_task "CERTBOT" "$line"; done
fi



log "starting nginx..."
# run nginx with our config -- daemon off runs in the foreground
nginx -c "/config/nginx/nginx.conf" -g 'daemon off;' 2>&1 | while read line; do log_for_task "NGINX" "$line"; done &
log "started nginx."



log "starting loop to certbot renew every 12h"

while true
do
    sleep 43200 #43200s = 12h
    log "starting certbot renew process"
    certbot renew --config-dir /config/letsencrypt 2>&1 | while read line; do log_for_task "CERTBOT" "$line"; done

    log "signaling nginx to reload configuration"
    nginx -s reload 2>&1 | while read line; do log_for_task "NGINX-RELOAD" "$line"; done
done

# wait for nginx to exit
wait -n

# exit with the same exit code from nginx
exit $?

