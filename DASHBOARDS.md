# Splunk Dashboards

This directory contains comprehensive Splunk dashboards for monitoring your Docker Swarm home lab.

## Dashboard List

| # | Dashboard | Description |
|---|-----------|-------------|
| 00 | **Executive Overview** | High-level summary of all systems, health status, key metrics |
| 01 | **Security Overview** | SSH, authentication, failed logins, security events |
| 02 | **Docker Swarm & Containers** | Container status, Swarm nodes, services, resource usage |
| 03 | **Traefik Proxy** | API gateway traffic, HTTP status codes, response times |
| 04 | **System Logs** | Syslog, kernel messages, daemon logs |
| 05 | **Audit & Compliance** | Command execution, file changes, user activity |
| 06 | **System Performance** | CPU, memory, disk, network metrics |
| 07 | **Network Monitoring** | Firewall events, blocked connections, traffic analysis |
| 08 | **Application Logs** | Docker container stdout/stderr, application events |
| 09 | **Login Activity** | SSH sessions, authentication history, geolocation |
| 10 | **Threat Detection** | Brute force attacks, anomalies, security threats |
| 11 | **Infrastructure Health** | VM status, cluster health, service discovery |

## Installation

### Method 1: Copy Script (Recommended)

```bash
# From your local machine
cd /home/zaid/Documents/Splunk
chmod +x scripts/copy-dashboards.sh
./scripts/copy-dashboards.sh
```

### Method 2: Manual Import via Splunk Web

1. Log into Splunk Web: `https://10.10.10.114:8000`
2. Go to **Settings → User Interface → Views**
3. Click **New** for each dashboard
4. Paste the XML content from the dashboard files

### Method 3: REST API Import

```bash
export SPLUNK_PASSWORD="your_password"
chmod +x scripts/import-dashboards.sh
./scripts/import-dashboards.sh
```

## Dashboard Descriptions

### 00 - Executive Overview 🏠
**The main landing page for your home lab monitoring.**

- System health status (Healthy/Degraded/Critical)
- Active hosts count
- Running containers count
- Events per second
- Security summary (failed/successful logins)
- Event volume by index
- Swarm node status
- Data source health check

### 01 - Security Overview 🔐
**Monitor all authentication and security events.**

- Security event counts
- Failed vs successful login timeline
- Failed login attempts by source IP
- Sudo command tracking
- Security events by host

### 02 - Docker Swarm & Containers 🐳
**Complete Docker infrastructure visibility.**

- Running container count
- Swarm node status and roles
- Service replicas
- Container CPU/memory usage charts
- Resource details table
- Docker events timeline

### 03 - Traefik Proxy 🌐
**Monitor your API gateway and reverse proxy.**

- Request rate
- Error response counts (4xx/5xx)
- Average response time
- HTTP status code distribution
- Top services/backends
- Top requested paths
- Client IP analysis
- Response time distribution
- Slowest requests
- Error request details

### 04 - System Logs 📋
**All Linux system log monitoring.**

- Event counts by severity
- Error and warning tracking
- Events by sourcetype
- Top processes/services
- Kernel messages
- Service start/stop events
- Package changes (dpkg)

### 05 - Audit & Compliance 📝
**Detailed command and file change tracking.**

- Audit event counts
- Command executions (EXECVE)
- Sudo activity with full command details
- File/config changes
- User/group modifications
- Network connections
- Bash history commands

### 06 - System Performance 📊
**Resource utilization and performance metrics.**

- Active data sources
- Reporting hosts
- Events per second
- Container CPU/memory charts
- Top resource consumers
- Network and Block I/O
- Index statistics

### 07 - Network Monitoring 🌐
**Firewall and network traffic analysis.**

- Network event counts
- Firewall blocks and allows
- Unique source IPs
- Blocked source IPs and ports
- SSH connection attempts
- Protocol distribution
- Firewall event details

### 08 - Application Logs 📱
**Docker container application output.**

