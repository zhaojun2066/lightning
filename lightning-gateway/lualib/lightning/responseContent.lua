--
-- Created by IntelliJ IDEA.
-- User: zhaojun
-- Date: 17/2/7
-- Time: 下午6:43
-- To change this template use File | Settings | File Templates.
-- 返回给client body json
local json = require("cjson")       --- josn 操作
local _json_encode = json.encode    --- function  json encode string
local _result = {
    status=1                        --- 目前就一个值，1 代表成功
}

local text = _json_encode(_result)
ngx.say(text)                       --- 返回给client




