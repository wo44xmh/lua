nginx.conf:

--
1：主要是根据手机ip过滤后
2：根据不同的域名分发到不同的后端主机
3：限制流量，防止奔溃

设置lua包含路径
lua_package_path "/default/lua/?.lua;;";
设置lua初始化
init_by_lua_file "/default/lua/config/config.lua";

--暂时废弃end


# 上线配置：

nginx.conf:

设置共享内存（范围：server）

lua_shared_dict limit_list 1m;

# 设置路由：

# 设置lua路由（范围：server）
```json
location /lua {
            lua_code_cache on;#此参数上线后开启
            #此参数代表lua项目的地址
            access_by_lua_file "/lua_limit/limit.lua";
}
location /flush_lua {
                lua_code_cache on;#此参数上线后开启
                #此参数代表lua项目的地址
                access_by_lua_file "/lua_limit/flush.lua";
 }

```

# 设置路由，要和inculde/common.lua中的路由一致，默认路由最好有，其他的可以没有

# 默认要走的路由(范围server)

```json
location @default {
      proxy_pass         http://mgz;
      proxy_set_header   Host             $host;
      proxy_set_header   X-Real-IP        $remote_addr:$server_port;
      proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
 }

```

# 设置国内代理请求（范围：server）：

 location @mgz-cn {
      proxy_pass         http://mgz_cn;
      proxy_set_header   Host             $host;
      proxy_set_header   X-Real-IP        $remote_addr:$server_port;
      proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
 }

#  设置英文默认代理请求（范围：server）：

```json
 location @mgz-en {
      proxy_pass         http://mgz_en;
      proxy_set_header   Host             $host;
      proxy_set_header   X-Real-IP        $remote_addr:$server_port;
      proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
 }
```

# 设置代理路径（范围：http）：

```json
 upstream mgz_cn {
      server host1;
 }
 upstream mgz_en {
     server hos2;
 }
```