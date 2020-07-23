FROM ubuntu:20.04
ENV TZ=UTC
ENV ZABBIX_REPO=https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z
ENV ZABBIX_MYSQL_SERVER=zabbix-server-mysql_5.0.2-1+focal_amd64.deb
ENV ZABBIX_RELEASE=zabbix-release_5.0-1+focal_all.deb
ENV ZABBIX_MYSQL_SERVER=zabbix-server-mysql_5.0.2-1+focal_amd64.deb

# Set time zone UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# First update for install wget
RUN apt update && apt -y upgrade && apt -y install wget

# Add zabbix repository and install zabbix componets
RUN wget $ZABBIX_REPO/zabbix-release/$ZABBIX_RELEASE && \
    dpkg -i ./$ZABBIX_RELEASE && rm -f ./$ZABBIX_RELEASE && apt update && \
    apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-agent

# Install mysql nginx supervisor
RUN apt install -y mysql-server nginx supervisor

# Create dirs for services
RUN mkdir -p /run/nginx /var/tmp/nginx/client_body /run/php /run/mysqld /var/run/mysqld /var/run/zabbix && \
    chown www-data:www-data -R /run/nginx /var/tmp/nginx/ /run/php && \
    chown -R mysql:mysql /run/mysqld  /var/run/mysqld && \
    chown -R zabbix:zabbix  /var/run/zabbix 

# Get zabbix db dump (I don't know why it not added when installing the package)
RUN mkdir -p /tmp/sql-tmp/ && \
    wget $ZABBIX_REPO/zabbix/$ZABBIX_MYSQL_SERVER && dpkg -x $ZABBIX_MYSQL_SERVER /tmp/sql-tmp && \
    mv /tmp/sql-tmp/usr/share/doc/zabbix-server-mysql/create.sql.gz /usr/share/doc/zabbix-server-mysql/create.sql.gz && \
    rm -rf /tmp/sql-tmp $ZABBIX_MYSQL_SERVER

# Supervisor config
COPY \
    files/supervisor.conf \
    files/php-fpm.conf \
    files/nginx.conf \
    files/mysql.conf \
    files/zabbix_server.conf \
    files/zabbix_agent.conf \
        /etc/supervisor/conf.d/

# Entrypoint
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# For database stor 
VOLUME /var/lib/mysql

# Ports
EXPOSE 80

# Init commands
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord"]
