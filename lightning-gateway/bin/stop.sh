#!/usr/bin/env bash

OPENRESTY_INSTALL_PATH="/workspace/openresty";

echo "检测nginx是否启动"
nginx_progress=`ps -ef|grep "nginx" |wc -l`

if [ $nginx_progress -gt 1 ]
then
    echo "nginx 已经启动,开始停止nginx"
    $OPENRESTY_INSTALL_PATH/nginx/sbin/nginx  -c  /lightning-gateway/conf/nginx.conf -s quit
    echo "nginx 已经停止"
else
    echo "nginx 没有启动,开始启动nginx"
fi

