--
-- Created by IntelliJ IDEA.
-- User: zhaojun
-- Date: 17/2/7
-- Time: 下午6:43
-- To change this template use File | Settings | File Templates.
--

----生成和修改response header 信息

ngx.header['Content-Type'] = 'application/json;charset=utf-8'           --- 返回值为json
ngx.header['Encoding-Type'] = 'none'                                    --- 和app 约定一个特殊值，表示没有进行压缩



