FROM alpine:3.18

RUN apk add --no-cache bash jq netcat-openbsd

COPY run.sh /run.sh
COPY generate.sh /generate.sh
RUN chmod +x /run.sh /generate.sh

CMD ["/run.sh"]
