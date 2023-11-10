#!/bin/bash

cd "$(dirname "$0")"

CERT_FILE_LOCATION=$PWD/ssl
WEBROOT_LOCATION=$PWD/tmp

function usage() {
cat << _EOT_
Description
  Certificate some domains with certbot
Usage
  cert.sh -d [DOMAINS] -m [MAIL ADDRESS]
Options
  -d                    Domains you want to certificate
                        Example: "your.domain.com", "your.first.domain.com, your.second.domain.com"
  -m                    Your mail address
  --domains-from-config Use server_name as domains defined in conf/*.conf
  -h                    Show this help
Advanced
  Instead of '-d' and '-m', you can specify them with below environment variables
  -d (domains)      -> CERT_DOMAINS
  -m (mail address) -> CERT_MAIL_ADDR
_EOT_
}

DOMAINS=$CERT_DOMAINS
MAIL_ADDR=$CERT_MAIL_ADDR

while getopts "hd:m:-:" OPT; do
  case $OPT in
    -)
      case "${OPTARG}" in
        domains-from-config)
          DOMAINS=$(grep server_name conf/*.conf | awk '{print $NF}' | uniq | sed s/\;// | paste -s -d ' ')
          if [ -z "$DOMAINS" ]; then
            echo "conf/*.conf has no server_name"
            exit 1
          else
            echo "Domains: $DOMAINS"
          fi
          ;;
        *)
          echo "Invalid option: $OPT"
          exit 1
          ;;
      esac
      ;;
    d)
      DOMAINS=$OPTARG
      ;;
    m)
      MAIL_ADDR=$OPTARG
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      echo "Invalid option: $OPT"
      exit 1
      ;;
  esac
done

if [ -z "$DOMAINS" ] || [ -z "$MAIL_ADDR" ]; then
  usage
  exit 1
fi

docker pull certbot/certbot:latest > /dev/null

for DOMAIN in $DOMAINS
do
  docker run -it --rm \
    --name nginx-rp-certbot \
    -v "$CERT_FILE_LOCATION":/etc/letsencrypt \
    -v "$WEBROOT_LOCATION":/webroot/.well-known/acme-challenge \
    certbot/certbot certonly --webroot -w /webroot -d "$DOMAIN" -m "$MAIL_ADDR" --agree-tos --non-interactive
done
