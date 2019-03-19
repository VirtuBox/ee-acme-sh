#!/bin/bash
# ----------------------------------------------------------------------------
# EE-ACME-SH -  Automated SSL certificate setup for EasyEngine with acme.sh
# ----------------------------------------------------------------------------
# Website:       https://virtubox.net
# GitHub:        https://github.com/VirtuBox/ee-acme-sh
# Author:        VirtuBox
# License:       M.I.T
# ----------------------------------------------------------------------------
# Version 2.1 - 2019-01-28
# ----------------------------------------------------------------------------


# install acme.sh if needed
[ ! -f $HOME/.acme.sh/acme.sh ] && {
    wget -O - https://get.acme.sh | sh
}

# install dig if needed
[ ! -x /usr/bin/dig ] && {
    apt-get install bind9-host -y
}

# find curl binary path
CURL_BIN="$(command -v curl)"

# install curl if needed
[ -z "$CURL_BIN" ] && {
    apt-get install curl -y >>/dev/null
}

# install socat if needed
[ ! -x /usr/bin/socat ] && {
    apt-get install socat -y >>/dev/null
}

_help() {
    echo "Issue and install SSL certificates using acme.sh with EasyEngine"
    echo "Usage: ee-acme [type] <domain> [mode]"
    echo "  Types:"
    echo "       -d, --domain <domain_name> ..... for domain.tld + www.domain.tld"
    echo "       -s, --subdomain <subdomain_name> ....... for sub.domain.tld"
    echo "       -w, --wildcard <domain_name> ..... for domain.tld + *.domain.tld"
    echo "  Modes:"
    echo "       --standalone ..... acme challenge in standalone mode"
    echo "       --cf ..... acme challenge in dns mode with Cloudflare"
    echo "  Options:"
    echo "       --cert-only ... do not change nginx configuration, only display it"
    echo "       --admin ... secure easyengine backend with the certificate"
    echo "       -h, --help, help ... displays this help information"
    echo "Examples:"
    echo ""
    echo "domain.tld + www.domain.tld in standalone mode :"
    echo "    ee-acme -d domain.tld --standalone"
    echo ""
    echo "sub.domain.tld in dns mode with Cloudflare :"
    echo "    ee-acme -s sub.domain.tld --cf"
    echo ""
    echo "wildcard certificate for domain.tld in dns mode with Cloudflare :"
    echo "    ee-acme -w domain.tld --cf"
    echo ""
    echo "domain.tld + www.domain.tld in standalone mode without editing Nginx configuration :"
    echo "    ee-acme -d domain.tld --standalone --cert-only"
    echo ""
    echo "sub.domain.tld in standalone mode to secure easyengine backend on port 22222 :"
    echo "    ee-acme -s sub.domain.tld --standalone --admin"
    echo ""
    return 0
}

if [ "${#}" = "0" ]; then
    _help
    exit 1
else

    while [ "${#}" -gt 0 ]; do
        case "${1}" in
            -d | --domain)
                domain_name="$2"
                domain_type=domain
                shift
            ;;
            -s | --subdomain)
                domain_name="$2"
                domain_type=subdomain
                shift
            ;;
            -w | --wildcard)
                domain_name="$2"
                domain_type=wildcard
                shift
            ;;
            --cf)
                acme_validation=cloudflare
            ;;
            --standalone)
                acme_validation=standalone
            ;;
            --cert-only)
                cert_only="1"
            ;;
            --admin)
                easyengine_backend="1"
            ;;
            -h | --help | help)
                _help
                exit 1
            ;;
            *) # positional args
            ;;
        esac
        shift
    done
fi

if [ -z "$domain_name" ]; then
    echo ""
    echo "What is your domain ?: "
    read -r domain_name
    echo ""
fi


if [ -z "$acme_validation" ]; then
    echo ""
    echo "Do you want to use standalone mode [1] or dns mode with Cloudflare [2] ?"
    while [[ "$acme_choice" != "1" && "$acme_choice" != "2" ]]; do
        read -p "Select an option [1-2]: " acme_choice
    done
fi
if [ "$acme_choice" = "1" ]; then
    acme_validation=standalone
    elif [ "$acme_choice" = "2" ]; then
    acme_validation=cloudflare
fi

if [ ! -f /etc/nginx/sites-available/${domain_name} ] && [ -z "$cert_only" ] && [ -z "$easyengine_backend" ]; then
    echo "####################################"
    echo "Error : Nginx vhost doesn't exist"
    echo "####################################"
    exit 1
fi

