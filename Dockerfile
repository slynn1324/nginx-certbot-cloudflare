FROM alpine:latest

COPY entrypoint.sh /
COPY config_template /config_template

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    curl \
	python3 \
    python3-dev \
    musl-dev \
    libffi \
    libffi-dev \
    gcc \
    nginx \
    openssl \
    && \
    python3 -m venv /opt/certbot && \
    /opt/certbot/bin/pip install --upgrade pip && \
    /opt/certbot/bin/pip install certbot && \
    ln -s /opt/certbot/bin/certbot /usr/bin/certbot && \
    /opt/certbot/bin/pip install certbot-dns-cloudflare && \
    chmod +x /entrypoint.sh && \
    apk del musl-dev gcc

RUN rm -r /etc/nginx && ln -s /config/nginx /etc/nginx

RUN mkdir /usr/local/sbin && \
	wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker && \
	wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/setup-ngxblocker -O /usr/local/sbin/setup-ngxblocker && \
	wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/update-ngxblocker -O /usr/local/sbin/update-ngxblocker && \
	chmod +x /usr/local/sbin/*-ngxblocker
	
ENTRYPOINT /entrypoint.sh
