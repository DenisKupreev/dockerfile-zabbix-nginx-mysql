#!/bin/bash
ZABBIX_SERVER_CONF="/etc/zabbix/zabbix_server.conf"
ZABBIX_WEB_CONF="/etc/zabbix/web/zabbix.conf.php"
# Cheack variables
[[ "$MYSQL_USER" = "root" ]] && echo "Please set MYSQL_USER other than root" && exit 1
if [[ ! "$MYSQL_USER" ]];then
    echo "MYSQL_USER is not defined use: 'zabbix'"
    MYSQL_USER=zabbix
fi
if [[ ! "$MYSQL_HOST" ]];then
    echo "MYSQL_HOST is not defined use: 'localhost'"
    MYSQL_HOST=localhost
fi
if [[ ! "$MYSQL_PASSWORD" ]];then
    echo "MYSQL_PASSWORD is not defined use: 'password'"
    MYSQL_PASSWORD=password
fi
if [[ ! "$MYSQL_DATABASE" ]];then
    echo "MYSQL_DATABASE is not defined use: 'zabbix'"
    MYSQL_DATABASE=zabbix
fi
# Init mysql
echo "MySQL: setup starting ..."
# Cheack first start
if [ ! -f "/run/mysqld/.init" ]; then
# Create temp file
    SQL=$(mktemp)
# Cheack mount external volume
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo "MySQL: install base db"
        chown -R mysql:mysql  /var/lib/mysql
        mysql_install_db --user=mysql --datadir=/var/lib/mysql
    fi
# Build MySQL setups
    echo "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE CHARACTER SET utf8 COLLATE utf8_bin;" >> $SQL
    echo "CREATE USER '$MYSQL_USER'@'$MYSQL_HOST' identified by '$MYSQL_PASSWORD';" >> $SQL
    echo "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'$MYSQL_HOST';" >> $SQL
    echo "FLUSH PRIVILEGES;" >> $SQL
    mysqld --skip-networking &
    pid="$!"
    for i in {30..0}; do
        if echo 'SELECT 1' | "mysql" &> /dev/null; then
            break
        fi
        echo 'MySQL: init process in progress...'
        sleep 1
    done
    cat "$SQL" | mysql
# Restore zabbix db dump
    zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE
    if ! kill -s TERM "$pid" || ! wait "$pid"; then
        echo >&2 'MySQL: init process failed.'
        exit 1
    fi
    rm -rf ~/.mysql_history ~/.ash_history $SQL
# Check first start was
    touch /run/mysqld/.init
    echo "MySQL: setup finish ..."
fi
echo "php-FPM setup ..."
sed -i -e "s/;\ php_value\[date\.timezone.*$/php_value\[date\.timezone\]\ =\ UTC/" /etc/zabbix/php-fpm.conf
echo "Nginx setup ..."
rm -rf /etc/nginx/sites-enabled/default
sed -i -e "s/^#[[:space:]]*listen.*;$/\tlisten\ 80\;/" /etc/zabbix/nginx.conf
echo "Zabbix setup ..."
# Setup Zabbix server config
sed -i -e "s/DBHost.*$/DBHost=$MYSQL_HOST/" $ZABBIX_SERVER_CONF
sed -i -e "s/DBName.*$/DBName=$MYSQL_DATABASE/" $ZABBIX_SERVER_CONF
sed -i -e "s/DBUser.*$/DBUser=$MYSQL_USER/" $ZABBIX_SERVER_CONF
sed -i -e "s/^#.*DBPassword.*$/DBPassword=$MYSQL_PASSWORD/" $ZABBIX_SERVER_CONF
# Setup Zabbix WEB config
cp /usr/share/zabbix/conf/zabbix.conf.php.example $ZABBIX_WEB_CONF
sed -i -e "s/\$DB\['SERVER'\].*$/\$DB['SERVER']\t= '$MYSQL_HOST';/" $ZABBIX_WEB_CONF
sed -i -e "s/\$DB\['DATABASE'\].*$/\$DB['DATABASE']\t = '$MYSQL_DATABASE';/" $ZABBIX_WEB_CONF
sed -i -e "s/\$DB\['USER'\].*$/\$DB['USER']\t = '$MYSQL_USER';/" $ZABBIX_WEB_CONF
sed -i -e "s/\$DB\['PASSWORD'\].*$/\$DB['PASSWORD']\t = '$MYSQL_PASSWORD';/" $ZABBIX_WEB_CONF
echo "Start Supervisor"
exec "$@"