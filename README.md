# nginx-certbot-cloudflare

A simple, no fluff container to run NGINX + LetsEncrypt/Certbot as rootless container.  

Only tested with podman, but it should work with Docker. 

## why

Several great exisitng solutions exist, such as linuxserver.io "SWAG" and nginx-proxy-manager, but all of these
introduce a significant number of additional moving pieces that I do not find necessary for my use.  

I scripted this simple container up to be very minimal, but configurable enough. 

## configuration

### required enviroment variables:

`DOMAIN` - your domain. Can (should?) be wildcard.  e.g, *.yourdomain.com
`EMAIL` - your email address.  Used with certbot to obtain the HTTPS certificate.

### required volume

You must map a volume to /config within the container.  If this volume is empty on first run, the container will populate it with basic configuration.  

### cloudflare configuration

/config/cloudflare.ini must be populated with your authorized cloudflare token to allow certbot to update the dns challenge entries. An example /config/cloudflare.ini.example file will be written on first run if one does not exist. Update and rename it, and re-start the container.

## running
```
#!/bin/sh
podman run \
    -d \
    -e DOMAIN="*.yourdomain.com" \
    -e EMAIL="you@example.com" \
    -p 8443:443 \
    -v ./config:/config \
    nginx-certbot-cloudflare
```



