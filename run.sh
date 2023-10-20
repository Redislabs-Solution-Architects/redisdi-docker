#!/bin/bash
# Maker: Joey Whelan
# Usage: run.sh
# Description:  Starts a 3-node Redis Enterpise cluster + postgresql containers, builds a Redis target DB, 
# builds a source DB, builds a Redis DI sink DB, deploys Redis DI, starts a Debezium container

GEARS=redisgears_python.Linux-ubuntu18.04-x86_64.1.2.7.zip
JSON=rejson.Linux-ubuntu18.04-x86_64.2.6.6.zip
SEARCH=redisearch.Linux-ubuntu18.04-x86_64.2.8.8.zip
INSTANT_CLIENT=https://download.oracle.com/otn_software/linux/instantclient/219000/instantclient-basiclite-linux.x64-21.9.0.0.0dbru.zip
SOURCE_DB=
MODE=

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
        while ! docker exec postgres pg_isready | grep -q accepting
        do  
            sleep 3
        done
        echo "*** Postgres is up ***"
        docker exec postgres /bin/bash -c "export PGPASSWORD=postgres"
        docker exec postgres createdb -U postgres Chinook
        docker exec postgres psql -q Chinook -U postgres -1 -f /home/scripts/chinook.sql >/dev/null 2>&1
        docker exec postgres createdb -U postgres AccountDB
        docker exec postgres psql -q AccountDB -U postgres -1 -f /home/scripts/account.sql >/dev/null 2>&1
        ;;
        mysql)
        while ! docker exec mysql mysqladmin -s --user=root --password=debezium ping 2>&1 | grep -q alive
        do      
            sleep 3
        done
        echo "*** MySQL is up ***"
        docker exec mysql mysql --user=root --password=debezium --silent \
        -e "GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'mysqluser';" >/dev/null 2>&1
        docker exec mysql /bin/bash -c "mysql --user=mysqluser --password=mysqlpw Chinook < /home/scripts/chinook.sql" >/dev/null 2>&1
        docker exec mysql /bin/bash -c "mysql --user=root --password=debezium < /home/scripts/account.sql"
        ;;
        sqlserver)
        while ! docker exec sqlserver cat /var/opt/mssql/log/errorlog | \
        grep -q "ready for client connections"
        do
            sleep 3
        done
        echo "*** SQLServer is up ***"
        docker exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Password! \
        -i /home/scripts/chinook.sql 1>/dev/null
        docker exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Password! \
        -i /home/scripts/account.sql 1>/dev/null
        ;;
        oracle_lm|oracle_xs)
        while ! docker logs --tail 100 $SOURCE_DB | grep -q "tail of the alert.log"
        do
            sleep 10
        done
        echo "*** Oracle is up ***"
        ;;
    esac
}

case $1 in
    postgres|mysql|sqlserver|oracle_lm|oracle_xs) 
        SOURCE_DB=$1
        ;;
    *)  
        echo "Usage: run.sh <db type: postgres|mysql|sqlserver|oracle_lm|oracle_xs>" 1>&2
        exit 1
        ;;
esac

case $2 in
    ingress|writebehind) 
        MODE=$2
        ;;
    *)  
        echo "Usage: run.sh <mode: ingress|writebehind>" 1>&2
        exit 1
        ;;
esac

if [ ! -f $JSON ]
then
    echo "*** Fetch JSON module  ***"
    wget -q https://redismodules.s3.amazonaws.com/rejson/$JSON
fi 

if [ ! -f $SEARCH ]
then
    echo "*** Fetch SEARCH module  ***"
    wget -q https://redismodules.s3.amazonaws.com/redisearch/$SEARCH
fi 

if [ ! -f $GEARS ]
then
    echo "*** Fetch Gears  ***"
    wget https://redismodules.s3.amazonaws.com/redisgears/$GEARS 
fi

if [ ! -f redis-di ]
then
    echo "*** Fetch redis-di executable ***"
    wget -q https://qa-onprem.s3.amazonaws.com/redis-di/latest/redis-di-ubuntu20.04-latest.tar.gz -O - | tar -xz
fi

echo "*** Launch Redis Enterprise + Source DB Containers ***"
SOURCE_DB=$SOURCE_DB INSTANT_CLIENT=$INSTANT_CLIENT docker compose --profile $SOURCE_DB up -d

echo "*** Wait for Redis Enterprise to come up ***"
curl -s -o /dev/null --retry 5 --retry-all-errors --retry-delay 3 -f -k -u "redis@redis.com:redis" https://localhost:9443/v1/bootstrap

echo "*** Build Cluster ***"
docker exec -it re1 /opt/redislabs/bin/rladmin cluster create name cluster.local username redis@redis.com password redis
docker exec -it re2 /opt/redislabs/bin/rladmin cluster join nodes 192.168.20.2 username redis@redis.com password redis
docker exec -it re3 /opt/redislabs/bin/rladmin cluster join nodes 192.168.20.2 username redis@redis.com password redis

echo "*** Load Modules ***"
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v2/modules -F module=@$GEARS
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v1/modules -F module=@$JSON
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v1/modules -F module=@$SEARCH

echo "*** Wait for Gears Module to load ***"
gears_check

echo "*** Build Target Redis DB ***"
curl -s -o /dev/null -k -u "redis@redis.com:redis" https://localhost:9443/v1/bdbs -H "Content-Type:application/json" -d @targetdb.json

echo "*** Wait for Source DB to come up ***"
db_check

if [ $MODE == "ingress" ]
then
    echo "*** Build Redis DI DB for Ingress ***"
    ./redis-di create --silent --cluster-host localhost --cluster-api-port 9443 --cluster-user redis@redis.com \
    --cluster-password redis --rdi-port 13000 --rdi-password redis

    echo "*** Deploy Redis DI for Ingress ***"
    ./redis-di deploy --dir ./conf/$SOURCE_DB/ingest --rdi-host localhost --rdi-port 13000 --rdi-password redis
    
    echo "*** Start Debezium ***"
    SOURCE_DB=$SOURCE_DB INSTANT_CLIENT=$INSTANT_CLIENT docker compose --profile debezium up -d
else
    echo "*** Configure and Deploy Redis DI for Write-behind ***"
    ./redis-di configure --rdi-host localhost --rdi-port 12000 --rdi-password redis
    ./redis-di deploy --rdi-host localhost --rdi-port 12000 --rdi-password redis --dir ./conf/$SOURCE_DB/write_behind
fi