#!/bin/bash

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

clear

# additionals modules choice

echo ""
echo "Welcome to the ee-acme-sh installation."
echo ""

echo "What mode of validation you want to use with  Acme.sh ?"
echo "1) Cloudflare API validation"
echo "2) Standalone mode validation"
echo ""
read -r acmemode 
echo ""

echo "checking if acme.sh is already installed"
if [ ! -f ~/.acme.sh/acme.sh ]; then
echo "installing acme.sh"
wget -O -  https://get.acme.sh | sh
source ~/.bashrc
fi 

if [ "$acmemode" = "1" ]
then
  mkdir -p  ~/.ee-acme.sh
  wget -O ~/.ee-acme.sh/ee-acme https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/master/script/ee-acme-cf
  echo '. "/root/.ee-acme/ee-acme"' >> ~/.bashrc
  source ~/.bashrc
  echo ""
  echo "What is your Cloudflare email address ? :"
  read -r cf_email
  echo "What is your Cloudflare API Key ?" 
  read -r cf_api_key
  export CF_Email="$cf_email"
  export CF_Key="$cf_api_key"
elif [[ "$acmemode" = "2" ]]; then
  wget -O ~/.ee-acme.sh/ee-acme https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/master/script/ee-acme-standalone
  echo '. "/root/.ee-acme/ee-acme"' >> ~/.bashrc
  source ~/.bashrc
  echo "" 
else 
  echo "this option doesn't exist"
  exit 1
fi


# We're done !
echo ""
echo -e "       ${CGREEN}ee-acme-sh was installed successfully !${CEND}"
echo ""
echo "ee-acme-sh usage :"      
echo ""
echo "use one of the following command to install a Let's Encrypt SSL certificate, ee-acme will ask you what domain you want to secure"
echo "ee-acme-www : install a Let's Encrypt SSL certificate on a domain with www alias (yourdomain.tld + www.yourdomain.tld)"
echo "ee-acme-subdomain : install a Let's Encrypt SSL certificate on a subdomain"
echo ""

