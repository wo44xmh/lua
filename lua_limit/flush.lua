local p = "/lua_limit/"
local m_package_path = package.path
package.path = string.format("%s?.lua;%s", p, m_package_path)

Common = require("include/common")
--[[
Channel = require("include/channel")
if Channel.MGZ_EU ~= nil then
    for k,v in ipairs(Channel.MGZ_EU) do
          if key ~= nil then

          end
    end
end
--]]

--restrict all request
Common.setStatus(false)
--del redis cache
Common.delRedis()
--update redis cache
for value in io.lines("/lua_limit/etc_mgz.conf") do
    value = Common.trim(value)
    if value ~= nil and value ~= "" then
        Common.setRedis(value)
    end
end
Common.setStatus(true)

local limit_channel_list_key = Common.limit_channel_list_key
Common.flushCache(limit_channel_list_key)

ngx.say("flush ok")
ngx.exit(ngx.HTTP_OK)