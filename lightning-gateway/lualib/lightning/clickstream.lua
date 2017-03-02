--
-- Created by IntelliJ IDEA.
-- User: zhaojun
-- Date: 17/1/12
-- Time: 下午12:23
-- To change this template use File | Settings | File Templates.
--


local _util = require "lightning.util"                                 --- util.lua
local _cjson_safe = require("cjson.safe")                       --- json操作

--通用全局变量缓存
local logger = ngx.log                                          --- function ngx log
local ERR = ngx.ERR                                             --- ngx log  level
local json_decode = _cjson_safe.decode                          --- function json decode
---local json_encode = _cjson_safe.encode                       --- function json encode
local request_time = _util.request_time                         --- function 获得服务端时间
local inflate_body = _util.inflate_body                         --- function 解压body
local check_spider = _util.check_spider                         --- function 过滤爬虫
local get_ip = _util.get_ip                                     --- function 获得client ip
local check_webh5_log_param = _util.check_webh5_log_param       --- function 检查web h5 参数
local check_app_log_param = _util.check_app_log_param           --- function 检查app 参数
local check_webh5_common_param = _util.check_webh5_common_param --- function 检查web h5 公共参数
local check_app_common_param = _util.check_app_common_param     --- function 检查app 公共参数
local check_common_param = _util.check_common_param             --- function 检查公共参数
local common_param_to_log = _util.common_param_to_log           --- function 公共参数转换为log json 发送到kafka
local ipairs = ipairs                                           --- function lua foreach
local user_agent = ngx.var.http_user_agent                      --- 客户端user agent
local get_cs=_util.get_cs                                       --- function 获得请求cs 参数

-------------------------- 各大主流搜索引擎爬虫过滤---------------------------------------------
check_spider(user_agent)
-------------------------- 检查是否zlib压缩or messaegpack压缩,如果压缩，解压重新设置body参数-----------------------------
inflate_body()
-------------------------- 检查是参数合法性开始-----------------------------
local cslog= get_cs()
local json = json_decode(cslog)
if not json then
    logger(ERR, "json error log")
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

--- 解析log
local common_param = json["cm"]
local logs = json["log"]
local log_datas = {}
--- 检查公共log 参数
local common_status = check_common_param(common_param)
if not common_status then
    logger(ERR, "check_common_param error!\n")
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end
--- 获得client ip
local ip =get_ip()
local t = request_time()
local clt = common_param["clt"]
--- 检查app 参数
if clt == "app" then
    local common_app_status = check_app_common_param(common_param)
    if not common_app_status then
        logger(ERR, "check_app_common_param error!\n")
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    if not logs then
        logger(ERR, "app logs error!\n")
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    for _index,log in ipairs(logs) do
        local check_app_log_staus =  check_app_log_param(common_param,log)
        if check_app_log_staus then
            log["req"] = t
            log["ip"] = ip
            log["ua"] = user_agent
            common_param_to_log(common_param,log)
            table.insert(log_datas, log)
        end
    end

--- 检查web h5 参数
elseif clt=="web" or clt == "h5" then
   local check_webh5_status = check_webh5_common_param(common_param)
    if not check_webh5_status then
        logger(ERR, "check_webh5_common_param error!\n")
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    if not logs then
        logger(ERR, "web h5 logs error!\n")
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    for _index,log in ipairs(logs) do
        local check_webh5_log_staus =  check_webh5_log_param(common_param,log)
        if check_webh5_log_staus then
            log["req"] = t
            log["ip"] = ip
            log["ua"] = user_agent
            common_param_to_log(common_param,log)
            table.insert(log_datas, log)
        end
    end
end
-------------------------- 检查是参数合法性结束-----------------------------

-----同一个请求不同阶段共享变量 ngx.ctx -----------
if not log_datas or log_datas[1]==nil then
    logger(ERR, "log_datas error!\n")
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

ngx.ctx.messageList = log_datas







