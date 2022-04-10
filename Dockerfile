FROM alpine:latest

COPY entrypoint.sh /
COPY config_template /config_template

RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
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
    

ENTRYPOINT /entrypoint.sh
