#!/bin/bash
ifrpm=$(cat /proc/version | grep -E "redhat|centos")
ifdpkg=$(cat /proc/version | grep -Ei "ubuntu|debian")
zabbix_server=`cat /alidata/server/zabbix/etc/zabbix_server.conf |grep DBPassword= |cut -d = -f2`
zabbix_web=`cat /alidata/www/default/zabbix/conf/zabbix.conf.php |grep PASSWORD|cut -d \' -f4`
#modify ftp passwd
FTPPASS=$(date | md5sum |head -c 9)
if [ "$ifrpm" != "" ];then
	echo $FTPPASS | passwd --stdin www
else
	echo "www:$FTPPASS" | chpasswd
fi

sed -i "9s/.*/password:${FTPPASS}/" /alidata/account.log
sleep 1

#modify mysql passwd
PASS=$(date | md5sum |head -c 10)
OLDPASSWD=$(sed -n '13p' /alidata/account.log |awk -F: '{print $2}')
/alidata/server/mysql/bin/mysqladmin -uroot -p$OLDPASSWD password $PASS
sed -i "13s/.*/password:${PASS}/" /alidata/account.log
sed -i "s/$zabbix_server/$PASS/" /alidata/server/zabbix/etc/zabbix_server.conf
sed -i "s/$zabbix_web/$PASS/" /alidata/www/default/zabbix/conf/zabbix.conf.php
ZPASS=$(date | md5sum |head -c 10)
/alidata/server/mysql/bin/mysql -uroot -p$PASS -e "update zabbix.users set passwd=md5('$ZPASS') where userid='1';"
sed -i "17s/.*/password:${ZPASS}/" /alidata/account.log
if [ "$ifrpm" != "" ];then
        sed -i "/\/alidata\/init.*/d" /etc/rc.d/rc.local
else
        sed -i "/\/alidata\/init.*/d" /etc/rc.local
fi
/etc/init.d/zabbix_server restart &
