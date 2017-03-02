--
-- Created by IntelliJ IDEA.
-- User: zhaojun
-- Date: 17/1/12
-- Time: 下午12:23
-- To change this template use File | Settings | File Templates.
-- require 只会在第一次调用时候，被执行，之后所有的请求都会适用应加载好的实例

local _producer = require "resty.kafka.producer"                        --- lua kafka package
local _cjson_safe = require("cjson.safe")                               --- json操作
local _config = require "lightning.config"                                     --- 公共配置

local logger = ngx.log                                                  --- function  ngx log
local ERR = ngx.ERR                                                     --- function  ngx log level
--local json_decode = _cjson_safe.decode                                --- function json decode string to json ojbect
local json_encode = _cjson_safe.encode                                  --- function json encode to string
local BROKER_LIST = _config.BROKER_LIST                                 --- kafka broker list
local KAFKA_CONFIG = _config.KAFKA_CONFIG                               --- kafka cofnig for producer
local cs_msg = ngx.ctx.messageList                                      --- log message list
if cs_msg then
    local json = cs_msg
    -- this is async producer_type and bp will be reused in the whole nginx worker
    local kafka_producer=_producer:new(BROKER_LIST, KAFKA_CONFIG)
    for _index,v in ipairs(json) do
        if v then
            local topic = v["tpc"]
            local key = v["sig"] --ngx.md5(ngx.time()..v["sig"])
            local data = json_encode(v)
            ---logger(ERR,"D-: "..data)
            if topic then
                local ok, err = kafka_producer:send(topic, key, data)
                if(not ok)then
                    logger(ERR,"KafkaErr: "..err)
                    logger(ERR,"ErrMsg: "..data)
                end
            end
        end
    end
end








