#!/bin/bash

web=apache
export httpd_version=2.2.27
web_dir=httpd-${httpd_version}
export web_dir

userdel www
groupadd www
useradd -g www -M -d /alidata/www -s /sbin/nologin www &> /dev/null

mkdir -p /alidata
mkdir -p /alidata/server
mkdir -p /alidata/server/openssl
mkdir -p /alidata/www
mkdir -p /alidata/init
mkdir -p /alidata/log
mkdir -p /alidata/log/php
mkdir -p /alidata/log/mysql
chown -R www:www /alidata/log



mkdir -p /alidata/server/${web_dir}
if echo $web |grep "nginx" > /dev/null;then
mkdir -p /alidata/log/nginx
mkdir -p /alidata/log/nginx/access
ln -s /alidata/server/${web_dir} /alidata/server/nginx
else
mkdir -p /alidata/log/httpd
mkdir -p /alidata/log/httpd/access
ln -s /alidata/server/${web_dir} /alidata/server/httpd
fi