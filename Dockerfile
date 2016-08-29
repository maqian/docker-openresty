FROM hub.fenxibao.com/base/centos:7

MAINTAINER Ma Qian<maqian258@gmail.com>

ARG RESTY_VERSION="1.9.15.1"
ARG RESTY_LUAROCKS_VERSION="2.3.0"
ARG RESTY_OPENSSL_VERSION="1.0.2h"
ARG RESTY_PCRE_VERSION="8.38"
ARG NGX_HTTP_DYUPS_MODULE_VERSION="0.2.9"
ARG RESTY_J="1"
ARG RESTY_CONFIG_OPTIONS="\
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \
    --without-http_fastcgi_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    "

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} --with-pcre=/tmp/pcre-${RESTY_PCRE_VERSION} --add-module=/tmp/ngx_http_dyups_module-${NGX_HTTP_DYUPS_MODULE_VERSION}"


# 1) Install yum dependencies
# 2) Download and untar OpenSSL, PCRE, and OpenResty
# 3) Build OpenResty
# 4) Cleanup

RUN \
    yum install -y \
        gcc \
        gcc-c++ \
        gd-devel \
        GeoIP-devel \
        libxslt-devel \
        make \
        perl \
        perl-ExtUtils-Embed \
        readline-devel \
        unzip \
        zlib-devel \
    && cd /tmp \
    && curl -fSL https://codeload.github.com/yzprofile/ngx_http_dyups_module/tar.gz/v${NGX_HTTP_DYUPS_MODULE_VERSION} -o ngx_http_dyups_module-${NGX_HTTP_DYUPS_MODULE_VERSION}.tar.gz \
    && tar xzf ngx_http_dyups_module-${NGX_HTTP_DYUPS_MODULE_VERSION}.tar.gz \
    && curl -fSL https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && curl -fSL https://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && rm -rf \
        openssl-${RESTY_OPENSSL_VERSION}.tar.gz openssl-${RESTY_OPENSSL_VERSION} \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
        ngx_http_dyups_module-${NGX_HTTP_DYUPS_MODULE_VERSION}.tar.gz ngx_http_dyups_module-${NGX_HTTP_DYUPS_MODULE_VERSION} \
    && curl -fSL http://luarocks.org/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${RESTY_LUAROCKS_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix=jit-2.1.0-beta2 \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make build \
    && make install \
    && cd /tmp \
    && rm -rf luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && yum clean all \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log


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

EXPOSE 80 443

ENTRYPOINT ["/usr/local/openresty/nginx/sbin/nginx", "-g", "daemon off;"]
