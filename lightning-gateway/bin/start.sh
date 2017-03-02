#!/usr/bin/env bash

OPENRESTY_INSTALL_PATH="/workspace/openresty";

echo "检测nginx是否启动"
nginx_progress=`ps -ef|grep "nginx" |wc -l`

if [ $nginx_progress -gt 1 ]
then
    echo "nginx 已经启动,开始重启nginx"
    $OPENRESTY_INSTALL_PATH/nginx/sbin/nginx  -c  /lightning-gateway/conf/nginx.conf -s reload
else
    echo "nginx 没有启动,开始启动nginx"
    $OPENRESTY_INSTALL_PATH/nginx/sbin/nginx  -c  /lightning-gateway/conf/nginx.conf
fi

nginx_progress=`ps -ef|grep "nginx" |wc -l`

if [ $nginx_progress -gt 2 ]
then
    echo "nginx 启动成功"
else
    echo "nginx 启动失败"
fi
