# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a **Docker-based NGINX reverse proxy** that masks Azure Blob Storage URLs, providing a clean API interface for accessing stored documents and attachments. The proxy transforms user-friendly URLs into Azure Blob Storage requests while adding security, rate limiting, and proper file handling.

## Key Architecture Concepts

### URL Masking Pattern
The core functionality revolves around URL transformation:
- **Client Request**: `GET /document/{document-id}/attachment/{attachment-id}`
- **Proxy Transform**: `https://jeendevisracardblob.blob.core.windows.net/jeendocs/{document-id}/attachment/{attachment-id}`
- **Security Layer**: Input validation, rate limiting, and header sanitization

### Container Architecture
- **Base Image**: `nginx:1.25-alpine` for lightweight, secure deployment
- **Security**: Non-root user execution, read-only filesystem, resource limits
- **Monitoring**: Built-in health checks and comprehensive logging
- **Performance**: Optimized buffer settings and keepalive connections

## Common Development Commands

### Local Development and Testing
```powershell
# Build and run with Docker Compose (recommended)
docker-compose up -d --build

# Check container status and logs
docker-compose ps
docker-compose logs -f nginx-azure-proxy

# Test the proxy endpoints
curl http://localhost:8080/health
curl http://localhost:8080/document/test-doc/attachment/sample.pdf
```

### Alternative Docker Commands
```powershell
# Build image manually
docker build -t nginx-azure-proxy .

# Run container directly
docker run -d --name nginx-azure-proxy -p 8080:80 -v ${PWD}/logs:/var/log/nginx nginx-azure-proxy

# Container management
docker stop nginx-azure-proxy
docker start nginx-azure-proxy
docker restart nginx-azure-proxy
```

### Configuration Validation
```powershell
# Test NGINX configuration syntax
docker run --rm -v ${PWD}/nginx.conf:/etc/nginx/nginx.conf nginx:alpine nginx -t

# Validate Docker Compose configuration
docker-compose config

# Check container health
docker-compose exec nginx-azure-proxy curl -f http://localhost/health
```

### Log Management and Debugging
```powershell
# Follow logs in real-time
docker-compose logs -f nginx-azure-proxy

# View specific log files
docker exec nginx-azure-proxy tail -f /var/log/nginx/access.log
docker exec nginx-azure-proxy tail -f /var/log/nginx/error.log

# Enable debug logging (modify nginx.conf)
# error_log /var/log/nginx/error.log debug;
```

## Architecture Deep Dive

### NGINX Configuration Structure
The `nginx.conf` file contains several critical sections:

1. **Upstream Configuration**: Defines the Azure Blob Storage backend
2. **Rate Limiting**: Implements `limit_req_zone` with 10 req/sec per IP
3. **Location Blocks**: Regex-based URL pattern matching and validation
4. **Security Headers**: OWASP-recommended headers and input validation
5. **Error Handling**: Custom JSON error responses

### Docker Security Features
- **Non-root execution**: Container runs as `nginxuser` (UID 1001)
- **Read-only filesystem**: Root filesystem mounted read-only
- **Resource limits**: CPU (0.5 cores) and memory (256MB) constraints
- **Capability dropping**: `no-new-privileges` security option
- **Temporary filesystems**: `/tmp`, `/var/cache/nginx`, `/var/run` as tmpfs

### URL Pattern Matching
```nginx
location ~ ^/document/([^/]+)/attachment/(.+)$ {
    set $document_id $1;
    set $attachment_id $2;
    # Input validation with regex
    if ($document_id !~ ^[a-zA-Z0-9_\-]+$) {
        return 400 "Invalid document ID format";
    }
}
```

### File Type Handling
- **Documents** (PDF, DOC, XLS, PPT): `Content-Disposition: inline`
- **Images** (JPG, PNG, GIF, SVG): `Content-Disposition: inline`
- **Archives** (ZIP, RAR, TAR): `Content-Disposition: attachment`

