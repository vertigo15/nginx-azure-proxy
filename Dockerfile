# Use official NGINX image as base
FROM nginx:1.25-alpine

# Maintainer information
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="NGINX reverse proxy for masking Azure Blob Storage URLs"
LABEL version="1.0"

# Install additional packages for better logging and debugging
RUN apk add --no-cache \
    curl \
    tzdata \
    && rm -rf /var/cache/apk/*

# Remove default NGINX configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom NGINX configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create log directory with proper permissions
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chmod -R 755 /var/log/nginx

# Create cache directory for NGINX
RUN mkdir -p /var/cache/nginx && \
    chown -R nginx:nginx /var/cache/nginx && \
    chmod -R 755 /var/cache/nginx

# Test NGINX configuration during build
RUN nginx -t

# Create a non-root user for running NGINX (security best practice)
RUN addgroup -g 1001 nginxuser && \
    adduser -D -s /bin/sh -u 1001 -G nginxuser nginxuser

# Set proper ownership for NGINX directories
RUN chown -R nginxuser:nginxuser /var/cache/nginx && \
    chown -R nginxuser:nginxuser /var/log/nginx && \
    chown -R nginxuser:nginxuser /etc/nginx/

# Create PID directory with proper permissions
RUN mkdir -p /var/run/nginx && \
    chown -R nginxuser:nginxuser /var/run/nginx

# Switch to non-root user
USER nginxuser

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start NGINX in foreground mode
CMD ["nginx", "-g", "daemon off;"]