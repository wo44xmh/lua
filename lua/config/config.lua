function currDir()
    os.execute("cd > cd.tmp")
    local f = io.open("cd.tmp", r)
    local cwd = f:read("*a")
    f:close()
    os.remove("cd.tmp")
    return cwd
end
local p = "/data/www/lua_web/lua/"
local m_package_path = package.path
package.path = string.format("%s?.lua;%s", p, m_package_path)
------加载配置数据
apiData = require("config/data")
------加载json
cjson = require "cjson"
------加载自定义url模块
urlModule = require("config/url")