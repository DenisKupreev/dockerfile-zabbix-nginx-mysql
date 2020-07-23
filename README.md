# Dockerfile-zabbix-nginx-mysql
Simple Dockerfile for build docker image with Zabbix, include:
- Zabbix web interface
- Nginx web server 
- MySQL database

# Using
Run container:
```bash
docker run -e MYSQL_DATABASE=zabbix_db -e MYSQL_USER=zabbix_user -e MYSQL_PASSWORD=password -p 8080:80 -it idkaktys/dockerfile-zabbix-nginx-mysql
```
With volume for store MySQL data:
```bash
docker run -v /YOUR_PATH/:/var/lib/mysql -e MYSQL_DATABASE=zabbix_db -e MYSQL_USER=zabbix_user -e MYSQL_PASSWORD=password -p 8080:80 -it idkaktys/dockerfile-zabbix-nginx-mysql
```
or clone [GitHub repository](https://github.com/DenisKupreev/dockerfile-zabbix-nginx-mysql) ,  go to the directory, build image:
```bash
git clone https://github.com/DenisKupreev/dockerfile-zabbix-nginx-mysql.git
cd dockerfile-zabbix-nginx-mysql.git
docker build -t zabbix .
docker run -e MYSQL_DATABASE=zabbix_db -e MYSQL_USER=zabbix_user -e MYSQL_PASSWORD=password -p 8080:80 -it zabbix
```
Open http://localhost:8080  
Defaul login: admin  
Defaul password: zabbix  

# Environment Variables
- TZ - Time zone, default UTC
- MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD, MYSQL_HOST - Credentials for mysql, optional, by default 'zabbix', 'zabbix', 'password', 'localhost'.
