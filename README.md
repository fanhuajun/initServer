## mysql 安装

```shell
yum install mysql
yum install mysql-server
yum install mysql-devel
chgrp -R mysql /var/lib/mysql
chmod -R 770 /var/lib/mysql
service mysqld start 
mysql
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('fhj');
```

- 如果要reboot自启动：

```shell
chkconfig --levels 345 mysqld on
```