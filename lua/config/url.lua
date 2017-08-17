local Url = {}

---------正常情况下访问路径
Url.path = "/public/index.php"

---------非缓存的情况下
Url.noCachePath = ""

---------要被替换的路由 key支持正则,key将被替换成val
Url.reg = {
    ["/service"] = ""

}

---------url 对应的路径字段配置 key中不能存放[,]等符号 page参数只能放在get方式中
Url.keys = {
    ["/themesrequest"] = {
        ["get"] = {
            ["test"] = 1
        },
        ["page"] = {["name"] = "page", ["num"] = 3},
        ["postPre"] = "test",
        ["post"] = {
            ["product"] = 1, ["width"] = 1
        }
    },
}
function Url.get(url, method)
  return Url.keys[url][method]
end
--------根据指定的configkeys 字段 把url 参数 table对应的字段提取出来 组成一个字符串
function Url.getParams(urlKey, args, configKeys)
  for key, val in pairs(args) do
        if type(val) == "table" then
            if val then
                urlKey = urlKey .. Url.getParams('', val, configKeys)
            end
        else
            temp = configKeys[key]
            if (temp ~= nil) then
                urlKey = urlKey .. "&" .. key .. "=" .. val
            end
        end
  end
  return urlKey
end

--------根据指定的字段 把args page取出来
function Url.parsePage(args, pageName)
  for key, val in pairs(args) do
        if key == pageName then
            if type(val) == 'table' then
                return val[1]
            else
                return val
            end
        end
  end
  return nil
end

--------根据指定的table 把url中key替换成val
function Url.replace(url, args)
  for key, val in pairs(args) do
        if type(val) == 'table' then
        else
            url = string.gsub(url, key, val)
        end
  end
  return url
end

---------- 获取urlkey get中的配置参数
function Url.getUrlKeyByGetMethod(urlOriginKey, urlKey, pageName, pageNumLimit)
    local urlModule = Url;
    local configGetUrlKeys = Url.keys[urlOriginKey]['get']
    local canNotCache = nil
    if configGetUrlKeys then
        ------ 根据配置参数 把get参数绑定到urlKey
        local args = ngx.req.get_uri_args()
        if args ~= nil then
            urlKey = urlModule.getParams(urlKey, args, configGetUrlKeys)
            local page = urlModule.parsePage(args, pageName)
            page = tonumber(page)
            if (page ~= nil and page + 1 > pageNumLimit) then
                canNotCache = true
            end
        end
    end
    return urlKey, canNotCache
end

---------获取urlkey post中配置参数
function Url.getUrlKeyByPostMehod(urlOriginKey)
    local urlModule = Url;
    local configPostPre = urlModule.keys[urlOriginKey]['postPre']
    local args = nil
    if (configPostPre ~= nil) then
        if true then
            --取出form-urlencode数据
            args, err = ngx.req.get_post_args()
            args = args[configPostPre]
            if args == nil or (type(args) == 'talbe' and table.getn(args) < 1) then
                --取出post raw数据
                args = ngx.req.get_body_data()
                if (args ~= nil and type(args) == 'string') then
                    if (pcall(cjson.decode, args)) then
                        args = cjson.decode(args)
                        args = args[configPostPre]
                    end
                end
            end
            if (args ~= nil) then
                if (type(args) == 'string' and pcall(cjson.decode, args)) then
                    args = cjson.decode(args)
                end
            else
                ngx.log(ngx.ERR, 'parse post json data error!')
            end
        else
            ngx.log(ngx.ERR, 'get_body_data error!')
        end
    end
    return args;
end
return Url
