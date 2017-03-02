--
-- Created by IntelliJ IDEA.
-- User: zhaojun
-- Date: 17/1/22
-- Time: 上午10:50
-- To change this template use File | Settings | File Templates.
--日志文件上传模块


local _util = require "lightning.util"                                             --- util.lua
local upload = require "resty.upload"                                       --- 文件上传
local _cjson_safe = require("cjson.safe")                                   --- json操作
local _zlib = require("zlib")                                               --- zlib 解压缩

local ipairs = ipairs                                                      --- function lua foreach
local ERR = ngx.ERR                                                        --- ngx log level
local logger = ngx.log                                                     --- function ngx log
local json_decode = _cjson_safe.decode                                     --- function json decode
local request_time = _util.request_time                                    --- function 服务端时间
local check_webh5_log_param = _util.check_webh5_log_param                  --- function 检查web h5 参数
local check_app_log_param = _util.check_app_log_param                      --- function 检查app 参数
local check_webh5_common_param = _util.check_webh5_common_param            --- function 检查web h5 公共参数
local check_app_common_param = _util.check_app_common_param                --- function 检查app 公共参数
local check_common_param = _util.check_common_param                        --- function 检查公共参数
local common_param_to_log = _util.common_param_to_log                      --- function 转换为log message 发送到kakfa
local inflate_body = _util.inflate_body                                    --- function 解压缩body
local check_spider = _util.check_spider                                    --- function 过滤爬虫
local get_ip = _util.get_ip                                                --- function 获得client ip
local user_agent = ngx.var.http_user_agent                                 --- 获得user agent

-------------------------- 各大主流搜索引擎爬虫过滤---------------------------------------------
check_spider(user_agent)
-------------------------- 检查是否zlib压缩,如果压缩，解压重新设置body参数-----------------------------
inflate_body()


--- 获得文件后缀
function get_file_extension(str)
    ngx.re.match(str,".+%.(%w+)$","o")
end

--- 获得文件名字
function get_filename(res)
    local filename = ngx.re.match(res,'(.+)filename="(.+)"(.*)','o')
    if filename then
        return filename[2]
    end
end

--- 文件上传
function handle_uploading()
    local chunk_size = 512
    local form, err = upload:new(chunk_size)
    local value=""
    local log_datas = {}
    local file_extension
    form:set_timeout(1000) -- 1 sec
    if not form then
        logger(ERR, "failed to new upload: ", err)
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    while true do
        local typ, res, err = form:read()
        if not typ then
            logger(ERR, "form failed to read: ", err)
            return ngx.exit(ngx.HTTP_BAD_REQUEST)
        end
        if typ == "header" then
            logger(ERR, "res -> " .. _cjson_safe.encode(res))
            local content = res[1]
            if content ~= "Content-Type" and content~="Content-Length" then
                local file_name = get_filename(res[2])
                if not file_name  then
                    logger(ERR, "file name err -> " .. file_name)
                    return ngx.exit(ngx.HTTP_BAD_REQUEST)
                end
                file_extension = get_file_extension(file_name)
            end
        elseif typ == "body" then
            if res then
                if file_extension and file_extension ==".gz" then
                    local stream = _zlib.inflate() ---压缩文件 进行解压
                    value = stream(res)
                else
                    value =value..res
                end
            end
        elseif typ == "part_end" then
            if value and value~="" then
                local json = json_decode(value)
                if not json then
                    logger(ERR, "upload json error log")
                    return ngx.exit(ngx.HTTP_BAD_REQUEST)
                end
                local common_param = json["cm"]
                local logs = json["log"]
                local common_status = check_common_param(common_param)
                if not common_status then
                    return ngx.exit(ngx.HTTP_BAD_REQUEST)
                end
                local t = request_time()
                --获得client ip
                local ip =get_ip()
                local clt = common_param["clt"]
                --- 检查app 参数
                if clt == "app" then
                    local common_app_status = check_app_common_param(common_param)
                    if not common_app_status then
                        return ngx.exit(ngx.HTTP_BAD_REQUEST)
                    end
                    if not logs then
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
                        return ngx.exit(ngx.HTTP_BAD_REQUEST)
                    end
                    if not logs then
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


            end

        elseif typ == "eof" then
            if value and log_datas then
                ngx.ctx.messageList = log_datas
            end
            break
        end
    end

end



handle_uploading()


