# ---------- BUILD STAGE ----------
FROM node:18 AS build
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy source code and build
COPY . .
RUN npm run build

# ---------- RUNTIME STAGE ----------
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Remove default nginx static assets
RUN rm -rf ./*

# Copy build output from previous stage
COPY --from=build /app/build .

# Copy custom nginx config (optional)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]



FROM nginx AS dummy
RUN apt-get update && apt-get install -y wget tar
RUN wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz 
RUN tar -zxvf node_exporter-1.9.1.linux-amd64.tar.gz
RUN mv node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/node_exporter
RUN chmod +x /usr/local/bin/node_exporter
EXPOSE 9100
CMD ["/usr/local/bin/node_exporter"]




--------------
#build .net base images 
# Build Stage 
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["WorkerApp/WorkerApp.csproj", "WorkerApp/"]
RUN dotnet restore "WorkerApp/WorkerApp.csproj"
COPY . .
WORKDIR "/src/WorkerApp"
RUN dotnet publish "WorkerApp.csproj" -c Release -o /app/publish

# Runtime Stage
FROM mcr.microsoft.com/dotnet/runtime:7.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "WorkerApp.dll"]


#############################################
# Stage 1: Build React App (Node.js)
#############################################
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files first (to leverage Docker cache)
COPY package*.json ./

# Install only production dependencies (no dev deps)
RUN npm ci --only=production

# Copy source code
COPY . .

# Build optimized static files
RUN npm run build


#############################################
# Stage 2: Serve Static Files with NGINX (Non-root)
#############################################
FROM nginx:1.27-alpine

# Create a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Remove default nginx configuration
RUN rm -rf /etc/nginx/conf.d/*

# Copy custom secure nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build output from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Change ownership of nginx directories to non-root user
RUN chown -R appuser:appgroup /usr/share/nginx /var/cache/nginx /var/run /etc/nginx

# Use non-root user
USER appuser

# Expose app port
EXPOSE 8080

# Apply metadata
LABEL maintainer="devops@company.com" \
      version="1.0.0" \
      description="React Frontend (Secure Non-Root Docker Image)"

# Start NGINX (using non-root)
CMD ["nginx", "-g", "daemon off;"]
