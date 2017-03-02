--
-- Created by IntelliJ IDEA.
-- User: zhaojun
-- Date: 17/1/18
-- Time: 下午6:26
-- 公共方法
---在http连接下
---当setSecure（true）时，浏览器端的cookie会不会传递到服务器端？
---当setSecure（false）时，服务器端的cookie会不会传递到浏览器端？
---答案：1）不会 ； 2）会
---secure值为true时，在http中是无效的；在https中才有效。
--

local _zlib = require("zlib")                --- zlib压缩
local ck = require 'resty.cookie'            --- cookie 设置
local cjson_safe = require("cjson.safe")     --- json操作
local msgpack = require 'resty.MessagePack'  --- messagepack 协议
local _config = require "lightning.config"          --- 配置文件

local json_encode = cjson_safe.encode        --- function  encode json 字符串



local ERR = ngx.ERR                         ---日志级别
local logger = ngx.log                      ---function  ngx logger

local md5 = ngx.md5                          --- function md5
local MD5_KEY = _config.MD5_KEY              --- 生成sig 的 key
local SPIDER_REG = _config.SPIDER_REG        --- 过滤个大搜索引擎爬虫
local DID_LENGTH=_config.DID_LENGTH          --- did 长度
local TIMESTAMP_LENGTH=_config.TIMESTAMP_LENGTH   --- 时间戳长度
local DST_ANDROID=_config.DST_ANDROID        --- 设备系统类型 android
local DST_IOS=_config.DST_IOS                --- 设备系统类型 ios
local MD5_LIST_APP = _config.MD5_LIST_APP
local MD5_LIST_WEB_H5 = _config.MD5_LIST_WEB_H5

local _Util = {}
--- 获得服务端时间
function _Util.request_time()
    local ngx_time = ngx.time();
    local server_time=os.date("%Y-%m-%d %H:%M:%S",ngx_time);
    return server_time;
end

---获得get post参数values
function _Util.get_args()
    local args = {}
    local request_method = ngx.var.request_method
    if "GET" == request_method then
        args = ngx.req.get_uri_args()
    elseif "POST" == request_method then
        ngx.req.read_body()  --log_by_lua 阶段不能使用
        args = ngx.req.get_post_args()
    end
    return args
end

---解压body gzip 压缩 or messagepack 压缩
function _Util.inflate_body()
    local encoding =  _Util.get_countent_encoding()
    if encoding == "gzip" then
        ngx.req.read_body()  --log_by_lua 阶段不能使用
        local body = ngx.req.get_body_data()
        if body then
            local stream = _zlib.inflate()
            local inflated, eof, bytes_in, bytes_out =  stream(body)
            ngx.req.set_body_data(inflated)
        end
    elseif encoding == "msgpack" then
        ngx.req.read_body()  --log_by_lua 阶段不能使用
        local body = ngx.req.get_body_data()
        if body then
            local message =  msgpack.unpack(body)
            local message_data = _Util.meassgepack_to_log(message)
            local json_data = json_encode(message_data)
            local body_data = "cs=" .. json_data
            ngx.req.set_body_data(body_data)
        end
    end
end

--- messagepack 反序列化body 为lua对象
function _Util.meassgepack_to_log(message)
    local cs = {}
    if message then
        local cm = message[1]
        local logs = message[2]
        if cm and logs then
            local commom =_Util.messagepack_to_common(cm)
            cs["cm"] = commom
            local log = _Util.messagepack_to_log_set(logs)
            cs["log"] = log
        end
    end
    return cs
end

---messagepack 对象转换为log 数组
function _Util.messagepack_to_log_set(logs)
    local log_data = {}
    if logs  then
        for _index,log in ipairs(logs) do
            local l = {}
            local typ = log[1]
            if typ then
             l["typ"]= typ
            end
            local pid = log[2]
            if pid then
                l["pid"]= pid
            end

            local ppid = log[3]
            if ppid then
                l["ppid"]= ppid
            end

            local eid = log[4]
            if eid then
                l["eid"]= eid
            end
            local pno = log[5]
            if pno then
                l["pno"]= pno
            end
            local net = log[6]
            if net then
                l["net"]= net
            end
            local sn = log[7]
            if sn then
                l["sn"]= sn
            end
            local url = log[8]
            if url then
                l["url"]= url
            end

            local ref = log[9]
            if ref then
                l["ref"]= ref
            end

            local ct = log[10]
            if ct then
                l["ct"]= ct
            end
            local lon = log[11]
            if lon then
                l["lon"]= lon
            end
            local lat = log[12]
            if lat then
                l["lat"]= lat
            end
            local data = log[13]
            if data then
                l["data"]= data
            end

            local sig = log[14]
            if sig then
                l["sig"]= sig
            end
            table.insert(log_data,l);
        end

    end
    return log_data
end

