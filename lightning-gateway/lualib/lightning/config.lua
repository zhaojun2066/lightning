--
-- Created by IntelliJ IDEA.
-- User: zhaojun
-- Date: 17/1/12
-- Time: 下午12:23
-- To change this template use File | Settings | File Templates.
-- 点击公共配置

--[[
Kafka in async model
The message will write to the buffer first.
It will send to the kafka server when the buffer
exceed the batch_num, or every flush_time flush the buffer.
 ]]

_Config={
    --- kafka broker list
    BROKER_LIST = {
        { host = "10.10.20.91", port = 9092 },
        { host = "10.10.20.92", port = 9092 },
        { host = "10.10.20.913", port = 9092 },
    },
   --[[ BROKER_LIST = {
        { host = "10.45.145.117", port = 9092 },
        { host = "10.25.132.20", port = 9092 },
        { host = "10.25.132.41", port = 9092 },
    },]]
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
    MD5_KEY="e2kU@-%K1a)0)+!*ZJ",
    ---过滤的爬虫网站
    SPIDER_REG="Googlebot|Mediapartners-Google|Adsbot-Google|Feedfetcher-Google|Yahoo! Slurp China|Yahoo! Slurp|bingbot/2.0|msnbot/1.0|Baiduspider|Sogou web spider/4.0|Sogou inst spider/4.0|360Spider|qihoobot|YoudaoBot|Sosospider|iaskspider",
    DID_LENGTH=32,                          --- did 长度
    TIMESTAMP_LENGTH=13,                    --- 时间戳长度
    DST_ANDROID="1",                        --- 设备android
    DST_IOS="2"                             --- 设备IOS

}


return _Config

