FROM openresty/openresty:1.9.15.1-centos

MAINTAINER Ma Qian<maqian258@gmail.com>

COPY deps /tmp/deps

RUN yum install -y cmake openldap-devel \
    && cd /tmp/deps/lua-zlib-0.4 \
    && cmake -DLUA_INCLUDE_DIR=/usr/local/openresty/luajit/include/luajit-2.1 -DLUA_LIBRARIES=/usr/local/openresty/luajit/lib -DUSE_LUAJIT=ON -DUSE_LUA=OFF \
    && make && make install \
    && mv /usr/local/share/lua/cmod/zlib.so /usr/local/openresty/luajit/lib/lua/5.1 \
    && cd /tmp/deps/lua-ldap-1.2.3 \
    && make LUA_INC=/usr/local/openresty/luajit/include/luajit-2.1  LUA_LIBDIR=/usr/local/openresty/luajit/lib && make install \
    && mv /usr/lib/lua/5.1/lualdap.so* /usr/local/openresty/luajit/lib/lua/5.1 \
    && rm -rf /tmp/deps
