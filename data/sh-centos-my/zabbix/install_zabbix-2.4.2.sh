#!/bin/bash
export PREFIX=/alidata/server/zabbix
rm -rf zabbix-2.4.2.tar.gz
if [ ! -f zabbix-2.4.2.tar.gz ];then
  wget http://zy-res.oss-cn-hangzhou.aliyuncs.com/zabbix/zabbix-2.4.2.tar.gz
fi
datadir=`pwd`
tar -xzvf zabbix-2.4.2.tar.gz
yum install net-snmp-devel -y
cd zabbix-2.4.2
./configure --prefix=$PREFIX --enable-server --enable-agent --with-mysql=/alidata/server/mysql/bin/mysql_config --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2
make
make install
if id zabbix &> /dev/null; then
userdel zabbix &> /dev/null && groupdel zabbix &> /dev/null && rm -rf /home/zabbix && rm -rf /var/spool/mail/zabbix &> /dev/null
fi
groupadd zabbix &> /dev/null
useradd -g zabbix zabbix &> /dev/null
usermod -s /sbin/nologin zabbix &> /dev/null
export MYSQL_PASSWORD=$(sed -n '13p'  /alidata/account.log | cut -d : -f2)
/alidata/server/mysql/bin/mysql -uroot -p$MYSQL_PASSWORD -e "drop database zabbix" &> /dev/null
/alidata/server/mysql/bin/mysql -uroot -p$MYSQL_PASSWORD -e "create database zabbix"	#创建zabbix的数据库
#导入数据到zabbix库中
/alidata/server/mysql/bin/mysql -uroot -p$MYSQL_PASSWORD zabbix < ./database/mysql/schema.sql
/alidata/server/mysql/bin/mysql -uroot -p$MYSQL_PASSWORD zabbix < ./database/mysql/images.sql
/alidata/server/mysql/bin/mysql -uroot -p$MYSQL_PASSWORD zabbix < ./database/mysql/data.sql
#修改配置文件
cd $datadir
cp $PREFIX/etc/zabbix_server.conf $PREFIX/etc/zabbix_server.conf.bak
sed -i "s/# DBHost=localhost/DBHost=localhost/g" $PREFIX/etc/zabbix_server.conf
sed -i "s/# DBPassword=/DBPassword=$MYSQL_PASSWORD/g" $PREFIX/etc/zabbix_server.conf
#添加启动脚本
cp ./zabbix-2.4.2/misc/init.d/fedora/core5/zabbix_server /etc/init.d/zabbix_server
cp ./zabbix-2.4.2/misc/init.d/fedora/core5/zabbix_agentd /etc/init.d/
chmod 700 /etc/init.d/zabbix_agentd
sed -i 's/usr\/local/alidata\/server\/zabbix/g' /etc/init.d/zabbix_agentd
sed -i 's/\/usr\/local/\/alidata\/server\/zabbix/g' /etc/init.d/zabbix_server
ln -s /alidata/server/mysql/lib/libmysqlclient.so.18 /usr/lib64/libmysqlclient.so.18
sed -i 's/post_max_size = 8M/post_max_size = 16M/g' /alidata/server/php/etc/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /alidata/server/php/etc/php.ini
sed -i 's/max_input_time = 60/max_input_time = 300/g' /alidata/server/php/etc/php.ini
sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/g' /alidata/server/php/etc/php.ini
chmod 700 /etc/init.d/zabbix_server
/etc/init.d/zabbix_server start		#启动zabbix_server
/etc/init.d/zabbix_agentd start
#添加开机自启动
if ! cat /etc/rc.local | grep "/etc/init.d/zabbix_server" > /dev/null;then 
     echo "/etc/init.d/zabbix_server  start" >> /etc/rc.local
fi
if ! cat /etc/rc.local | grep "/etc/init.d/zabbix_agentd" > /dev/null;then 
     echo "/etc/init.d/zabbix_agentd  start" >> /etc/rc.local
fi
mkdir -p /alidata/www/default/zabbix
cp -r ./zabbix-2.4.2/frontends/php/* /alidata/www/default/zabbix/
chmod 777 /alidata/www/default/zabbix/conf/
service httpd restart
#modify zabbix passwd
sleep 1
export ZPASS=$(date | md5sum |head -c 10)
/alidata/server/mysql/bin/mysql -uroot -p$MYSQL_PASSWORD -e "update zabbix.users set passwd=md5('$ZPASS') where userid='1';"
sed -i "17s/.*/password:${ZPASS}/" /alidata/account.log