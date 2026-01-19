#!/bin/bash

# Récupération des IPs
ip_privee=$(hostname -I | awk '{print $1}')
ip_publique_v4=$(curl -s https://ipv4.icanhazip.com)
ip_publique_v6=$(curl -s https://ipv6.icanhazip.com)

# Affichage formaté
echo "IP Privé IPV4 : $ip_privee"
echo "IP Public IPV4 : $ip_publique_v4"
echo "IP Public IPV6 : $ip_publique_v6"