## Configuration Guide

### Azure Blob Storage Backend
To change the target storage account, update `nginx.conf`:
```nginx
upstream azure_blob {
    server your-storage-account.blob.core.windows.net:443;
    keepalive 32;
}

# And update the proxy_pass directive:
proxy_pass https://azure_blob/your-container/$document_id/attachment/$attachment_id;
```

### Rate Limiting Configuration
```nginx
# Adjust rate limiting in nginx.conf
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;
```

### Environment Variables (docker-compose.yml)
```yaml
environment:
  - TZ=UTC                    # Set timezone
  - NGINX_WORKER_PROCESSES=2  # Adjust worker processes if needed
```

### Resource Limits
```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'      # Adjust based on load requirements
      memory: 256M     # Increase for high-traffic scenarios
```

## API Endpoints

### Document Access
- **Pattern**: `/document/{document-id}/attachment/{attachment-id}`
- **Method**: GET
- **Validation**: IDs must match `^[a-zA-Z0-9_\-\.]+$`
- **Response**: File content with appropriate MIME type and headers

### Health Check
- **URL**: `/health`
- **Method**: GET
- **Response**: `200 OK` with "healthy" text

### Error Responses
- **400**: Invalid URL format or ID validation failure
- **403**: Direct blob storage access attempts
- **404**: Document or attachment not found
- **500**: Internal server errors

## Production Deployment Considerations

### SSL/TLS Configuration
For production, add SSL termination:
```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
}
```

### Performance Tuning
```nginx
# Increase worker connections for high traffic
events {
    worker_connections 2048;
}

# Adjust buffer sizes
proxy_buffer_size 8k;
proxy_buffers 16 8k;
proxy_busy_buffers_size 16k;
```

### Monitoring and Alerting
- **Health Check**: Container includes built-in health check endpoint
- **Log Analysis**: Access and error logs in JSON format for easy parsing
- **Metrics**: Consider adding Prometheus metrics exporter for monitoring
- **Alerting**: Set up alerts on error rates and response times

## Troubleshooting Common Issues

### Container Won't Start
```powershell
# Check NGINX configuration syntax
docker run --rm -v ${PWD}/nginx.conf:/etc/nginx/nginx.conf nginx:alpine nginx -t

# Check Docker Compose syntax
docker-compose config

# View container startup logs
docker-compose logs nginx-azure-proxy
```

### File Access Issues
1. **Invalid document/attachment ID**: Check ID format matches `^[a-zA-Z0-9_\-\.]+$`
2. **Azure Blob Storage access**: Verify blob exists and is publicly accessible
3. **Network connectivity**: Test connection to Azure Blob Storage from container

### Performance Issues
```powershell
# Monitor container resource usage
docker stats nginx-azure-proxy

# Check for rate limiting
grep "limiting requests" logs/access.log

# Analyze response times
docker-compose logs nginx-azure-proxy | grep -E "upstream_response_time"
```

### Permission Errors
```powershell
# Ensure logs directory has proper permissions
mkdir -p logs
chmod 755 logs

# Check container user permissions
docker exec nginx-azure-proxy id
```

## Development Best Practices

### Configuration Changes
1. **Test syntax**: Always validate NGINX config before deployment
2. **Gradual rollout**: Test changes in development environment first
3. **Backup configs**: Keep previous working configurations for rollback

### Security Considerations
- **Input validation**: All IDs are validated with strict regex patterns
- **Rate limiting**: Prevents abuse with configurable limits
- **Header sanitization**: Azure-specific headers are hidden from responses
- **Container security**: Non-root execution and read-only filesystem

### Monitoring and Logging
- **Structured logging**: Access logs include timing and upstream information
- **Health checks**: Regular container health verification
- **Error tracking**: Detailed error logs with request context

This proxy is designed for production use with security, performance, and maintainability as primary concerns. All deployments should be thoroughly tested with realistic traffic patterns before production use.