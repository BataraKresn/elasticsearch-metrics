# Prometheus Configuration Guide for Elasticsearch Metrics

## Overview
Konfigurasi `prometheus.yml` telah dioptimalkan untuk mengumpulkan metrics dari Elasticsearch cluster melalui internal Docker network dengan fallback ke external Tailscale access.

## Scrape Jobs Configuration

### 1. Elasticsearch Cluster Metrics
```yaml
- job_name: 'elasticsearch-cluster'
  static_configs:
    - targets: ['elasticsearch-exporter:9114']
```
**Metrics yang dikumpulkan:**
- Cluster health status (GREEN/YELLOW/RED)
- Node status dan availability  
- Index metrics (dokumen count, storage size)
- Query performance (search latency, throughput)
- JVM heap usage dan garbage collection
- Segment counts dan merges

**Endpoint Access:** Internal network `elasticsearch-exporter:9114`

### 2. System/Node Metrics
```yaml
- job_name: 'system-metrics'
  static_configs:
    - targets: ['node-exporter-es:9100']
```
**Metrics yang dikumpulkan:**
- CPU usage (user, system, idle)
- Memory utilization (used, available, cached)
- Disk I/O (read/write operations, latency)
- Network traffic (bytes in/out, errors)
- File system usage dan mount points
- System load average

**Endpoint Access:** Internal network `node-exporter-es:9100`

### 3. Container Metrics
```yaml
- job_name: 'container-metrics'
  static_configs:
    - targets: ['cadvisor-es:8080']
```
**Metrics yang dikumpulkan:**
- Container CPU usage per service
- Container memory consumption
- Container network I/O
- Container filesystem usage
- Docker container status dan restart counts
- Resource limits vs usage

**Endpoint Access:** Internal network `cadvisor-es:8080`

### 4. External Access (Backup)
```yaml
- job_name: 'elasticsearch-external'
  static_configs:
    - targets: 
      - '100.105.46.41:9114'  # Elasticsearch Exporter
      - '100.105.46.41:9100'  # Node Exporter  
      - '100.105.46.41:8080'  # cAdvisor
```
**Purpose:** Backup access method menggunakan Tailscale IP untuk external Prometheus servers.

## Labels & Relabeling

### Global Labels
```yaml
external_labels:
  cluster: 'elasticsearch-production'
  datacenter: 'tailscale-network'  
  environment: 'production'
```

### Service-specific Labels
- **elasticsearch-cluster:** `service=elasticsearch`, `cluster_name=elastic-production`
- **system-metrics:** `service=system`, `instance_type=elasticsearch-host`
- **container-metrics:** `service=containers`, `component=docker`

## Key Metrics untuk Monitoring

### Elasticsearch Health
```
elasticsearch_cluster_health_status
elasticsearch_cluster_health_number_of_nodes
elasticsearch_cluster_health_active_primary_shards
elasticsearch_indices_docs_total
```

### System Performance  
```
node_cpu_seconds_total
node_memory_MemAvailable_bytes
node_disk_io_now
node_network_receive_bytes_total
```

### Container Resources
```
container_memory_usage_bytes
container_cpu_usage_seconds_total  
container_network_receive_bytes_total
container_fs_usage_bytes
```

## Remote Write Configuration

Untuk external Prometheus servers:
```yaml
remote_write:
  - url: "https://your-external-prometheus/api/v1/write"
    basic_auth:
      username: "prometheus"
      password: "your-password"
```

## Firewall Requirements

**Internal Network (elasticsearch-network):**
- Port 9114: elasticsearch-exporter metrics
- Port 9100: node-exporter metrics
- Port 8080: cAdvisor metrics

**External Access (Tailscale):**
- 100.105.46.41:9114 → elasticsearch-exporter
- 100.105.46.41:9100 → node-exporter
- 100.105.46.41:8080 → cAdvisor

## Usage Examples

### Deploy Metrics Stack
```bash
cd /data/elasticsearch-metrics
docker-compose up -d
```

### Check Metrics Endpoints
```bash
# Internal network access
curl -s http://elasticsearch-exporter:9114/metrics | head -20
curl -s http://node-exporter-es:9100/metrics | head -20
curl -s http://cadvisor-es:8080/metrics | head -20

# External access
curl -s http://100.105.46.41:9114/metrics | head -20
curl -s http://100.105.46.41:9100/metrics | head -20
curl -s http://100.105.46.41:8080/metrics | head -20
```

### Test Prometheus Config
```bash
# Validate configuration
docker run --rm -v $(pwd)/prometheus.yml:/prometheus.yml prom/prometheus:latest \
  --config.file=/prometheus.yml --dry-run

# Deploy local Prometheus (optional)
# Uncomment prometheus service in docker-compose.yml then:
docker-compose up -d prometheus
```

## Integration dengan External Servers

### Grafana Datasource
```json
{
  "name": "Elasticsearch-Metrics",
  "type": "prometheus", 
  "url": "http://100.105.46.41:9090",
  "access": "proxy"
}
```

### External Prometheus Scrape Config
```yaml
scrape_configs:
  - job_name: 'elasticsearch-remote'
    static_configs:
      - targets: 
        - '100.105.46.41:9114'
        - '100.105.46.41:9100' 
        - '100.105.46.41:8080'
    scrape_interval: 30s
```

## Monitoring Best Practices

1. **Scrape Intervals:**
   - Elasticsearch metrics: 30s (data intensive)
   - System metrics: 15s (responsive monitoring)
   - Container metrics: 30s (resource efficient)

2. **Retention:**
   - Local storage: 30 days
   - Remote write untuk long-term storage

3. **Alerting Rules:**
   - Cluster status tidak GREEN
   - High memory usage (>90%)
   - Disk space low (<10%)
   - High search latency (>1000ms)

4. **Security:**
   - Internal network untuk optimal performance
   - External access melalui Tailscale VPN
   - Basic auth untuk remote write endpoints