- Application event counts
- Error and warning detection
- Log volume by container
- Log level distribution
- Dokploy service logs
- Database service logs
- Recent application events

### 09 - Login Activity 🔑
**Detailed authentication tracking.**

- Login attempt counts
- Authentication timeline
- Successful login details
- Failed login analysis
- Brute force detection
- Authentication methods
- Geolocation of login sources

### 10 - Threat Detection 🚨
**Security threat identification and alerting.**

- Active threat count
- Suspicious activities
- Brute force attack detection
- Invalid user attempts
- Root login attempts
- Suspicious process execution
- Failed sudo attempts
- Configuration file changes
- Attack source geolocation

### 11 - Infrastructure Health 🖥️
**Overall infrastructure status.**

- VM/Node status with age tracking
- Swarm cluster status
- Service health
- Container distribution
- Event rate by host
- Container restarts/crashes
- Service errors

## Customization

### Modifying Time Ranges

Each panel has configurable time ranges. Common options:
- `earliest=-1h` - Last hour
- `earliest=-24h` - Last 24 hours
- `earliest=-7d` - Last 7 days
- `earliest=@d` - Since midnight

### Adding New Panels

1. Copy an existing panel as template
2. Modify the search query
3. Update title and options
4. Save the XML file
5. Re-run the import script

### Creating Custom Searches

Example searches for common use cases:

```spl
# Top 10 error-generating containers
index=docker sourcetype="docker:container:json" (error OR ERROR)
| rex field=source "/var/lib/docker/containers/(?<container_id>[^/]+)/"
| stats count by container_id
| sort -count
| head 10

# SSH brute force attempts
index=security "Failed password"
| rex "from\s+(?<src_ip>\d+\.\d+\.\d+\.\d+)"
| bin _time span=10m
| stats count by _time src_ip
| where count >= 5

# Traefik slow requests (>500ms)
index=docker traefik
| rex "\"Duration\":(?<duration>\d+)"
| eval duration_ms = duration/1000000
| where duration_ms > 500
| table _time service path duration_ms

# Container memory hogs
index=docker sourcetype="docker:stats"
| rex field=mem_perc "(?<mem_pct>[\d.]+)%"
| where mem_pct > 80
| table _time name mem_pct host
```

## Troubleshooting

### Dashboards Not Loading

1. Check Splunk is running:
   ```bash
   ssh root@10.10.10.114 'docker ps | grep splunk-enterprise'
   ```

2. Verify dashboard files exist:
   ```bash
   ssh root@10.10.10.114 'docker exec splunk-enterprise ls -la /opt/splunk/etc/apps/search/local/data/ui/views/'
   ```

3. Check permissions:
   ```bash
   ssh root@10.10.10.114 'docker exec splunk-enterprise chown -R splunk:splunk /opt/splunk/etc/apps/search/local/'
   ```

### No Data in Panels

1. Check if data exists for the time range:
   ```spl
   index=* | stats count by index
   ```

2. Verify forwarders are sending data:
   ```spl
   | tstats count WHERE index=* earliest=-5m by host
   ```

3. Check specific sourcetype:
   ```spl
   | metadata type=sourcetypes index=*
   ```

### Panel Shows Errors

1. Open the panel search in Search app
2. Check for syntax errors
3. Verify field extractions work
4. Check time range is appropriate

## Best Practices

1. **Set appropriate refresh intervals** - Don't refresh too frequently for historical data
2. **Use tstats for efficiency** - `| tstats` is faster than regular searches
3. **Limit result sets** - Use `| head N` to prevent slowdowns
4. **Use drilldowns** - Link to detailed searches for investigation
5. **Add descriptions** - Help users understand panel purpose

## References

- [Splunk Dashboard Examples](https://docs.splunk.com/Documentation/Splunk/latest/Viz/Dashboards)
- [Simple XML Reference](https://docs.splunk.com/Documentation/Splunk/latest/Viz/PanelreferenceforSimplifiedXML)
- [Splunk Search Reference](https://docs.splunk.com/Documentation/Splunk/latest/SearchReference)

