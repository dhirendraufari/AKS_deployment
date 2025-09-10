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