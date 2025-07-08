FROM nginx AS ajeem
RUN apt-get update && apt-get install -y wget tar
RUN wget https://github.com/prometheus/node_exporter/releases/download/v1.9.1/node_exporter-1.9.1.linux-amd64.tar.gz 
RUN tar -zxvf node_exporter-1.9.1.linux-amd64.tar.gz
RUN mv node_exporter-1.9.1.linux-amd64/node_exporter /usr/local/bin/node_exporter
RUN chmod +x /usr/local/bin/node_exporter
EXPOSE 9100
CMD ["/usr/local/bin/node_exporter"]