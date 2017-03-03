# lightning
服务收集app web h5 埋点信息，openresty 实现
支持文件上传/zlib压缩/messagepack

### 安装openresty
    [1] 安装依赖包   
        yum install -y gcc gcc-c++ readline-devel pcre-devel openssl-devel tcl perl  
   
    
    [2] 安装openresty  
        tar zxvf ngx_openresty-{Version}.tar.gz    
        cd ngx_openresty-{Version} 
        ./configure --prefix=/usr/local/openresty   
        make    
        make install 
### 依赖       
[lua-resty-jit-uuid](https://github.com/thibaultcha/lua-resty-jit-uuid)

[lua-resty-cookie](https://github.com/cloudflare/lua-resty-cookie)

[lua-MessagePack](https://github.com/fperrad/lua-MessagePack)

[lua-resty-upload](https://github.com/openresty/lua-resty-upload)

[lua-zlib](https://github.com/brimworks/lua-zlib) 

### 运行
        修改bin/start.sh  
        OPENRESTY_INSTALL_PATH 为你的openresty 安装路径 
        修改配置文件路径为你nginx.conf的路径  
        修改bin/stop.sh 同上  

        修改conf/nginx.conf 里面加载lua的路径指向到该项目路径  

        启动重启：  
        sh bin/star.tsh  
        停止：  
        sh bin/stop.sh 
### 修改相关配置  

        lightning-gataway/lualib/lightning/config.lua 
        _Config={
                --- kafka broker list
                BROKER_LIST = { 
                    { host = "", port = 9092 }, 
                    { host = "", port = 9092 }, 
                    { host = "", port = 9092 }, 
                }, 
                --- kafka config  one ngx worker one kafka client or producer instance 
                KAFKA_CONFIG= { 
                    producer_type = "async",            ---异步 
                    socket_timeout = 6000,              --- request_timeout 
                    max_retry = 2,                      --- 重试次数 
                    refresh_interval = 600 * 1000,      ---auto refresh the metadata in milliseconds. 
                    keepalive_timeout = 600 * 1000,     ---connection timeout 10 min 
                    keepalive_size = 40,                --- pool size for each nginx worker 
                    max_buffering = 1000000,             --- queue size 
                    flush_time=100,                     --- send kafka XX ms 
                    batch_num=500                       --- 批量大小，当队列内达到500时进行一个send 到kakfa 
                },
                --- MD5 key 
                MD5_KEY="oifsoifosdfsdifodsfs", 
                ---过滤的爬虫网站 
                SPIDER_REG="Googlebot|Mediapartners-Google|Adsbot-Google|Feedfetcher-Google|Yahoo! Slurp China|Yahoo! Slurp|bingbot/2.0|msnbot/1.0|Baiduspider|Sogou web spider/4.0|Sogou inst spider/4.0|360Spider|qihoobot|YoudaoBot|Sosospider|iaskspider", 
                DID_LENGTH=32,                          --- did 长度限制 
                TIMESTAMP_LENGTH=13,                    --- 时间戳长度限制 
                DST_ANDROID="1",                        --- 设备android 
                DST_IOS="2",                            --- 设备IOS 
                MD5_LIST_APP={"fr","ct","tpc","did","eid"},  --- app md5生成签名的字段拼接顺序 
                MD5_LIST_WEB_H5={"fr","ct","tpc","url","eid"}  --- web h5 md5生成签名的字段拼接顺序 

            } 
             
### 埋点字段  
     
    字段 | 来源 | 是否必填  | 说明  
    ----|------|----|----
    req | 服务端  | 是  | 请求到达时间
    ua | 服务端  | 是  | user agent
    ip | 服务端  | 是  | client ip
    clt | 客户端  | 是  | 终端类型 [app web h5]
    pf | 客户端  | 是  |  平台类型，哪个平台在调用数据接口
    typ | 客户端  | 是  | 事件类型 p: 进入页面事件，e: 页面内事件（点击曝光等）
    tpc | 客户端  | 是  | 具体在给哪个业务或者产品在埋点，也是发给kafka的topic
    pid | 客户端  | 是  | 页面id
    ppid | 客户端  | 是  | 父页面id
    eid | 客户端  | 是  |  事件id
    pno | 客户端  | 是  | 页面访问深度
    ver | 客户端  | 是  | 日志版本
    data | 服务端  | 是  | 业务字段，服务端传递给客户段要埋点的数据
    did | 客户端  | 是  | 设备id ，app 端必须传，web h5 为空，服务端会将did写入cookie
    amd | 客户端  | 否  | imei,idfa
    uid | 客户端  | 否  | 用户id
    sid | 客户端  | 否  | 会话 session id
    dsv | 客户端  | 是  | 设备系统版本 app 必须传递
    dt | 客户端  | 是  | 设备类型 app 必须传递
    dst | 客户端  | 是  | 设备系统类型 1 android 2 ios app 必须传递
    dsv | 客户端  | 是  | 设备系统版本 app 必须传递
    apv | 客户端  | 是  | 应用版本 app version  app 必须传递
    lag | 客户端  | 是  | 客户端语言 app 必须传递
    fr | 客户端  | 是  | app 下载来源
    net | 客户端  | 是  | 网络类型 2－4  : 2-4g ，5:wifi ，1：其他  app 必须传递
    scr | 客户端  | 是  | 屏幕分辨率 app 必须传递
    lon | 客户端  | 否  | 经度 app 必须传递
    lat | 客户端  | 否  | 纬度 app 必须传递
    ct | 客户端  | 是  | 客户端时间戳 ms 
    lc | 客户端  | 否  | 登陆方式
    sn | 客户端  | 是  | 请求域名 web h5 必须传递
    url | 客户端  | 是  | 请求的url web h5 必须传递
    refer | 客户端  | 是  | 请求的refer url web h5 必须传递
    sig | 客户端  | 是  | 签名


### 埋点信息  
        {
        "cm": {
            "ver": "2", //日志版本
            "clt": "app",//终端类型 app web h5
            "pf": "demo", //平台
            "tpc": "recommder",
            "did": "ce9ca2eb2a9a9f964ef895ab084ce12b", //设备id，浏览器id
            "amd": "ce9ca2eb2a9a9f964ef895ab084ce12b", //imei｜idfa 
            "uid": "9000032",  //用户id
            "sid": "9f964ef895ab084ce",//会话session id
            "dsv": "4.0", //设备系统版本
            "dt": "HM 1s", //设备类型
            "dst": "1",//设备系统类型  1 android 2 ios
            "apv": "1.3.5",//app 版本号
            "lag": "zh", //客户端语言
            "fr": "appStore",//app下载来源
            "scr": "1027*777",//屏幕分辨率
            "lc": "qq" //登陆方式
        },
        "log": [
            {
                "typ": "e",// 事件类型 e or p 两个事件 e页面内事件 p 进入页面事件
                "pid": "00011",//页面id，和进入页面的p事件 eid 一样
                "ppid": "00010",//父页面id
                "eid": "00011",// 事件id
            "pno": "10",//页面访问深度
            "net": "1",//网络类型2－4  : 2-4g ，5:wifi ，1：其他
            "sn": "www.xxx.com",//请求数据的域名
            "url": "/login",//当前url
            "ref": "/register",//refer url
            "ct": "1486915200000",//client 时间戳
            "lon": 89.09, //经纬度
            "lat": 88.09,
            "data": {// 业务数据 由服务端传递给client 进行埋点
                "rec": "2.12.20.jn.zk"
            },
            "sig": "2160ed0e47607e1e53fd5aaed41f7e73"//生成的签名
        },{
            "typ": "e",
            "pid": "00011",
            "ppid": "00010",
                        "eid": "00011",
                        "pno": 10,
                        "net": 1,
                        "sn": "www.xxx.com",
                        "url": "/login",
                        "ref": "/register",
                        "ct": "1486915200000",
                        "lon": 89.09,
                        "lat": 88.09,
                        "data": {
                            "rec": "2.12.20.jn.zk"
                        },
                        "sig": "2160ed0e47607e1e53fd5aaed41f7e73"
                    }
                ]
            }
    
### Kafka接受json 格式 message
    {
            "ver": "2",
            "clt": "app",
            "pf": "demo",
            "tpc": "rec",
            "did": "ce9ca2eb2a9a9f964ef895ab084ce12b",
            "amd": "ce9ca2eb2a9a9f964ef895ab084ce12b",
            "uid": "9000032",
            "sid": "9f964ef895ab084ce",
            "dsv": "4.0",
            "dt": "HM 1s",
            "dst": 1,
            "apv": "1.4.5",
            "lag": "zh",
            "fr": "appStore",
            "scr": "1027*777",
            "lc": "wx",
            "req":"140023432423423",
            "ua":"user agent",
            "ip":"10.20.22.172",
            "typ": "e",
            "pid": "00011",
            "ppid": "00010",
            "eid": "00011",
            "pno": "10",
            "net": "1",
            "sn": "www.xx.com",
            "url": "/login",
            "ref": "/register",
            "ct": "1486915200000",
            "lon": "89.09",
            "lat": "88.09",
            "data": {
                "rec": "2.12.20.jn.zk"
            },
            "sig": "2160ed0e47607e1e53fd5aaed41f7e73"
    }
