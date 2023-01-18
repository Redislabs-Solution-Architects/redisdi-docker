# Redis Data Integration Docker Build  

## Contents
1.  [Summary](#summary)
2.  [Features](#features)
3.  [Prerequisites](#prerequisites)
4.  [Installation](#installation)
5.  [Results](#results)
    1.  [Architecture](#architecture)
    2.  [rladmin](#rladmin)
    3.  [RedisInsight](#redisinsight)

## Summary <a name="summary"></a>
This is a utility script for building a full Redis DI environment in Docker

## Features <a name="features"></a>
- Builds out a full Redis DI environment to include:  Redis Cluster, Source DB, Redis DI, Debezium

## Prerequisites <a name="prerequisites"></a>
- Docker
- Command line tools: curl, wget, jq, select, pg_isready, mysqladmin

## Installation <a name="installation"></a>
1. Clone this repo.

## Usage
### Options
- <dbtype>  postgres or mysql currently supported.

### Execution
```bash
./run.sh mysql
```
## Results <a name="results"></a>
### Architecture <a name="architecture"></a>
![architecture](https://docs.google.com/drawings/d/e/2PACX-1vTTMI3fiiboZdx5zhYUEQF22Wrw4O-xGHhnbYa0_8h_PWInpYsy0bBIDS2bDNis3ceYUHBpJ6MWQAXo/pub?w=663&h=380)  
