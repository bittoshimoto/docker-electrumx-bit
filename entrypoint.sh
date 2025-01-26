#!/bin/bash

# Check if SSL certificate and key exist, generate them if not
if [ ! -e "${SSL_CERTFILE}" ] || [ ! -e "${SSL_KEYFILE}" ]; then
  openssl req -newkey rsa:2048 -sha256 -nodes -x509 -days 365 -subj "/O=ElectrumX" -keyout "${SSL_KEYFILE}" -out "${SSL_CERTFILE}"
fi

# Function to get the public IP of the server
get_public_ip() {
  # Use any reliable service to fetch the public IP
  curl -s ifconfig.me || curl -s icanhazip.com
}

# Fetch the public IP
PUBLIC_IP=$(get_public_ip)

if [ -z "$PUBLIC_IP" ]; then
  echo "Error: Unable to fetch the public IP address. Exiting."
  exit 1
fi

echo "Detected public IP: $PUBLIC_IP"

# Dynamically update the REPORT_SERVICES environment variable
export REPORT_SERVICES="tcp://${PUBLIC_IP}:50001,ssl://${PUBLIC_IP}:50002,wss://${PUBLIC_IP}:50004"

echo "REPORT_SERVICES set to: $REPORT_SERVICES"

# Start the Bit daemon
bitd -conf=/root/.bit/bit.conf -datadir=/data &

# Start the ElectrumX server
exec /root/electrumx-bit/electrumx_server
