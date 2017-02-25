Docker image to run Hive
===============================

## Current Version
* Apache Hive
* Apache Hadoop 2.5.0
* PostgreSQL 9.3 (Hive metastore backend)

## Build the image

docker build -t scality/hive .

## Run the image

docker run -it scality/hive /etc/hive-bootstrap.sh -bash
