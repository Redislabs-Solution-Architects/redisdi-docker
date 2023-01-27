FROM debezium/server:latest
USER root
ARG INSTANT_CLIENT
RUN microdnf -y install libaio
RUN microdnf -y install unzip
RUN curl -s $INSTANT_CLIENT -o instantclient.zip && \
unzip -qq -j instantclient.zip -d /debezium/instantclient && \
rm instantclient.zip
RUN cp /debezium/instantclient/ojdbc8.jar /debezium/lib && \
cp /debezium/instantclient/xstreams.jar /debezium/lib
ENV LD_LIBRARY_PATH=/debezium/instantclient