#!/bin/bash
# Simple test script for Pi-hole Docker stack

PIHOLE_IP="${1:-127.0.0.1}"
PIHOLE_PORT="${2:-80}"

echo "Testing Pi-hole web interface at http://${PIHOLE_IP}:${PIHOLE_PORT}/admin/"
curl -s -o /dev/null -w "%{http_code}\n" "http://${PIHOLE_IP}:${PIHOLE_PORT}/admin/" | grep -q "200" && \
    echo "Web interface reachable." || echo "Web interface not reachable!"

echo "Testing DNS resolution via Pi-hole (google.com)..."
dig @${PIHOLE_IP} google.com +short | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' && \
    echo "DNS resolution works." || echo "DNS resolution failed!"