CF_ACME_ACCOUNT_CHECK=$(grep "CF" $HOME/.acme.sh/account.conf)

if [ "$acme_validation" = "cloudflare" ] && [ -z "$CF_ACME_ACCOUNT_CHECK" ]; then
    echo ""
    echo "What is your Cloudflare email address ? :"
    echo ""
    read -r cf_email
    echo "What is your Cloudflare API Key ? You API Key is available on https://www.cloudflare.com/a/profile"
    read -r cf_api_key

    echo "SAVED_CF_Key='$cf_api_key'" >>$HOME/.acme.sh/account.conf
    echo "SAVED_CF_Email='$cf_email'" >>$HOME/.acme.sh/account.conf
fi




if [ ! -d $HOME/.acme.sh/${domain_name}_ecc ] || [ ! -f /etc/letsencrypt/live/${domain_name}/fullchain.pem ]; then
    if [ "$acme_validation" = "cloudflare" ]; then
        if [ "$domain_type" = "domain" ]; then
            $HOME/.acme.sh/acme.sh --issue -d "$domain_name" -d www.${domain_name} -k ec-384 --dns dns_cf 
            elif [ "$domain_type" = "subdomain" ]; then
            $HOME/.acme.sh/acme.sh --issue -d "$domain_name" -k ec-384 --dns dns_cf 
            elif [ "$domain_type" = "wildcard" ]; then
            $HOME/.acme.sh/acme.sh --issue -d "$domain_name" -d \*.${domain_name} -k ec-384 --dns dns_cf 
        fi
        elif [ "$acme_validation" = "standalone" ]; then
        SERVER_PUBLIC_IP=$("$CURL_BIN" -s https://v4.vtbox.net)
        DOMAIN_IP=$(/usr/bin/dig +short @8.8.8.8 "$domain_name")
        if [ "$SERVER_PUBLIC_IP" = "$DOMAIN_IP" ]; then
            if [ $domain_type = "domain" ]; then
                $HOME/.acme.sh/acme.sh --issue -d "$domain_name" -d www.${domain_name} -k ec-384 --standalone --pre-hook "service nginx stop " --post-hook "service nginx start"
                elif [ "$domain_type" = "subdomain" ]; then
                $HOME/.acme.sh/acme.sh --issue -d "$domain_name" -k ec-384 --standalone --pre-hook "service nginx stop " --post-hook "service nginx start"
                elif [ "$domain_type" = "wildcard" ]; then
                echo "standalone mode do not support wildcard certificates"
                exit 1
            fi
        else
            echo "####################################"
            echo "Error : domain do not resolve server IP"
            echo "####################################"
            exit 1
        fi
    fi
else
    echo "####################################"
    echo "Certificate Already Exist"
    echo "####################################"
    exit 1
fi
if [ -f $HOME/.acme.sh/${domain_name}_ecc/fullchain.cer ]; then
    # check if folder already exist
    if [ -d /etc/letsencrypt/live/${domain_name} ]; then
        sudo rm -rf /etc/letsencrypt/live/${domain_name}/*
    else
        # create folder to store certificate
        sudo mkdir -p /etc/letsencrypt/live/${domain_name}
    fi

    # install the cert and reload nginx

    $HOME/.acme.sh/acme.sh --install-cert -d "$domain_name" --ecc \
    --cert-file /etc/letsencrypt/live/${domain_name}/cert.pem \
    --key-file /etc/letsencrypt/live/${domain_name}/key.pem \
    --fullchain-file /etc/letsencrypt/live/${domain_name}/fullchain.pem \
    --reloadcmd "service nginx restart"
else
    echo "####################################"
    echo "Acme.sh failed to issue certificate"
    echo "####################################"
    exit 1
fi
if [ ! -d /var/www/${domain_name}/conf/nginx ] && [ -z "$easyengine_backend" ]; then
    cert_only=1
fi
if [ -z "$cert_only" ] && [ -z "$easyengine_backend" ]; then
    if [ -f /etc/letsencrypt/live/${domain_name}/fullchain.pem ] && [ -f /etc/letsencrypt/live/${domain_name}/key.pem ]; then
        # add certificate to the nginx vhost configuration
        CURRENT=$(/usr/sbin/nginx -v 2>&1 | awk -F "/" '{print $2}' | grep 1.15)
        if [ -z "$CURRENT" ]; then
            cat <<EOF >/var/www/${domain_name}/conf/nginx/ssl.conf
        # SSL configuration added by ee-acme-sh
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        ssl on;
        ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
        ssl_certificate_key    /etc/letsencrypt/live/${domain_name}/key.pem;
        ssl_trusted_certificate /etc/letsencrypt/live/${domain_name}/cert.pem;
EOF
        else
            cat <<EOF >/var/www/${domain_name}/conf/nginx/ssl.conf
        # SSL configuration added by ee-acme-sh
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
        ssl_certificate_key    /etc/letsencrypt/live/${domain_name}/key.pem;
        ssl_trusted_certificate /etc/letsencrypt/live/${domain_name}/cert.pem;
EOF

        fi

        # add redirection from http to https
        if [ "$domain_type" = "domain" ]; then
            cat <<EOF >/etc/nginx/conf.d/force-ssl-${domain_name}.conf
server {
    # SSL redirection added by ee-acme-sh
    listen 80;
    listen [::]:80;
    server_name ${domain_name} www.${domain_name};
    return 301 https://${domain_name}\$request_uri;
}
EOF
            elif [ "$domain_type" = "subdomain" ]; then
            cat <<EOF >/etc/nginx/conf.d/force-ssl-${domain_name}.conf
server {
    # SSL redirection added by ee-acme-sh
    listen 80;
    listen [::]:80;
    server_name ${domain_name};
    return 301 https://${domain_name}\$request_uri;
}
EOF
            elif [ "$domain_type" = "wildcard" ]; then
            cat <<EOF >/etc/nginx/conf.d/force-ssl-${domain_name}.conf
server {
    # SSL redirection added by ee-acme-sh
    listen 80;
    listen [::]:80;
    server_name ${domain_name} *.${domain_name};
    return 301 https://\$host\$request_uri;
}

EOF
        fi
    else
        echo "####################################"
        echo "acme.sh failed to install certificate"
        echo "####################################"
        exit 1
    fi
    VERIFY_NGINX_CONFIG=$(nginx -t 2>&1 | grep failed)
    if [ -z "$VERIFY_NGINX_CONFIG" ]; then
        echo "####################################"
        echo "Reloading Nginx"
        echo "####################################"
        sudo service nginx reload
    else
        echo "####################################"
        echo "Nginx configuration is not correct"
        echo "####################################"
    fi
    elif [ "$easyengine_backend" = "1" ]; then

    if [ -f /etc/letsencrypt/live/${domain_name}/fullchain.pem ] && [ -f /etc/letsencrypt/live/${domain_name}/key.pem ]; then
        sed -i "s/ssl_certificate \/var\/www\/22222\/cert\/22222.crt;/ssl_certificate \/etc\/letsencrypt\/live\/${domain_name}\/fullchain.pem;/" /etc/nginx/sites-available/22222
        sed -i "s/ssl_certificate_key \/var\/www\/22222\/cert\/22222.key;/ssl_certificate_key    \/etc\/letsencrypt\/live\/${domain_name}\/key.pem;/" /etc/nginx/sites-available/22222
    fi
    VERIFY_NGINX_CONFIG=$(nginx -t 2>&1 | grep failed)
    if [ -z "$VERIFY_NGINX_CONFIG" ]; then
        echo "####################################"
        echo "Reloading Nginx"
        echo "####################################"
        sudo service nginx reload
    else
        echo "####################################"
        echo "Nginx configuration is not correct"
        echo "####################################"
    fi
else
    if [ -f /etc/letsencrypt/live/${domain_name}/fullchain.pem ] && [ -f /etc/letsencrypt/live/${domain_name}/key.pem ]; then
        # add certificate to the nginx vhost configuration
        CURRENT=$(nginx -v 2>&1 | awk -F "/" '{print $2}' | grep 1.15)
        if [ -z "$CURRENT" ]; then
            echo "###### Nginx configuration"
            echo ""
            echo "  listen 443 ssl http2;"
            echo "  listen [::]:443 ssl http2;"
            echo "  ssl on;"
            echo "  ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;"
            echo "  ssl_certificate_key    /etc/letsencrypt/live/${domain_name}/key.pem;"
            echo "  ssl_trusted_certificate /etc/letsencrypt/live/${domain_name}/cert.pem;"
            echo ""
        else
            echo "###### Nginx configuration"
            echo ""
            echo "  listen 443 ssl http2;"
            echo "  listen [::]:443 ssl http2;"
            echo "  ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;"
            echo "  ssl_certificate_key    /etc/letsencrypt/live/${domain_name}/key.pem;"
            echo "  ssl_trusted_certificate /etc/letsencrypt/live/${domain_name}/cert.pem;"
            echo ""

        fi
    else
        echo "####################################"
        echo "acme.sh failed to install certificate"
        echo "####################################"
        exit 1
    fi
fi
