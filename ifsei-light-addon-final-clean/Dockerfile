FROM alpine:3.18

RUN apk add --no-cache bash jq netcat-openbsd mosquitto-clients

COPY run.sh /run.sh
COPY generate.sh /generate.sh
COPY feedback.sh /feedback.sh
RUN chmod +x /run.sh /generate.sh /feedback.sh


CMD ["/run.sh"]
