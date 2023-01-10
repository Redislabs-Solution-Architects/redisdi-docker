#!/bin/bash
# Maker: Joey Whelan
# Usage: run.sh
# Description:  Starts a 3-node Redis Enterpise cluster + postgresql containers,
# builds a Redis target DB, 
# builds a Postgres source DB, 
# builds a Redis DI sink DB,
# deploys Redis DI
# starts a Debezium container

SEARCH=redisearch.Linux-ubuntu18.04-x86_64.2.6.3.zip
JSON=rejson.Linux-ubuntu18.04-x86_64.2.4.2.zip
GEARS=redisgears_python.Linux-ubuntu18.04-x86_64.1.2.5.zip
CHINOOK=chinook.sql
REDIS_DI=redis-di

gears_check() {
    curl -s -k -u "redis@redis.com:redis" https://localhost:9443/v1/modules | jq '.[] | select(.display_name=="RedisGears").semantic_version'
}

if [ ! -f $SEARCH ]
then
    echo "*** Fetch Search module  ***"
    wget -q https://redismodules.s3.amazonaws.com/redisearch/$SEARCH
fi 

if [ ! -f $JSON ]
then
    echo "*** Fetch JSON module  ***"
    wget -q https://redismodules.s3.amazonaws.com/rejson/$JSON
fi 

if [ ! -f $GEARS ]
then
    echo "*** Fetch Gears module  ***"
    wget -q https://redismodules.s3.amazonaws.com/redisgears/$GEARS
fi 

if [ ! -f $CHINOOK ]
then
    echo "*** Fetch Chinook script ***"
    wget -q https://raw.githubusercontent.com/xivSolutions/ChinookDb_Pg_Modified/master/chinook_pg_serial_pk_proper_naming.sql -O chinook.sql
fi

if [ ! -f $REDIS_DI ]
then
    echo "*** Fetch redis-di executable ***"
    wget -q https://qa-onprem.s3.amazonaws.com/redis-di/latest/redis-di-ubuntu20.04-latest.tar.gz -O - | tar -xz
fi

echo "*** Launch Redis Enterprise + Postgres Containers ***"
docker compose up -d

echo "*** Wait for Redis Enterprise to come up ***"
curl -s -o /dev/null --retry 5 --retry-all-errors --retry-delay 3 -f -k -u "redis@redis.com:redis" https://localhost:9443/v1/bootstrap

echo "*** Build Cluster ***"
docker exec -it re1 /opt/redislabs/bin/rladmin cluster create name cluster.local username redis@redis.com password redis
docker exec -it re2 /opt/redislabs/bin/rladmin cluster join nodes 192.168.20.2 username redis@redis.com password redis
docker exec -it re3 /opt/redislabs/bin/rladmin cluster join nodes 192.168.20.2 username redis@redis.com password redis

echo "*** Load Modules ***"
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v2/modules -F module=@$GEARS
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v1/modules -F module=@$SEARCH
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v1/modules -F module=@$JSON

echo "*** Build Target Redis DB ***"
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v1/bdbs -H "Content-Type:application/json" -d @targetdb.json

echo "*** Build Source Postgres DB ***"
export PGPASSWORD=postgres; createdb -U postgres -h localhost chinook; psql -q chinook -U postgres -h localhost -1 -f ./chinook.sql >&/dev/null

echo "*** Wait for Gears Module to load ***"
while [ -z "$(gears_check)" ] 
do 
    sleep 3
done

echo "*** Build Redis DI DB ***"
./redis-di create --silent --cluster-host localhost --cluster-api-port 9443 --cluster-user redis@redis.com \
--cluster-password redis --rdi-port 13000 --rdi-password redis

echo "*** Expose RDI Endpoint on all nodes ***"
docker exec -it re1 /opt/redislabs/bin/rladmin bind db redis-di-1 endpoint 2:1 policy all-nodes

echo "*** Deploy Redis DI ***"
./redis-di deploy --dir ./conf --rdi-host localhost --rdi-port 13000 --rdi-password redis

echo "*** Start Debezium ***"
docker run -d --rm --name debezium --network re_network --privileged -v $PWD/conf/debezium:/debezium/conf debezium/server:2.0.0.Final