---messagepack 对象转换为common公共参数
function _Util.messagepack_to_common(cm)
    local commom = {}
    local ver  = cm[1]
    if  ver  then
        commom["ver"] = ver
    end
    local clt  = cm[2]
    if  clt then
        commom["clt"] = clt
    end
    local pf  = cm[3]
    if  pf then
        commom["pf"] = pf
    end

    local tpc  = cm[4]
    if  tpc then
        commom["tpc"] = tpc
    end
    local did  = cm[5]
    if  did then
        commom["did"] = did
    end
    local amd  = cm[6]
    if  amd then
        commom["amd"] = amd
    end

    local uid  = cm[7]
    if  uid then
        commom["uid"] = uid
    end
    local sid  = cm[8]
    if  sid then
        commom["sid"] = sid
    end

    local dsv  = cm[9]
    if  dsv then
        commom["dsv"] = dsv
    end

    local dt  = cm[10]
    if  dt then
        commom["dt"] = dt
    end
    local dst  = cm[11]
    if dst then
        commom["dst"] = dst
    end

    local apv  = cm[12]
    if apv then
        commom["apv"] = apv
    end

    local lag  = cm[13]
    if lag then
        commom["lag"] = lag
    end

    local fr  = cm[14]
    if  fr then
        commom["fr"] = fr
    end
    local scr  = cm[16]
    if scr then
        commom["scr"] = scr
    end
    local lc  = cm[17]
    if lc then
        commom["lc"] = lc
    end

    return commom
end

---获得page content encoding
function _Util.get_countent_encoding()
    return  ngx.req.get_headers()["Content-Encoding"]
end

--- 获得请求 cs 参数value
function _Util.get_cs()
    local args = _Util.get_args()
    local cs = args["cs"]
    if not cs then
        logger(ERR, "cs error!\n")
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
    cs = ngx.unescape_uri(cs) --- url param decode
    return cs
end
function _Util.get_app_md5_sig(common_param,log_param)
    local va = ""
    for _index,data in ipair(MD5_LIST_APP) do
        local d = common_param[data]
        if not d then
            d = log_param[data]
        end
        va = va..data
    end

    va = MD5_KEY .. va .. MD5_KEY
    return md5(va)
end

function _Util.get_web_h5_md5_sig(common_param,log_param)
    local va = ""
    for _index,data in ipair(MD5_LIST_APP) do
        local d = common_param[data]
        if not d then
            d = log_param[data]
        end
        va = va..data
    end

    va = MD5_KEY .. va .. MD5_KEY
    return md5(va)
end

--- 检查web h5 log 参数
function _Util.check_webh5_log_param(common_param,log_param)
    if log_param then
        local tpc = common_param["tpc"]
        local fr = common_param["fr"]
        local typ = log_param["typ"]
        if not typ then
            return false
        end
        if typ~="e" and typ ~="p" then
            return false
        end
        local ct = log_param["ct"]
        if not ct then
            return false
        end
        if  string.len(ct) ~= TIMESTAMP_LENGTH then
            return false
        end
        local eid = log_param["eid"]
        if not eid then
            return false
        end
        local url = log_param["url"]
        if not url then
            return false
        end
        local signature = log_param["sig"]
        if not signature then
            return false
        end
        local s_signature = _Util.get_web_h5_md5_sig(common_param,log_param)
        if s_signature ~= signature then
            logger(ERR, "web h5 signature err -> " .. signature .. ",s_signature->" .. s_signature)
            return false
        end
        return true
    else
        return false
    end
end


---- 检查app log 参数
function _Util.check_app_log_param(common_param,log_param)
    if log_param then
        local tpc = common_param["tpc"]
        local did = common_param["did"]
        local fr = common_param["fr"]
        local typ = log_param["typ"]
        if not typ then
            logger(ERR, "typ nil ")
            return false
        end
        if typ~="e" and typ ~="p" then
            logger(ERR, "app typ err " .. typ.."\n")
            return false
        end
        local ct = log_param["ct"]
        if not ct then
            logger(ERR, "app ct nil ")
            return false
        end
        if  string.len(ct) ~= 13 then
            logger(ERR, "app ct length nil ")
            return false
        end
        local eid = log_param["eid"]
        if not eid then
            logger(ERR, "app eid nil ")
            return false
        end
        local signature = log_param["sig"]
        if not signature then
            logger(ERR, "app sig nil ")
            return false
        end
        local s_signature = _Util.get_app_md5_sig(common_param,log_param)
        if signature ~= s_signature then
            logger(ERR, "app signature err -> " .. signature .. ",s_signature->" .. s_signature)
            return false
        end
        return true
    else
        return false
    end
end

--- 检查web h5 公共参数
function _Util.check_webh5_common_param(common_param)
    local did = common_param["did"]
    if not did then
        _Util.set_cookie()
        return true
    elseif string.len(did) ~= DID_LENGTH then
        return false
    end
    return true
end



