------ 获取请求URI query_string
local query_string = ngx.var.query_string


------ 设置返回数据类型
ngx.header.content_type = 'application/json';

------ 路径请求对于的key
urlKey = ngx.var.request_uri

------ 去除url后缀
urlKey = (string.gsub(urlKey, "([%a%-%_%/%%%d%.]*)%?([%a%-%_%/%%%?%&%=%d%:%.]*)", "%1"))
------ urlKey = string.gsub(urlKey, "(%.php*)", "")


------ 根据规则替换掉无用URL  这里request_uri 是原始url，如果nginx有重写规则(作用在uri) 需要在这里手动替换掉
local reg = urlModule.reg;
if (reg ~= nil) then
    urlKey = urlModule.replace(urlKey, reg)
end

------ 组成要发送的url 一般格式为index.php文件+query_string,如果是文件则需要直接访问
local pos = string.find(urlKey, '.php')
if (pos ~= nil) then
    url = urlKey .. "/no_into_lua?" .. query_string
else
    url = urlModule.path .. "?" .. query_string
end

------ 保存原始uri 后面用
urlOriginKey = urlKey


------ 发送给php request_uri的参数 php 可以通过$_SERVER['request_uri']获取, 要提前设置好fastcgi参数
ngx.var.php_request_uri = urlKey --.. "?" .. query_string

------ 判断路由是否需要缓存 不需要的直接执行结果返回 不会容灾
-- urlOriginKey = string.gsub(urlOriginKey, "(%.php*)", "")
enable = urlModule.keys[urlOriginKey]

------ 检测cjson插件是否已经安装 或者是否需要直接执行而不缓存
if (cjson == nil or apiData["enable"] == 0 or enable == nil) then

    if (cjson == nil) then
        ngx.log(ngx.ERR, 'cjson plugn has not be installed!')
    end
    --不需要缓存 直接返回rewrite 路由 此函数后面的代码不在执行
    if (urlModule.noCachePath ~= nil and urlModule.noCachePath ~= "" and pos ~= nil) then
        ngx.exec(urlModule.noCachePath)
    else
        ngx.exec(url)
    end
    --ngx.redirect(url)
else

    ------ 获取分页参数
    if (urlModule.keys[urlOriginKey]['page'] ~= nil) then
        pageName = urlModule.keys[urlOriginKey]['page']['name']
        pageNumLimit = urlModule.keys[urlOriginKey]['page']['num']
    end

    ------ 是否缓存数据
    local canNotCache = nil
    local page = nil

    ------ 获取配置get参数
    urlKey, canNotCache = urlModule.getUrlKeyByGetMethod(urlOriginKey, urlKey, pageName, pageNumLimit)

    ---------- 默认只缓存前3页，超过的页数直接返回，不会查看是否异常 不会去查看缓存
    if canNotCache then
        ngx.exec(url)
    end

    ----- 获取post参数 绑定key
    ngx.req.read_body() --强制刷新get_body_data数据
    --取得post参数体的前缀
    if ngx.req.get_method() == "POST" then
        args = urlModule.getUrlKeyByPostMehod(urlOriginKey)
    end

    --取得post参数不为空
    if not err and args ~= nil and type(args) == 'table' then
        --获取配置需要取的post key
        local configPostUrlKeys = urlModule.keys[urlOriginKey]['post']
        urlKey = urlModule.getParams(urlKey, args, configPostUrlKeys)
    end

    ------ lua 控制请求
    if (urlKey ~= nil) then
        local apiDatas = ngx.shared.apiDatas
        ----------- 开始URL请求
        if ngx.req.get_method() == "GET" then
            method = ngx.HTTP_GET
        else
            method = ngx.HTTP_POST
        end
        local postData = {
            ["method"] = method,
            ["body"] = ngx.req.get_body_data(),
            vars = { php_request_uri = ngx.var.php_request_uri }
        }
        local res = ngx.location.capture(url, postData)
        ------ 获取请求数据 如果请求异常则返回缓存数据(缓存不存在直接返回执行结果)
        if res.status == ngx.HTTP_OK or res.status == ngx.HTTP_MOVED_PERMANENTLY or res.status == ngx.HTTP_MOVED_TEMPORARILY then
            apiDatas:set(urlKey, res.body)
        else
            local cacheData = apiDatas:get(urlKey)
            if (cacheData ~= nil) then
                ngx.status = ngx.HTTP_OK
                ngx.print(cacheData)
                ngx.exit(ngx.HTTP_OK)
            end
        end
        ngx.status = res.status
        ngx.print(res.body)
        ngx.exit(res.status)
    end
end

