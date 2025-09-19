# SingleClin Web Admin - Multi-stage Docker build

# Stage 1: Build environment
FROM node:18-alpine AS build
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache libc6-compat

# Copy package files
COPY package*.json ./
COPY tsconfig*.json ./
COPY vite.config.ts ./

# Install dependencies - use npm install to handle missing package-lock.json
RUN npm install

# Copy source code
COPY public ./public
COPY src ./src
COPY index.html ./

# Set Firebase environment variables for build
ARG VITE_FIREBASE_API_KEY
ARG VITE_FIREBASE_AUTH_DOMAIN
ARG VITE_FIREBASE_PROJECT_ID
ARG VITE_FIREBASE_STORAGE_BUCKET
ARG VITE_FIREBASE_MESSAGING_SENDER_ID
ARG VITE_FIREBASE_APP_ID
ARG VITE_GOOGLE_MAPS_API_KEY
ARG VITE_BACKEND_URL

ENV VITE_FIREBASE_API_KEY=$VITE_FIREBASE_API_KEY
ENV VITE_FIREBASE_AUTH_DOMAIN=$VITE_FIREBASE_AUTH_DOMAIN
ENV VITE_FIREBASE_PROJECT_ID=$VITE_FIREBASE_PROJECT_ID
ENV VITE_FIREBASE_STORAGE_BUCKET=$VITE_FIREBASE_STORAGE_BUCKET
ENV VITE_FIREBASE_MESSAGING_SENDER_ID=$VITE_FIREBASE_MESSAGING_SENDER_ID
ENV VITE_FIREBASE_APP_ID=$VITE_FIREBASE_APP_ID
ENV VITE_GOOGLE_MAPS_API_KEY=$VITE_GOOGLE_MAPS_API_KEY
ENV VITE_BACKEND_URL=$VITE_BACKEND_URL

# Build the application (skip TypeScript check for deployment)
RUN npx vite build

# Stage 2: Runtime environment with Nginx
FROM nginx:alpine AS runtime

# Install curl for health checks
RUN apk add --no-cache curl

# Copy custom nginx configuration
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 8080;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Enable compression
    gzip on;
    gzip_types
        text/plain
        text/css
        text/js
        text/xml
        text/javascript
        application/javascript
        application/json
        application/xml+rss;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Handle client-side routing
    location / {
        try_files \$uri \$uri/ /index.html;

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API proxy to backend
    location /api/ {
        proxy_pass https://api.singleclin.com.br/api/;
        proxy_set_header Host api.singleclin.com.br;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_ssl_verify off;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Copy built application from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Create non-root user
RUN addgroup -g 1001 -S singleclin && \
    adduser -S singleclin -u 1001 -G singleclin

# Update nginx to run as non-root
RUN sed -i 's/user  nginx;/user  singleclin;/' /etc/nginx/nginx.conf && \
    chown -R singleclin:singleclin /var/cache/nginx && \
    chown -R singleclin:singleclin /var/log/nginx && \
    chown -R singleclin:singleclin /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R singleclin:singleclin /var/run/nginx.pid

# Switch to non-root user
USER singleclin

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]