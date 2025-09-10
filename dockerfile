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