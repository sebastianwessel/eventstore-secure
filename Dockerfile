FROM ubuntu:latest

ENV ES_VERSION=5.0.0-1 \
    DEBIAN_FRONTEND=noninteractive \
    EVENTSTORE_CLUSTER_GOSSIP_PORT=2112

RUN apt-get update \
    && apt-get install tzdata curl iproute2 -y \
    && curl -s https://packagecloud.io/install/repositories/EventStore/EventStore-OSS/script.deb.sh | bash \
    && apt-get install eventstore-oss=$ES_VERSION -y \
    && apt-get install openssl -y

EXPOSE 1112 2112 1113 2113 1115

VOLUME /var/lib/eventstore

COPY eventstore.conf /etc/eventstore/
COPY entrypoint.sh /

RUN mkdir /ssl

RUN openssl req \
  -x509 -sha256 -nodes -days 365 -subj "/CN=escluster.net" \
  -newkey rsa:2048 -keyout eventstore.pem -out eventstore.csr

RUN openssl pkcs12 -export -inkey eventstore.pem -in eventstore.csr -out eventstore.p12 -password pass:

RUN cp eventstore.csr /usr/local/share/ca-certificates/eventstore.crt

RUN update-ca-certificates

RUN apt-get -y remove openssl \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN cp eventstore.p12 /ssl
RUN cp eventstore.csr /ssl
RUN ls /ssl


HEALTHCHECK --timeout=2s CMD curl -sf http://localhost:2113/stats || exit 1

ENTRYPOINT ["/entrypoint.sh"]
