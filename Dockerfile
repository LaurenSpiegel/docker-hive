FROM scality/hadoop

MAINTAINER Lauren Spiegel
#Installs Hive
#Builds the InMobi Hive from trunk
#Configure Postgres DB
#Starts Hive metastore Server
#Starts Hive Server2


# to configure postgres as hive metastore backend
RUN apt-get update
RUN apt-get -yq install vim postgresql-9.3 libpostgresql-jdbc-java net-tools

# create metastore db, hive user and assign privileges
USER postgres
RUN /etc/init.d/postgresql start &&\
     psql --command "CREATE DATABASE metastore;" &&\
     psql --command "CREATE USER hive WITH PASSWORD 'hive';" && \
     psql --command "ALTER USER hive WITH SUPERUSER;" && \
     psql --command "GRANT ALL PRIVILEGES ON DATABASE metastore TO hive;"
     
# revert back to default user
USER root

# dev tools to build
RUN apt-get update
RUN apt-get install -y git libprotobuf-dev protobuf-compiler
            
# install hive
ENV HIVE_VERSION=2.1.1
RUN curl -o /usr/local/hive-${HIVE_VERSION}.tar.gz "http://apache.cs.utah.edu/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz"
RUN ls /usr/local
RUN mkdir -p /usr/local/hive-dist && tar -xzvf "/usr/local/hive-${HIVE_VERSION}.tar.gz" -C /usr/local/hive-dist

# set hive environment
ENV HIVE_HOME /usr/local/hive-dist/apache-hive-${HIVE_VERSION}-bin
ENV HIVE_CONF $HIVE_HOME/conf
ENV PATH $HIVE_HOME/bin:$PATH

# add postgresql jdbc jar to classpath
RUN ln -s /usr/share/java/postgresql-jdbc4.jar $HIVE_HOME/lib/postgresql-jdbc4.jar

# to avoid psql asking password, set PGPASSWORD
ENV PGPASSWORD hive

# initialize hive metastore db
RUN /etc/init.d/postgresql start &&\
	sleep 60 &&\
	cd $HIVE_HOME/scripts/metastore/upgrade/postgres/ &&\
 	psql -h localhost -U hive -d metastore -f hive-schema-0.13.0.postgres.sql

# copy config, sql, data files to /opt/files
RUN mkdir /opt/files
ADD hive-site.xml /opt/files/
ADD hive-log4j.properties /opt/files/
ADD hive-site.xml $HIVE_CONF/hive-site.xml
ADD hive-log4j.properties $HIVE_CONF/hive-log4j.properties
ADD store_sales.* /opt/files/
ADD datagen.py /opt/files/

# set permissions for hive bootstrap file
ADD hive-bootstrap.sh /etc/hive-bootstrap.sh
RUN chown root:root /etc/hive-bootstrap.sh
RUN chmod 700 /etc/hive-bootstrap.sh

# To overcome the bug in AUFS that denies postgres permission to read /etc/ssl/private/ssl-cert-snakeoil.key file.
# https://github.com/Painted-Fox/docker-postgresql/issues/30
# https://github.com/docker/docker/issues/783
# To avoid this issue lets disable ssl in postgres.conf. If we really need ssl to encrypt postgres connections we have to fix permissions to /etc/ssl/private directory everytime until AUFS fixes the issue
ENV POSTGRESQL_MAIN /var/lib/postgresql/9.3/main/
ENV POSTGRESQL_CONFIG_FILE $POSTGRESQL_MAIN/postgresql.conf
ENV POSTGRESQL_BIN /usr/lib/postgresql/9.3/bin/postgres
ADD postgresql.conf $POSTGRESQL_MAIN
RUN chown postgres:postgres $POSTGRESQL_CONFIG_FILE





