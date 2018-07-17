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
source .bashrc
fi


# ACME validation choice

echo ""
echo "Welcome to the ee-acme-sh installation."
echo ""

echo "What mode of validation you want to use with  Acme.sh ?"
echo "1) Cloudflare API validation (domain/subdomain/wildcard certs)"
echo "2) Standalone mode validation (domain/subdomain certs)"
while [[ $acmemode != "1" && $acmemode != "2" ]]; do
	read -r "Select an option [1-2]: " acmemode
done
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
echo "       ee-acme-sh usage :"
echo ""
if [ "$acmemode" = "1" ]
then
  echo "               ee-acme-domain : install Let's Encrypt SSL certificate on domain.tld + www.domain.tld"
  echo ""
  echo "               ee-acme-subdomain : install Let's Encrypt SSL certificate on sub.domain.tld "
  echo ""
  echo "               ee-acme-wildcard : install Let's Encrypt SSL certificate on domain.tld + *.domain.tld"
  echo ""
else
  echo "                ee-acme-domain : install Let's Encrypt SSL certificate on domain.tld + www.domain.tld"
  echo ""
  echo "                ee-acme-subdomain : install Let's Encrypt SSL certificate on sub.domain.tld"
  echo ""
fi


