FROM ubuntu:18.04
LABEL maintainer="hobakc@gmail.com"
LABEL version="1.0"

# docker build environments
ENV BUILD_SRC="/tmp/janus"
ENV JANUS_HOME="/opt/janus"


# Install dependencies
RUN mkdir -p ${BUILD_SRC}
RUN apt-get -y update && \
  apt-get install -y \
  libmicrohttpd-dev \
  libjansson-dev \
  libssl-dev \
  libsrtp-dev \
  libsofia-sip-ua-dev \
  libglib2.0-dev \
  libopus-dev \
  libogg-dev \
  libcurl4-openssl-dev \
  liblua5.3-dev \
  libconfig-dev \
  pkg-config \
  gengetopt \
  libtool \
  autotools-dev \
  automake \
  build-essential \
  wget \
  git \
  make \
  cmake \
  doxygen \
  graphviz

# Install libnice 
RUN apt install --no-install-recommends --no-install-suggests -y \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel ninja-build
RUN pip3 install meson
RUN apt remove libnice-dev

RUN cd ${BUILD_SRC} && \
  git clone https://gitlab.freedesktop.org/libnice/libnice && \
  cd ${BUILD_SRC}/libnice && \
  meson --prefix=/usr build && \
  ninja -C build && \
  sudo ninja -C build install

# Install libsrtp 2.3.0 (Secure Real-time Transport Protocol)
RUN cd ${BUILD_SRC} && \
  wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz && \
  tar xfv v2.3.0.tar.gz && \
  cd ${BUILD_SRC}/libsrtp-2.3.0 && \
  ./configure --prefix=/usr --enable-openssl && \
  make shared_library && make install

# Install usrsctp (data channel support)
# Note: you may need to pass --libdir=/usr/lib64
RUN cd ${BUILD_SRC} && \
  git clone https://github.com/sctplab/usrsctp && \
  cd ${BUILD_SRC}/usrsctp && \
  ./bootstrap && \
  ./configure --prefix=/usr --disable-programs --disable-inet --disable-inet6 && \
  make && make install

# Install libwebsockets (webSockets support)
# Note: if libwebsockets.org is unreachable for any reason, replace the first line with this:
# git clone https://github.com/warmcat/libwebsockets.git
RUN cd ${BUILD_SRC} && \
  git clone https://libwebsockets.org/repo/libwebsockets && \
  cd ${BUILD_SRC}/libwebsockets && \
  mkdir build && \
  cd build && \
  cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. && \
  make && make install

# Install janus
RUN cd ${BUILD_SRC}/ && \
  git clone https://github.com/meetecho/janus-gateway.git && \
  cd ${BUILD_SRC}/janus-gateway && \
  sh autogen.sh && \
  ./configure --prefix=${JANUS_HOME} --disable-rabbitmq --disable-mqtt && \
  make && \
  make install && \
  make configs

COPY conf/janus.plugin.videoroom.jcfg ${JANUS_HOME}/etc/janus/janus.plugin.videoroom.jcfg
COPY conf/janus.transport.http.jcfg ${JANUS_HOME}/etc/janus/janus.transport.http.jcfg

# Install Nginx
RUN apt-get install nginx -y
COPY nginx/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80 7088 8088 8188 8089
EXPOSE 10000-10200/udp

# CMD ["/usr/local/bin/janus"]
CMD service nginx restart && /opt/janus/bin/janus --nat-1-1=${DOCKER_IP}
