# Redis Data Integration Docker Build  

## Contents
1.  [Summary](#summary)
2.  [Features](#features)
3.  [Prerequisites](#prerequisites)
4.  [Installation](#installation)
5.  [Usage](#usage)
6.  [Architecture](#architecture)


## Summary <a name="summary"></a>
This is a utility script for building a full Redis DI environment in Docker

## Features <a name="features"></a>
- Builds out a full Redis DI environment to include:  Redis Cluster, Source DB, Redis DI, Debezium

## Prerequisites <a name="prerequisites"></a>
- Ubuntu 20.x or higher
- Docker
- Command line tools: curl, wget

## Installation <a name="installation"></a>
```bash
git clone https://github.com/Redislabs-Solution-Architects/redisdi-docker.git && cd redisdi-docker
```

## Usage <a name="usage"></a>
### Options
- <dbtype>  postgres, mysql, sqlserver, oracle_lm (LogMiner), oracle_xs (XStreams) currently supported.
- <mode> ingress, writebehind

### Execution Example
```bash
./run.sh mysql
```
```bash
./stop.sh mysql
```

## Architecture <a name="architecture"></a>
### Ingress
![architecture](https://docs.google.com/drawings/d/e/2PACX-1vQJTilci_8FrRnPjy7Lxf67QLiUbilbLpmM3ftsKIY0jYJOi7uqupLs1XXGFRKP4yq0S7plyNYiUVwA/pub?w=663&h=380) 
### Writebehind
![architecture](https://docs.google.com/drawings/d/e/2PACX-1vTTMI3fiiboZdx5zhYUEQF22Wrw4O-xGHhnbYa0_8h_PWInpYsy0bBIDS2bDNis3ceYUHBpJ6MWQAXo/pub?w=663&h=380) 
