#!/bin/bash

# Monitoring script untuk metrics agents
source .env

echo "=== Elasticsearch Metrics Agent Status ==="
echo "Timestamp: $(date)"
echo ""

# Check Docker containers
echo "1. CONTAINER STATUS"
echo "==================="
docker-compose ps

echo ""
echo "2. EXPORTER ENDPOINTS"
echo "===================="

# Test Elasticsearch Exporter
echo "Testing Elasticsearch Exporter (port 9114)..."
if curl -s -o /dev/null -w "%{http_code}" http://100.105.46.41:9114/metrics | grep -q "200"; then
    echo "✅ Elasticsearch Exporter: OK"
    METRICS_COUNT=$(curl -s http://100.105.46.41:9114/metrics | grep "^elasticsearch_" | wc -l)
    echo "   📊 Metrics available: $METRICS_COUNT"
else
    echo "❌ Elasticsearch Exporter: FAILED"
fi

# Test Node Exporter
echo "Testing Node Exporter (port 9100)..."
if curl -s -o /dev/null -w "%{http_code}" http://100.105.46.41:9100/metrics | grep -q "200"; then
    echo "✅ Node Exporter: OK"
    METRICS_COUNT=$(curl -s http://100.105.46.41:9100/metrics | grep "^node_" | wc -l)
    echo "   📊 Metrics available: $METRICS_COUNT"
else
    echo "❌ Node Exporter: FAILED"
fi

# Test cAdvisor
echo "Testing cAdvisor (port 8080)..."
if curl -s -o /dev/null -w "%{http_code}" http://100.105.46.41:8080/metrics | grep -q "200"; then
    echo "✅ cAdvisor: OK" 
    METRICS_COUNT=$(curl -s http://100.105.46.41:8080/metrics | grep "^container_" | wc -l)
    echo "   📊 Metrics available: $METRICS_COUNT"
else
    echo "❌ cAdvisor: FAILED"
fi

echo ""
echo "3. ELASTICSEARCH CONNECTIVITY"
echo "============================="
ES_URL="http://elastic:${ES_PASSWORD}@${ES_HOST}:${ES_PORT}"

if curl -s -u "elastic:${ES_PASSWORD}" "http://${ES_HOST}:${ES_PORT}/_cluster/health" > /dev/null; then
    CLUSTER_STATUS=$(curl -s -u "elastic:${ES_PASSWORD}" "http://${ES_HOST}:${ES_PORT}/_cluster/health" | jq -r '.status')
    NODE_COUNT=$(curl -s -u "elastic:${ES_PASSWORD}" "http://${ES_HOST}:${ES_PORT}/_cluster/health" | jq -r '.number_of_nodes')
    echo "✅ Elasticsearch Connection: OK"
    echo "   🏥 Cluster Status: $CLUSTER_STATUS"
    echo "   🖥️  Active Nodes: $NODE_COUNT"
else
    echo "❌ Elasticsearch Connection: FAILED"
fi

echo ""
echo "4. SYSTEM RESOURCES"
echo "=================="
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
echo "Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
echo "Disk Usage (/data): $(df -h /data | awk 'NR==2 {print $5}')"
echo "Disk Usage (/): $(df -h / | awk 'NR==2 {print $5}')"

echo ""
echo "5. NETWORK CONNECTIVITY"
echo "======================"
echo "Tailscale IP: ${TAILSCALE_IP}"
ping -c 1 ${TAILSCALE_IP} > /dev/null 2>&1 && echo "✅ Tailscale connectivity: OK" || echo "❌ Tailscale connectivity: FAILED"

echo ""
echo "6. RECENT LOGS (Last 10 lines)"
echo "=============================="
echo "Elasticsearch Exporter logs:"
docker-compose logs --tail=5 elasticsearch-exporter 2>/dev/null || echo "No logs available"

echo ""
echo "=== Metrics Endpoints for Prometheus ==="
echo "elasticsearch_exporter: http://${TAILSCALE_IP}:9114/metrics"
echo "node_exporter:          http://${TAILSCALE_IP}:9100/metrics"
echo "cadvisor:              http://${TAILSCALE_IP}:8080/metrics"