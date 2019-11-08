local redis = require("resty.redis")
local _CONSTANCE = { _VERSION = "2018.6.5", OK = 1, ERROR = 2, FORBIDDEN = 3, _REDIS_IP = "127.0.0.1", _REDIS_PORT = 6379, _REDIS_AUTH = ""}
local Common = {}

Common.limit_channel_list_key = "limit_channel_list"
Common.log = "info"
Common.status = "status"
Common.flush = true

--先local，再redis，如果match，reject，otherwise，pass。。
function Common.close_redis(redisConnection)
	if not redisConnection then
		return
	end
	local pool_max_idle_time = 10000
	local pool_size = 100
	local ok, err = redisConnection:set_keepalive(pool_max_idle_time, pool_size)
	if not ok then
		ngx.say("connecton redis, error : ", err)
		ngx.log(ngx.WARN, "redis rpush error: " .. err)
	end
end

---读取ip
function Common.getIp()
    local localIp = ngx.req.get_headers()["X-Real-IP"]
    if localIp == nil then
        localIp = ngx.req.get_headers()["x_forwarded_for"]
    end
    if localIp == nil then
        localIp = ngx.var.remote_addr
    end
    return localIp
end

function Common.newReds()
   local redisConnection = redis:new()
   redisConnection:set_timeout(redis_timeout)
   local ok, err = redisConnection:connect(_CONSTANCE._REDIS_IP, _CONSTANCE._REDIS_PORT)
   if not ok then
    ngx.say("connect to redis error : ", err)
    ngx.log(ngx.WARN, "connect to redis error :" .. err)
    return Common.close_redis(redisConnection)
   end
   if _CONSTANCE._REDIS_AUTH ~= nil and  _CONSTANCE._REDIS_AUTH ~= "" then
       local red, err = redisConnection:auth(_CONSTANCE._REDIS_AUTH)
       if not red then
           ngx.say("auth redis error : ", err)
           ngx.log(ngx.WARN, "connect to redis error :" .. err)
           return Common.close_redis(redisConnection)
       end
   end
   return redisConnection
end

function Common.setRedis(value)
    local redisConnection = Common.newReds()
    if redisConnection == nil then
            ngx.log(ngx.INFO, "fuck .....>> get redis  error , return nil")
            return
    end
    local  ok, err = redisConnection:sadd(Common.limit_channel_list_key, value)
    if err then
        ngx.log(ngx.WARN, "fuck .....>> redis set error : ", err)
        return false
    else
      return true
    end
end

function Common.delRedis()
    local redisConnection = Common.newReds()
    if redisConnection == nil then
            ngx.log(ngx.INFO, "fuck .....>> get redis  error , return nil")
            return
    end
    local  ok, err = redisConnection:del(Common.limit_channel_list_key)
    if err then
        ngx.log(ngx.WARN, "fuck .....>> redis del error : ", err)
        return false
    else
      return true
    end
end

function Common.includep(value, tbl)
    for k,v in ipairs(tbl) do
      if v == value then
      return true;
      end
    end
    return false;
end

function Common.flushCache(limit_channel_list_key)
    local redisConnection = Common.newReds()
    if redisConnection == nil then
            ngx.log(ngx.INFO, "fuck .....>> get redis  error , return nil")
            return
    end
    local limitList = ngx.shared.limit_list
    local new_limit_ip_list, redisErr = redisConnection:smembers(limit_channel_list_key)

    if redisErr then
        ngx.log(ngx.INFO, "fuck .....>> redis read error while does't has the set limit_ip_list? " .. redisErr)
    else
        Common.setStatus(false)
        limitList:flush_all()

        for index,new_one_ip in ipairs(new_limit_ip_list) do
            limitList:set(new_one_ip, true)
        end
        Common.setStatus(true)
        limitList:set("last_update_time", ngx.now())
    end
end

function Common.setStatus(status)
    local limitList = ngx.shared.limit_list
    return  limitList:set(Common.status, status)
end

function Common.getStatus()
    local limitList = ngx.shared.limit_list
    return  limitList:get(Common.status)
end

function Common.getCache(section)
    local limitList = ngx.shared.limit_list
    if  not Common.getStatus() or limitList == nil then
         return true
    end
    return  limitList:get(section)
end

function Common.getCacheTime(section)
    local limitList = ngx.shared.limit_list
    return  limitList:get(section)
end

function Common.setCache(section, value)
    local limitList = ngx.shared.limit_list
    return  limitList:set(section, value)
end

function Common.response()
        if ngx.req.get_method() == "GET" then
            method = ngx.HTTP_GET
        else
            method = ngx.HTTP_POST
        end
        local postData = {
            ["method"] = method,
            ["body"] = ngx.req.get_body_data(),
        }
        local res = ngx.location.capture(ngx.var.request_uri, postData)
        ngx.status = res.status
        ngx.print(res.body)
        ngx.exit(res.status)
end

function Common.trim(s)
      return (s:gsub("^%s*(.-)%s*$", "%1"))
end

return Common