# Dockerfile-zabbix-nginx-mysql
Simple Dockerfile for build docker image with Zabbix, include:
- Zabbix web interface
- Nginx web server 
- MySQL database

# Using
Clone repository, go to the directory, build image:

```bash
git clone https://github.com/DenisKupreev/dockerfile-zabbix-nginx-mysql.git
cd dockerfile-zabbix-nginx-mysql.git
docker build -t zabbix .
```

Run container:
```bash
docker run -e MYSQL_DATABASE=zabbix_db -e MYSQL_USER=zabbix_user -e MYSQL_PASSWORD=password -p 8080:80 -it zabbix
```
# Environment Variables
- TZ - Time zone, default UTC
- MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD, MYSQL_HOST - Credentials for mysql, optional, by default 'zabbix', 'zabbix', 'password', 'localhost'.
