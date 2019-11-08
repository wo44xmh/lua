local p = "/home/q/system/lua_limit/"
local m_package_path = package.path
package.path = string.format("%s?.lua;%s", p, m_package_path)

local Common = require("include/common")
local Channel = require("include/channel")
local cjson = require("cjson")
--local http = require("resty.http")

--5min
local cache_time = 300

if Common.log == "debug" then
ngx.log(ngx.INFO, "start to check channel------>>")
end

-- read local cache
local limitList = ngx.shared.limit_list
if Common.log == "debug" then
  --ngx.say("local channel cache list: ", cjson.encode(limitList), "</br>")
end

-- read local expire time
local last_update_time =  Common.getCacheTime("last_update_time")
last_update_time=tonumber(last_update_time)
-- read local
now_time = tonumber(ngx.now())

local uri_args = ngx.req.get_uri_args()
local projectId = uri_args["projectId"]
local osId = uri_args["os_id"]
local channel = uri_args["channel"]
local limit_channel_list_key = Common.limit_channel_list_key

if Common.log == "debug" then
  ngx.say("now diff time :", now_time - last_update_time, "</br>")
end


if last_update_time == nil
then
    if Common.log == "debug" then
        ngx.say(" flush redis cache---->>", "</br>")
        ngx.log(ngx.INFO, "start to flush channel, redis cache to local cache------>>")
    end
    Common.flushCache(limit_channel_list_key)
else if  now_time - last_update_time >= cache_time
then
    if Common.log == "debug" then
        ngx.say(" flush redis cache---->>", "</br>")
        ngx.log(ngx.INFO, "start to flush channel, redis cache to local cache------>>")
    end
    Common.flushCache(limit_channel_list_key)
end

if projectId ~= nil then
 key = projectId
else if osId ~=  nil then
 key = projectId
else
 key = channel
end

if Common.log == "debug" then
  ngx.say("judge key = ", key, "</br>")
end
if Common.getCache(key) or key == nil or key == ""
then
  if Channel.MGZ_EU["default"] ~= nil then
      ngx.log(ngx.INFO, "your channel was Restricted default---->> , channel = " .. channel  .. ", rule:" .. Channel.MGZ_EU["default"])
      ngx.exec(Channel.MGZ_EU["default"]);
  else
        ngx.status = ngx.HTTP_FORBIDDEN
        ngx.log(ngx.INFO, "your channel was Restricted---->>  ,channel = " .. channel)
        --ngx.say(" your url request was Restricted---->> key = ", key, "</br>")
        return ngx.exit(ngx.HTTP_FORBIDDEN)
  end
end

--pass now
if Common.log == "debug" then
  ngx.say("judge pass key = ", key, "</br>")
  ngx.say(ngx.var.HOST, "</br>")
end

--redirect
if Channel.MGZ_EU[ngx.var.HOST] ~= nil then
    ngx.log(ngx.INFO, "your channel was passed---->>  ,channel = " .. channel .. ", rule:" .. Channel.MGZ_EU[ngx.var.HOST])
    ngx.exec(Channel.MGZ_EU[ngx.var.HOST]);
else if Channel.MGZ_EU["default"] ~= nil then
    ngx.log(ngx.INFO, "your channel was passed default---->> , channel = " .. channel  .. ", rule:" .. Channel.MGZ_EU["default"])
    ngx.exec(Channel.MGZ_EU["default"]);
end

return
end
end
end