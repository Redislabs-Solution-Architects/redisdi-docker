#!/bin/bash
# Maker: Joey Whelan
# Usage: run.sh
# Description:  Starts a 3-node Redis Enterpise cluster + postgresql containers, builds a Redis target DB, 
# builds a source DB, builds a Redis DI sink DB, deploys Redis DI, starts a Debezium container

GEARS=redisgears_python.Linux-ubuntu18.04-x86_64.1.2.5.zip
JSON=rejson.Linux-ubuntu18.04-x86_64.2.4.3.zip
SOURCE_DB=

gears_check() {
    while [ -z "$(curl -s -k -u "redis@redis.com:redis" https://localhost:9443/v1/modules | \
    jq '.[] | select(.display_name=="RedisGears").semantic_version')" ]
    do  
        sleep 3
    done
}

db_check() {
    case $SOURCE_DB in
        postgres)
        while ! pg_isready -q -h 127.0.0.1
        do  
            sleep 3
        done
        echo "*** Postgres is up ***"
        ;;
        mysql)
        while ! mysqladmin -s -h 127.0.0.1 ping
        do      
            sleep 3
        done
        echo "*** Mysql is up ***"
        docker exec mysql mysql --user=root --password=debezium --silent \
        -e "GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'mysqluser';" >/dev/null 2>&1
        ;;
    esac
}

case $1 in
    postgres|mysql) 
        SOURCE_DB=$1
        ;;
    *)  
        echo "Usage: run.sh <db type: postgres|mysql>" 1>&2
        exit 1
        ;;
esac

if [ ! -f $JSON ]
then
    echo "*** Fetch JSON module  ***"
    wget -q https://redismodules.s3.amazonaws.com/rejson/$JSON
fi 

if [ ! -f $GEARS ]
then
    echo "*** Fetch Gears  ***"
    wget -q https://redismodules.s3.amazonaws.com/redisgears/$GEARS 
fi

if [ ! -f redis-di ]
then
    echo "*** Fetch redis-di executable ***"
    wget -q https://qa-onprem.s3.amazonaws.com/redis-di/latest/redis-di-ubuntu20.04-latest.tar.gz -O - | tar -xz
fi

echo "*** Launch Redis Enterprise + Source DB Containers ***"
docker compose --profile $SOURCE_DB up -d

echo "*** Wait for Redis Enterprise to come up ***"
curl -s -o /dev/null --retry 5 --retry-all-errors --retry-delay 3 -f -k -u "redis@redis.com:redis" https://localhost:9443/v1/bootstrap

echo "*** Build Cluster ***"
docker exec -it re1 /opt/redislabs/bin/rladmin cluster create name cluster.local username redis@redis.com password redis
docker exec -it re2 /opt/redislabs/bin/rladmin cluster join nodes 192.168.20.2 username redis@redis.com password redis
docker exec -it re3 /opt/redislabs/bin/rladmin cluster join nodes 192.168.20.2 username redis@redis.com password redis

echo "*** Load Modules ***"
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v2/modules -F module=@$GEARS
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v1/modules -F module=@$JSON

echo "*** Build Target Redis DB ***"
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v1/bdbs -H "Content-Type:application/json" -d @targetdb.json

echo "*** Wait for Gears Module to load ***"
gears_check

echo "*** Build Redis DI DB ***"
./redis-di create --silent --cluster-host localhost --cluster-api-port 9443 --cluster-user redis@redis.com \
--cluster-password redis --rdi-port 13000 --rdi-password redis

echo "*** Expose RDI Endpoint on all nodes ***"
docker exec -it re1 /opt/redislabs/bin/rladmin bind db redis-di-1 endpoint 2:1 policy all-nodes

echo "*** Deploy Redis DI ***"
./redis-di deploy --dir ./conf --rdi-host localhost --rdi-port 13000 --rdi-password redis

echo "*** Wait for Source DB to come up ***"
db_check

echo "*** Start Debezium ***"
docker run -d --rm --name debezium --network re_network --privileged -v $PWD/conf/debezium/$SOURCE_DB:/debezium/conf debezium/server:2.0.0.Final