# wo-acme-sh

## Bash script to install Let's Encrypt SSL certificates automatically using acme.sh on servers running with WordOps, developed by [Virtubox](https://virtubox.net) for EasyEngine and forked to WordOps.

![ee-acme-sh](https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/master/ee-acme.png)

## Features

- Automated Installation of Let's Encrypt SSL certificates using [acme.sh](http://acme.sh)
- Acme validation with standalone mode or Cloudflare DNS API
- Domain, Subdomain & Wildcard SSL Certificates support
- IPv6 Support
- Generate ECDSA Certificates with ECC 384 Bits private key
- Automated Certificates Renewal
- Nginx mainline & stable release support
- Cert-only mode available

## Installation

```bash
bash <(wget -qO - https://raw.githubusercontent.com/VirtuBox/ee-acme-sh/master/install.sh)

# enable acme.sh & ee-acme-sh
source .bashrc
```

## Update script

Just run the installation command again

## Usage

```bash
Usage: ee-acme [type] <domain> [mode]
  Types:
       -d, --domain <domain_name> ..... for domain.tld + www.domain.tld
       -s, --subdomain <subdomain_name> ....... for sub.domain.tld
       -w, --wildcard <domain_name> ..... for domain.tld + *.domain.tld
  Modes:
       --standalone ..... acme challenge in standalone mode
       --cf ..... acme challenge in dns mode with Cloudflare
  Options:
       --cert-only ... do not change nginx configuration, only display it
       --admin ... secure easyengine backend with the certificate
       -h, --help, help ... displays this help information
Examples:

domain.tld + www.domain.tld in standalone mode :
    ee-acme -d domain.tld --standalone

sub.domain.tld in dns mode with Cloudflare :
    ee-acme -s sub.domain.tld --cf

wildcard certificate for domain.tld in dns mode with Cloudflare :
    ee-acme -w domain.tld --cf

domain.tld + www.domain.tld in standalone mode without editing Nginx configuration :
    ee-acme -d domain.tld --standalone --cert-only

sub.domain.tld in standalone mode to secure easyengine backend on port 22222 :
    ee-acme -s sub.domain.tld --standalone --admin
```

## Limitations

- Wildcard certs are only available with Cloudflare DNS API
