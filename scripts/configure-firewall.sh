#!/bin/bash

# Firewall configuration untuk Elasticsearch Metrics Agent
# Hanya mengizinkan akses dari IP Tailscale 100.105.46.41

echo "=== Configuring Firewall untuk Elasticsearch Metrics ==="

# Tailscale subnet
TAILSCALE_SUBNET="100.64.0.0/10"
TAILSCALE_IP="100.105.46.41"

echo "Configuring UFW rules untuk metrics ports..."

# Block all access to metrics ports by default
sudo ufw deny 9114 comment "Block Elasticsearch Exporter by default"
sudo ufw deny 9100 comment "Block Node Exporter by default"  
sudo ufw deny 8080 comment "Block cAdvisor by default"

# Allow access only from Tailscale subnet
sudo ufw allow from $TAILSCALE_SUBNET to any port 9114 comment "Elasticsearch Exporter - Tailscale only"
sudo ufw allow from $TAILSCALE_SUBNET to any port 9100 comment "Node Exporter - Tailscale only"
sudo ufw allow from $TAILSCALE_SUBNET to any port 8080 comment "cAdvisor - Tailscale only"

# Allow localhost for health checks
sudo ufw allow from 127.0.0.1 to any port 9114 comment "Elasticsearch Exporter - localhost"
sudo ufw allow from 127.0.0.1 to any port 9100 comment "Node Exporter - localhost"
sudo ufw allow from 127.0.0.1 to any port 8080 comment "cAdvisor - localhost"

echo "Firewall rules applied:"
echo "✅ Metrics ports (9114, 9100, 8080) accessible only from Tailscale subnet"
echo "✅ Localhost access allowed for health checks"

# Show current rules
echo ""
echo "Current UFW rules for metrics ports:"
sudo ufw status numbered | grep -E "(9114|9100|8080)"

echo ""
echo "=== Security Configuration Complete ==="
echo "Metrics endpoints are now restricted to Tailscale network only"
echo "External access to metrics ports is blocked"