#!/bin/bash
# Maker: Joey Whelan
# Usage: run.sh
# Description:  Shuts down Redis, DB, and Debezium containers
INSTANT_CLIENT=
SOURCE_DB=

case $1 in
    postgres|mysql|sqlserver|oracle_lm|oracle_xs) 
        SOURCE_DB=$1
        ;;
    *)  
        echo "Usage: stop.sh <db type: postgres|mysql|sqlserver|oracle_lm|oracle_xs>" 1>&2
        exit 1
        ;;
esac

SOURCE_DB=$SOURCE_DB INSTANT_CLIENT=$INSTANT_CLIENT docker compose --profile $SOURCE_DB --profile debezium down