--- 检查app 公共参数
function _Util.check_app_common_param(common_param)
    local amd = common_param["amd"]
    if not amd then
        return false
    end
    --app did not and length 32
    local did = common_param["did"]
    if not did then
        logger(ERR, "app did nil \n")
        return false
    end
    if  string.len(did) ~= DID_LENGTH then
        logger(ERR, "app did length nil\n ")
        return false
    end
    local dsv = common_param["dsv"]
    if not dsv then
        logger(ERR, "app dsv  nil \n")
        return false
    end
    local dt = common_param["dt"]
    if not dt then
        logger(ERR, "app dt  nil \n")
        return false
    end
    local dst = common_param["dst"]
    if not dst then
        logger(ERR, "app dst  nil \n")
        return false
    end
    if dst ~=DST_ANDROID and dst~=DST_IOS then
        logger(ERR, "app dst  err "..dst.."\n")
        return false
     end
    local apv = common_param["apv"]
    if not apv then
        logger(ERR, "app apv  nil \n")
        return false
    end
    local scr = common_param["scr"]
    if not scr then
        logger(ERR, "app scr  nil \n")
        return false
    end
    return true
    --lc lat lon  不一定能够拿到，不做检查
end

--- 检查公共参数
function _Util.check_common_param(common_param)
    if common_param then
        local ver = common_param["ver"]
        if not ver then
            logger(ERR, "common ver  nil \n")
            return false
        end
        local clt = common_param["clt"]
        if not clt then
            logger(ERR, "common clt  nil \n")
            return false
        end
        if clt~="app" and clt~="web" and clt ~="h5" then
            logger(ERR, "common clt  err "..clt)
            return false
        end
        local pf = common_param["pf"]
        if not pf then
            logger(ERR, "common pf  nil \n")
            return false
        end

        local tpc = common_param["tpc"]
        if not tpc then
            logger(ERR, "common tpc  nil \n ")
            return false
        end
        ---TODO:检查tpc 的值
        local lag = common_param["lag"]
        if not lag then
            logger(ERR, "common lag  nil \n")
            return false
        end
        local fr = common_param["fr"]
        if not fr then
            logger(ERR, "common fr  nil \n")
            return false
        end
    else
        return false
    end

    return true
end

---检查did长度
function _Util.check_did(did)
    if did and string.len(did) == DID_LENGTH then
        return true
    else
        return false
    end
end



---web h5 设置did 到cookie
function _Util.set_cookie()
    local did
    local _ck, err = ck:new()
    if not _ck then
        logger(ERR, "_cookie err -> " ..err)
    end
    if _ck then
        local _did, err = _ck:get("did") --ngx.var.cookie_did
        if not _did then
            local _expiretime = ngx.time();
            --uuid超时时间10 年
            local _max_age = 10*365*24*60*60
            local _did_expiretime = ngx.cookie_time(_expiretime+_max_age);
            did = md5(_uuid.generate_v4())
            local ok, err = _ck:set({
                key = "did",
                value = did,
                path = "/",
                domain = "xiaoka.tv",
                --secure = true, --https 才会使用
                httponly = true,
                expires = _did_expiretime,
                max_age = _max_age
            })
            if not ok then
                logger(ERR, "cookie err -> " ..err)
            end
        else
            did = _did
        end

    end

    return did

end

---过滤爬虫
function _Util.check_spider(user_agent)
    if not user_agent then
        logger(ERR, "check user_agent error!\n")
        --return ngx.req.set_uri(ngx.unescape_uri("/empty-gif"), true)
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    local test_log_err, err = ngx.re.match(user_agent, SPIDER_REG)
    if test_log_err then
        logger(ERR, "Crawler ip is " .. ngx.var.u_remote_addrx .. "; UA is " .. user_agent.."\n")
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
end

---检查cs参数是否为空
function _Util.check_cs()
    local args = _Util.get_args() --获得所有参数
    if not args then --如果request当中取不到任何参数 直接返回
        logger(ERR, "check request args error!\n")
        --return ngx.req.set_uri(ngx.unescape_uri("/empty-gif"), true)
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end

    local cslog = args["cs"]
    if not cslog then
        logger(ERR, "check cs args is nil error!\n")
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
    end
end


---获得client ip
function _Util.get_ip()
    local ip = ngx.req.get_headers()["X-Real-IP"]
    if not ip then
        ip = ngx.req.get_headers()["x_forwarded_for"]
    end
    if not ip then
        ip = ngx.var.remote_addr
    end
    return ip
end

--- string split ,in function  string.gsub not jit ,please use ngx.reg.gsub
function _Util.split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local rt= {}
    string.gsub(str, '[^'..delimiter..']+', function(w) table.insert(rt, w) end )
    return rt
end

---公共参数添加单条log 最后发送给kafka
function _Util.common_param_to_log(common_param,log)
    log["clt"]  = common_param["clt"]
    log["pf"]  = common_param["pf"]
    log["tpc"]  = common_param["tpc"]
    log["ver"]  = common_param["ver"]
    log["did"]  = common_param["did"]
    log["amd"]  = common_param["amd"]
    log["uid"]  = common_param["uid"]
    log["sid"]  = common_param["sid"]
    log["dsv"]  = common_param["dsv"]
    log["dt"]  = common_param["dt"]
    log["dst"]  = common_param["dst"]
    log["apv"]  = common_param["apv"]
    log["lag"]  = common_param["lag"]
    log["fr"]  = common_param["fr"]
    log["scr"]  = common_param["scr"]
    log["lc"]  = common_param["lc"]
end


return _Util



