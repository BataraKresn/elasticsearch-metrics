#!/bin/bash

# Setup script untuk Elasticsearch Metrics Agents (Updated for SSL)
echo "=== Elasticsearch Metrics Agent Setup (SSL Support) ==="

# Check if Elasticsearch is accessible via HTTP
ES_URL="http://elastic:K4a8ep8sMJMu4YxD@100.105.46.41:9200"

echo "Checking Elasticsearch HTTP connectivity..."
if curl -s -f "$ES_URL/_cluster/health" > /dev/null; then
    echo "✅ Elasticsearch HTTP is accessible at http://100.105.46.41:9200"
    curl -s -u elastic:K4a8ep8sMJMu4YxD "$ES_URL/_cluster/health?pretty" | grep -E "(cluster_name|status|number_of_nodes)"
else
    echo "❌ Cannot connect to Elasticsearch HTTP at http://100.105.46.41:9200"
    echo "Please ensure:"
    echo "  1. Elasticsearch cluster is running"
    echo "  2. HTTP access is configured"
    echo "  3. Firewall allows HTTP access from this IP"
    echo "  4. Credentials are correct"
    exit 1
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p logs

# Configure firewall for Tailscale-only access
echo "Configuring firewall for Tailscale-only access..."
./scripts/configure-firewall.sh

# Start metrics agents
echo "Starting metrics agents..."
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 10

# Check if exporters are running
echo "Checking exporter status..."

# Check Elasticsearch Exporter
if curl -s http://100.105.46.41:9114/metrics | head -5 > /dev/null; then
    echo "✅ Elasticsearch Exporter is running on port 9114"
else
    echo "❌ Elasticsearch Exporter failed to start"
fi

# Check Node Exporter
if curl -s http://100.105.46.41:9100/metrics | head -5 > /dev/null; then
    echo "✅ Node Exporter is running on port 9100"
else
    echo "❌ Node Exporter failed to start"
fi

# Check cAdvisor
if curl -s http://100.105.46.41:8080/metrics | head -5 > /dev/null; then
    echo "✅ cAdvisor is running on port 8080"
else
    echo "❌ cAdvisor failed to start"
fi

echo ""
echo "=== Setup Complete ==="
echo "Metrics endpoints available:"
echo "  📊 Elasticsearch Exporter: http://100.105.46.41:9114/metrics"
echo "  🖥️  Node Exporter:          http://100.105.46.41:9100/metrics"
echo "  🐳 cAdvisor:               http://100.105.46.41:8080/metrics"
echo ""
echo "Add these targets to your Prometheus configuration:"
echo "  - 100.105.46.41:9114 (elasticsearch metrics)"
echo "  - 100.105.46.41:9100 (system metrics)" 
echo "  - 100.105.46.41:8080 (container metrics)"
echo ""
echo "Example Prometheus scrape config available in: prometheus.yml"
echo "Grafana dashboard available in: grafana/elasticsearch-dashboard.json"