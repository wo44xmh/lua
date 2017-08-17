# lua

## 1：限流，降级  暂时没做

## 2：加载缓存，容灾 已经有

部署方式：

`
 nginx:

    http{
        #初始化变量的lua项目地址
        init_by_lua_file "/home/s/test/lua_web/lua/config/config.lua";
        lua_shared_dict apiDatas 1m;
    #设置默认路由
    location / {
           #这条去掉try_files $uri $uri/ /public/index.php?$query_string;
           #默认通过lua方式加载路由
           try_files $uri $uri/ /lua?$query_string;
    }
    #设置lua路由
    location /lua {
                lua_code_cache off;#此参数上线后开启
                #此参数代表lua项目的地址
                content_by_lua_file "/home/s/test/lua_web/lua/index.lua";
    }
    #设置除index,public,xring,adwpbrowse,adwpdownload,wpdownload,wpbrowse,fontdl,scenedl,ringdl,thdownload,bucket,zk等开头的路由外，其他路由全部通过lua方式加载
    location ~ ^/(?!index|public|xring|adwpbrowse|adwpdownload|wpdownload|wpbrowse|fontdl|scenedl|ringdl|thdownload|bucket|zk)(.*)\.php(?!/no_into_lua) {
        #设置php $_SERVER['SCRIPT_NAME']
        set $php_request_uri "";
        #lua路由
        rewrite (.*?) /lua?$query_string;
    }
    location ~ \.php {
            fastcgi_index  index.php;
            fastcgi_pass 127.0.0.1:9000;
            include fastcgi.conf;
            #这个参数一定要放到最后 用来设置php $_SERVER['SCRIPT_NAME']的值
            fastcgi_param  SCRIPT_NAME        $php_request_uri;
    }
    location ~ \.lua$ {
            access_log off;
            return 403;
    }
   `

*** 此项目：

*** config/config.lua

  *** 找到这里，替换真正线上lua地址
  local p = "/data/code/lua_web/"