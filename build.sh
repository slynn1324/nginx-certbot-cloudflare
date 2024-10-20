#!/bin/sh
podman pull alpine:latest
podman build --no-cache -t nginx-certbot-cloudflare .
