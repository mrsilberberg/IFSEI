FROM alpine:3.18

RUN apk add --no-cache bash jq netcat-openbsd mosquitto-clients

COPY run.sh /run.sh
COPY generate.sh /generate.sh
COPY feedback.sh /feedback.sh
COPY stop_nc.sh /stop_nc.sh
COPY send_ifsei_cmd.sh /send_ifsei_cmd.sh
RUN chmod +x /run.sh /generate.sh /feedback.sh /stop_nc.sh /send_ifsei_cmd.sh


CMD ["/run.sh"]
