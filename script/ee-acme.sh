#!/bin/bash



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
        echo "       -h, --help, help ... displays this help information"
        echo "Examples:"
        echo ""
        echo "domain.tld + www.domain.tld in standalone mode :"
        echo "    ee-acme -d domain.tld --standalone"
        echo ""
        echo "sub.domain.tld in dns mode with Cloudflare"
        echo "    ee-acme -s sub.domain.tld --cf"
        echo ""
        echo "wildcard certificate for domain.tld in dns mode with Cloudflare :"
        echo "    ee-acme -w domain.tld --cf"
        echo ""
        return 0
    }

    if [ ! -f /etc/systemd/system/multi-user.target.wants/nginx.service ]; then
        {
            sudo systemctl enable nginx.service
            sudo systemctl start nginx
        } >>/var/log/ee-acme-sh.log
    fi

    while [[ $# -gt 0 ]]; do
        arg="$1"
        case $arg in
        -d | --domain)
            domain_name=$2
            domain_type=domain
            shift
            ;;
        -s | --subdomain)
            domain_name=$2
            domain_type=subdomain
            shift
            ;;
        -w | --wildcard)
            domain_name=$2
            domain_type=wildcard
            shift
            ;;
        --cf)
            acme_validation=cloudflare
            shift
            ;;
        --standalone)
            acme_validation=standalone
            shift
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

    if [ -z "$domain_name" ]; then
        echo ""
        echo "What is your domain ?: "
        read -r domain_name
        echo ""
    fi

    if [ -z "$acme_validation" ]; then
        echo ""
        echo "Do you want to use standalone mode [1] or dns mode with Cloudflare [2] ?"
        while [[ $acme_choice != "1" && $acme_choice != "2" ]]; do
            read -p "Select an option [1-2]: " acme_choice
        done
    fi
    if [ $acme_choice = "1" ]; then
        acme_validation=standalone
    elif [ $acme_choice = "2" ]; then
        acme_validation=cloudflare
    fi

    if [ ! -f /etc/nginx/sites-available/$domain_name ]; then
        echo "Error: non existant domain"
        exit 1
    fi

    if [ ! -d $HOME/.acme.sh/${domain_name}_ecc ]; then
        if [ $acme_validation = "cloudflare" ]; then
            if [ $domain_type = "domain" ]; then
                $HOME/.acme.sh/acme.sh --issue -d $domain_name -d www.$domain_name --keylength ec-384 --dns dns_cf --dnssleep 60
            elif [ $domain_type = "subdomain" ]; then
                $HOME/.acme.sh/acme.sh --issue -d $domain_name --keylength ec-384 --dns dns_cf --dnssleep 60
            elif [ $domain_type = "wildcard" ]; then
                $HOME/.acme.sh/acme.sh --issue -d $domain_name -d "*.$domain_name" --keylength ec-384 --dns dns_cf --dnssleep 60
            fi
        elif [ $acme_validation = "standalone" ]; then
            sudo apt-get install socat -y
            if [ $domain_type = "domain" ]; then
                $HOME/.acme.sh/acme.sh --issue -d $domain_name -d www.$domain_name --keylength ec-384 --standalone --pre-hook "service nginx stop " --post-hook "service nginx start"
            elif [ $domain_type = "subdomain" ]; then
                $HOME/.acme.sh/acme.sh --issue -d $domain_name --keylength ec-384 --standalone --pre-hook "service nginx stop " --post-hook "service nginx start"
            elif [ $domain_type = "wildcard" ]; then
                echo "standalone mode do not support wildcard certificates"
                exit 1
            fi
        fi
    else
        echo "certificate already exist !"
        exit 1
    fi

    # check if folder already exist
    if [ -d /etc/letsencrypt/live/$domain_name ]; then
        sudo rm -rf /etc/letsencrypt/live/$domain_name/*
    else
        # create folder to store certificate
        sudo mkdir -p /etc/letsencrypt/live/$domain_name
    fi

    # install the cert and reload nginx
    if [ -f $HOME/.acme.sh/${domain_name}_ecc/fullchain.cer ]; then
        $HOME/.acme.sh/acme.sh --install-cert -d ${domain_name} --ecc \
            --cert-file /etc/letsencrypt/live/${domain_name}/cert.pem \
            --key-file /etc/letsencrypt/live/${domain_name}/key.pem \
            --fullchain-file /etc/letsencrypt/live/${domain_name}/fullchain.pem \
            --reloadcmd "sudo systemctl reload nginx.service"
    else
        echo "acme.sh failed to issue certificate"
        exit 1
    fi
    if [ -f /etc/letsencrypt/live/${domain_name}/fullchain.pem ] && [ -f /etc/letsencrypt/live/${domain_name}/key.pem ]; then
        # add certificate to the nginx vhost configuration
        CURRENT=$(nginx -v 2>&1 | awk -F "/" '{print $2}' | grep 1.15)
        if [ -z "$CURRENT" ]; then
            cat <<EOF >/var/www/$domain_name/conf/nginx/ssl.conf
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        ssl on;
        ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
        ssl_certificate_key    /etc/letsencrypt/live/$domain_name/key.pem;
        ssl_trusted_certificate /etc/letsencrypt/live/$domain_name/cert.pem;
EOF
        else
            cat <<EOF >/var/www/$domain_name/conf/nginx/ssl.conf
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
        ssl_certificate_key    /etc/letsencrypt/live/$domain_name/key.pem;
        ssl_trusted_certificate /etc/letsencrypt/live/$domain_name/cert.pem;
EOF

        fi

        # add redirection from http to https
        if [ $domain_type = "domain" ]; then
            cat <<EOF >/etc/nginx/conf.d/force-ssl-$domain_name.conf
server {
    listen 80;
    listen [::]:80;
    server_name $domain_name www.$domain_name;
    return 301 https://$domain_name\$request_uri;
}
EOF
        elif [ $domain_type = "subdomain" ]; then
            cat <<EOF >/etc/nginx/conf.d/force-ssl-$domain_name.conf
server {
    listen 80;
    listen [::]:80;
    server_name $domain_name;
    return 301 https://$domain_name\$request_uri;
}
EOF
        elif [ $domain_type = "wildcard" ]; then
            cat <<EOF >/etc/nginx/conf.d/force-ssl-$domain_name.conf
server {
    listen 80;
    listen [::]:80;
    server_name $domain_name *.$domain_name;
    return 301 https://\$host\$request_uri;
}

EOF
        fi
    else
        echo "acme.sh failed to install certificate"
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
}

alias ee-acme=ee_acme
