#!/bin/bash

# Deploy Elasticsearch Metrics Agents for Remote Monitoring
echo "🚀 Deploying Elasticsearch Metrics Agents for Remote Server"
echo "=========================================================="

# Load configuration
source .env

# Deploy agents only (no local Prometheus/Grafana)
echo "📊 Starting metrics exporters..."
echo "   - Elasticsearch Exporter (HTTPS SSL support)"
echo "   - Node Exporter (System metrics)"
echo "   - cAdvisor (Container metrics)"

docker compose up -d elasticsearch-exporter node-exporter cadvisor

# Wait for services to start
echo "⏳ Waiting for services to initialize..."
sleep 15

# Verify endpoints
echo ""
echo "🔍 Verifying metrics endpoints:"
echo ""

# Test Elasticsearch exporter
echo "1. Testing Elasticsearch Exporter (SSL):"
if curl -s -f "http://100.105.46.41:9114/metrics" | head -5 > /dev/null; then
    echo "   ✅ Elasticsearch metrics available at http://100.105.46.41:9114/metrics"
    echo "      Sample metrics:"
    curl -s "http://100.105.46.41:9114/metrics" | grep "elasticsearch_cluster_health_status" | head -3
else
    echo "   ❌ Elasticsearch exporter not responding"
fi

echo ""

# Test Node exporter
echo "2. Testing Node Exporter:"
if curl -s -f "http://100.105.46.41:9100/metrics" | head -5 > /dev/null; then
    echo "   ✅ Node metrics available at http://100.105.46.41:9100/metrics"
    echo "      Sample metrics:"
    curl -s "http://100.105.46.41:9100/metrics" | grep "node_cpu_seconds_total" | head -2
else
    echo "   ❌ Node exporter not responding"
fi

echo ""

# Test cAdvisor
echo "3. Testing cAdvisor:"
if curl -s -f "http://100.105.46.41:8080/metrics" | head -5 > /dev/null; then
    echo "   ✅ Container metrics available at http://100.105.46.41:8080/metrics"
    echo "      Sample metrics:"
    curl -s "http://100.105.46.41:8080/metrics" | grep "container_memory_usage_bytes" | head -2
else
    echo "   ❌ cAdvisor not responding"
fi

echo ""
echo "📋 Agent Status Summary:"
docker compose ps elasticsearch-exporter node-exporter cadvisor

echo ""
echo "🔗 Remote Prometheus Configuration:"
echo "   Add these endpoints to your remote Prometheus server:"
echo "   - job_name: 'elasticsearch-production'"
echo "     targets: ['100.105.46.41:9114']"
echo "   - job_name: 'elasticsearch-node'"
echo "     targets: ['100.105.46.41:9100']"  
echo "   - job_name: 'elasticsearch-containers'"
echo "     targets: ['100.105.46.41:8080']"

echo ""
echo "📖 Full configuration available in: prometheus-remote-config.yml"
echo ""
echo "✅ Metrics agents deployed successfully for remote monitoring!"