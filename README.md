# NGINX Azure Blob Storage Reverse Proxy

A Docker-based NGINX reverse proxy that masks Azure Blob Storage URLs, providing a clean API interface for accessing stored documents and attachments.

## Overview

This project creates a reverse proxy that:
- Accepts requests in the format: `https://<nginx-url>/document/{document-id}/attachment/{attachment-id}`
- Proxies them to Azure Blob Storage: `https://jeendevisracardblob.blob.core.windows.net/jeendocs/{document-id}/attachment/{attachment-id}`
- Hides the actual Azure Blob Storage URL from users
- Provides security headers and proper file serving capabilities

## How URL Masking Works

### 1. URL Pattern Matching
The NGINX configuration uses regex pattern matching to extract document IDs and attachment IDs from incoming requests:

```nginx
location ~ ^/document/([^/]+)/attachment/(.+)$ {
    set $document_id $1;
    set $attachment_id $2;
    # ...proxy configuration
}
```

### 2. Request Flow
1. **Client Request**: `GET /document/doc123/attachment/report.pdf`
2. **NGINX Processing**:
   - Extracts `document_id = "doc123"`
   - Extracts `attachment_id = "report.pdf"`
   - Validates IDs contain only safe characters
3. **Proxy Request**: `https://jeendevisracardblob.blob.core.windows.net/jeendocs/doc123/attachment/report.pdf`
4. **Response**: File content is streamed back to the client with appropriate headers

### 3. Security Features
- **ID Validation**: Only alphanumeric characters, underscores, hyphens, and dots are allowed
- **Rate Limiting**: 10 requests per second per IP with burst capability
- **Header Sanitization**: Azure-specific headers are hidden from responses
- **Direct Access Protection**: Blocks attempts to access blob storage URLs directly
- **Security Headers**: Adds OWASP-recommended security headers

## File Structure

```
nginx-azure-proxy/
├── nginx.conf           # NGINX configuration with proxy rules
├── Dockerfile          # Container definition
├── docker-compose.yml  # Docker Compose configuration
├── README.md          # This documentation
├── .gitignore         # Git ignore rules
└── logs/              # Log directory (created during runtime)
```

## Quick Start

### Prerequisites
- Docker
- Docker Compose

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd nginx-azure-proxy
```

### 2. Build and Run with Docker Compose
```bash
# Build and start the container
docker-compose up -d --build

# Check container status
docker-compose ps

# View logs
docker-compose logs -f nginx-azure-proxy
```

### 3. Test the Proxy
```bash
# Health check
curl http://localhost:8080/health

# Test document access (replace with actual document/attachment IDs)
curl http://localhost:8080/document/your-doc-id/attachment/your-file.pdf
```

## Alternative Deployment Methods

### Docker Build and Run
```bash
# Build the image
docker build -t nginx-azure-proxy .

# Run the container
docker run -d \
  --name nginx-azure-proxy \
  -p 8080:80 \
  -v $(pwd)/logs:/var/log/nginx \
  nginx-azure-proxy
```

### Production Deployment
For production deployment, consider:

1. **SSL/TLS Termination**: Add SSL certificates and configure HTTPS
2. **Load Balancing**: Deploy multiple instances behind a load balancer
3. **Monitoring**: Set up log aggregation and monitoring
4. **Environment Variables**: Make Azure Blob Storage URL configurable

## Configuration

### Environment Variables
You can customize the deployment using environment variables in `docker-compose.yml`:

- `TZ`: Timezone (default: UTC)

### NGINX Configuration Customization
Edit `nginx.conf` to modify:
- Rate limiting settings
- Timeout values
- Security headers
- File type handling
- Error responses

### Azure Blob Storage URL
To change the target Azure Blob Storage account, update the upstream configuration in `nginx.conf`:

```nginx
upstream azure_blob {
    server your-storage-account.blob.core.windows.net:443;
    keepalive 32;
}
```

And update the proxy_pass directive:
```nginx
proxy_pass https://azure_blob/your-container/$document_id/attachment/$attachment_id;
```

## API Endpoints

### Document Access
- **URL**: `/document/{document-id}/attachment/{attachment-id}`
- **Method**: GET
- **Description**: Retrieves a document attachment
- **Response**: File content with appropriate headers

**Example**:
```bash
curl http://localhost:8080/document/abc123/attachment/invoice.pdf
```

### Health Check
- **URL**: `/health`
- **Method**: GET
- **Description**: Returns service health status
- **Response**: "healthy" text

### Error Responses
The proxy returns JSON error responses for various scenarios:

- **400 Bad Request**: Invalid URL format or ID format
- **403 Forbidden**: Direct blob storage access attempts
- **404 Not Found**: Document or attachment not found
- **500 Server Error**: Internal server errors

## File Type Handling

The proxy handles different file types appropriately:

- **Documents** (PDF, DOC, XLS, PPT): `Content-Disposition: inline`
- **Images** (JPG, PNG, GIF, SVG): `Content-Disposition: inline`
- **Archives** (ZIP, RAR, TAR): `Content-Disposition: attachment`

## Security Features

1. **Input Validation**: Document and attachment IDs are validated using regex
2. **Rate Limiting**: 10 requests/second per IP with burst of 20
3. **Security Headers**: X-Frame-Options, X-Content-Type-Options, etc.
4. **Non-root User**: Container runs as unprivileged user
5. **Read-only Filesystem**: Container filesystem is read-only
6. **Resource Limits**: CPU and memory limits applied

## Monitoring and Logs

### Log Files
- Access logs: `/var/log/nginx/access.log`
- Error logs: `/var/log/nginx/error.log`

### Log Monitoring
```bash
# Follow logs in real-time
docker-compose logs -f nginx-azure-proxy

# View access logs
docker exec nginx-azure-proxy tail -f /var/log/nginx/access.log

# View error logs
docker exec nginx-azure-proxy tail -f /var/log/nginx/error.log
```

### Health Monitoring
```bash
# Check container health
docker-compose ps

# Manual health check
curl http://localhost:8080/health
```

## Troubleshooting

### Common Issues

1. **Container won't start**:
   ```bash
   # Check NGINX configuration syntax
   docker run --rm -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf nginx:alpine nginx -t
   ```

2. **File not found errors**:
   - Verify the document ID and attachment ID are correct
   - Check Azure Blob Storage permissions
   - Review access logs for the actual requested URL

3. **Permission errors**:
   ```bash
   # Check log directory permissions
   chmod 755 logs/
   ```

4. **High memory usage**:
   - Adjust buffer sizes in nginx.conf
   - Monitor proxy_buffers settings

### Debug Mode
To enable debug logging, modify `nginx.conf`:
```nginx
error_log /var/log/nginx/error.log debug;
```

## Performance Tuning

For high-traffic scenarios:

1. **Increase worker connections**: Modify `worker_connections` in nginx.conf
2. **Adjust buffer sizes**: Tune `proxy_buffers` and related settings
3. **Enable HTTP/2**: Add HTTP/2 support for better performance
4. **Cache static responses**: Implement caching for frequently accessed files

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review container logs
3. Open an issue in the repository with detailed information about the problem