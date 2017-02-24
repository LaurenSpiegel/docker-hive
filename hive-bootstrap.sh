#!/bin/bash

echo "Starting postgresql server..."
sudo -u postgres $POSTGRESQL_BIN --config-file=$POSTGRESQL_CONFIG_FILE
sleep 60

#start hadoop bootstrap script
/etc/bootstrap.sh

sleep 60


# start hive metastore server
$HIVE_HOME/bin/hive --service metastore &

wait

# start hive server
$HIVE_HOME/bin/hive --service hiveserver2 &

sleep infinity
