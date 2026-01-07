FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre3-dev \
    libssl-dev \
    zlib1g-dev \
    libpq-dev \    
    wget \
    perl \
    make


ENV OPENRESTY_VERSION=1.21.4.1
RUN wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz \
    && tar -xzvf openresty-${OPENRESTY_VERSION}.tar.gz

WORKDIR /openresty-${OPENRESTY_VERSION}

RUN ./configure \
    --prefix=/opt/openresty \
    --with-pcre-jit \
    --with-ipv6 \
    --without-http_redis2_module \
    --with-http_iconv_module \
    --with-http_postgres_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    -j2

RUN make && make install

FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
    libpcre3 \
    libssl1.1 \
    libpq5 \  
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*


COPY --from=builder /opt/openresty /opt/openresty

ENV PATH=$PATH:/opt/openresty/nginx/sbin:/opt/openresty/bin

COPY nginx.conf /opt/openresty/nginx/conf/nginx.conf

EXPOSE 80 9113
CMD ["openresty", "-g", "daemon off;"]
