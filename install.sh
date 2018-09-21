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
if [ -d $HOME/.ee-acme ]; then
    rm -rf $HOME/.ee-acme/*
    echo 'alias ee-acme="/root/.ee-acme/ee-acme.sh"' >> $HOME/.ee-acme/ee-acme
    wget -O $HOME/.ee-acme/ee-acme.sh https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/master/script/ee-acme.sh
    chmod +x $HOME/.ee-acme/ee-acme.sh
else
    mkdir -p  $HOME/.ee-acme
    wget -O $HOME/.ee-acme/ee-acme.sh https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/master/script/ee-acme.sh
    chmod +x $HOME/.ee-acme/ee-acme.sh
    echo 'alias ee-acme="/root/.ee-acme/ee-acme.sh"' >> $HOME/.bashrc
fi


# We're done !
echo ""
echo -e "     ${CGREEN}ee-acme-sh was installed successfully !${CEND}"
echo ""
echo "You need to run the following command to enable ee-acme-sh"
echo ""
echo -e "     ${CGREEN}source .bashrc${CEND}"
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
echo "       --cert-only ... do not change nginx configuration, only display it"
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




