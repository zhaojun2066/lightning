--
-- Created by IntelliJ IDEA.
-- User: zhaojun
-- Date: 17/1/12
-- Time: 下午2:29
-- To change this template use File | Settings | File Templates.
--

local ERR = ngx.ERR                 --- ngx log level
local logger = ngx.log              --- ngx log

print("开始初始化模块以及加载配置")
_uuid = require 'resty.jit-uuid'    --- 生成uuid，用于web和h5 生成did 写入cookie
local x = os.clock()
--加载配置
_config = require "lightning.config"

if not _config  then
    logger(ERR, "parse configs error!");
end
_uuid.seed()                        --- very important! 初始化uuid
print("end初始化模块以及加载配置结束,耗时: "..(os.clock() - x).." s \\n  ")

