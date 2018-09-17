#!/bin/bash

clear

# Colors
CSI="\\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"

# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

# install acme.sh if needed
echo ""
echo "checking if acme.sh is already installed"
echo ""
if [ ! -f ~/.acme.sh/acme.sh ]; then
    echo ""
    echo "installing acme.sh"
    echo ""
    wget -O -  https://get.acme.sh | sh
fi


# ACME validation choice

echo ""
echo "Welcome to the ee-acme-sh installation."
echo ""


# install ee-acme-cf or ee-acme-standalone
mkdir -p  ~/.ee-acme
if [ "$acmemode" = "1" ]
then
    wget -O ~/.ee-acme/ee-acme https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/master/script/ee-acme-cf
    cd || exit
    echo '. "/root/.ee-acme/ee-acme"' >> .bashrc
    source .bashrc
    echo ""
    echo "What is your Cloudflare email address ? :"
    echo ""
    read -r cf_email
    echo "What is your Cloudflare API Key ? You API Key is available on https://www.cloudflare.com/a/profile"
    read -r cf_api_key

    echo "SAVED_CF_Key='$cf_api_key'" >> .acme.sh/account.conf
    echo "SAVED_CF_Email='$cf_email'" >> .acme.sh/account.conf

    elif [[ "$acmemode" = "2" ]]; then
    wget -O ~/.ee-acme/ee-acme https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/master/script/ee-acme-standalone
    echo "alias ee-acme="/root/.ee-acme/ee-acme.sh""
    echo '. "/root/.ee-acme/ee-acme"' >> .bashrc
    source .bashrc
    echo ""
else
    echo "this option doesn't exist"
    exit 1
fi

# We're done !
echo ""
echo -e "       ${CGREEN}ee-acme-sh was installed successfully !${CEND}"
echo ""
echo "You have to run the following command  to enable ee-acme-sh"
echo ""
echo -e "     ${CGREEN}source .bashrc${CEND}"
echo ""
echo ""
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




