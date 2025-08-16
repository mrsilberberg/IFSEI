FROM alpine:3.18

RUN apk add --no-cache bash jq netcat-openbsd mosquitto-clients

# Copia scripts para dentro do container
COPY run.sh /run.sh
COPY listener.sh /listener.sh
COPY parser.sh /parser.sh
COPY generate.sh /generate.sh
COPY stop_nc.sh /stop_nc.sh

# Permissões de execução
RUN chmod +x /run.sh /listener.sh /parser.sh /generate.sh /stop_nc.sh 

# Script inicial
CMD ["/run.sh"]
