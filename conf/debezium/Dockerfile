FROM quay.io/debezium/server:latest
USER root
ARG INSTANT_CLIENT
RUN microdnf -y install libaio && \
microdnf -y install unzip && \
microdnf clean all
RUN curl -s $INSTANT_CLIENT -o instantclient.zip && \
unzip -qq -j instantclient.zip -d /debezium/instantclient && \
rm instantclient.zip && \
cp /debezium/instantclient/ojdbc8.jar /debezium/lib && \
cp /debezium/instantclient/xstreams.jar /debezium/lib
ENV LD_LIBRARY_PATH=/debezium/instantclient