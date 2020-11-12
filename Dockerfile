FROM ubuntu:18.04
MAINTAINER HK <hobakc@gmail.com>

RUN mkdir -p /tmp/janus
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
  automake \
  build-essential \
  wget \
  git \
  cmake \
  gtk-doc-tools

# Install libnice 
RUN cd /tmp/janus && \
  git clone https://gitlab.freedesktop.org/libnice/libnice && \
  cd libnice && \
  meson --prefix=/usr build && \
  ninja -C build && \
  sudo ninja -C build install

# Install libsrtp 2.3.0 (Secure Real-time Transport Protocol)
RUN cd /tmp && \
  wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz && \
  tar xfv v2.3.0.tar.gz && \
  cd libsrtp-2.3.0 && \
  ./configure --prefix=/usr --enable-openssl && \
  make shared_library && make install

# Install usrsctp (data channel support)
# Note: you may need to pass --libdir=/usr/lib64
RUN cd /tmp && \
  git clone https://github.com/sctplab/usrsctp && \
  cd usrsctp && \
  ./bootstrap && \
  ./configure --prefix=/usr --disable-programs --disable-inet --disable-inet6 && \
  make && make install

# Install libwebsockets (webSockets support)
# Note: if libwebsockets.org is unreachable for any reason, replace the first line with this:
# git clone https://github.com/warmcat/libwebsockets.git
RUN cd /tmp && \
  git clone https://libwebsockets.org/repo/libwebsockets && \
  cd libwebsockets && \
  mkdir build && \
  cd build && \
  cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. && \
  make && make install

# Install janus
RUN cd /tmp && \
  git clone https://github.com/meetecho/janus-gateway.git && \
  cd janus-gateway && \
  sh autogen.sh && \
  ./configure --prefix=/usr/local --disable-rabbitmq --disable-mqtt && \
  make && \
  make install && \
  make configs

COPY conf/janus.plugin.videoroom.jcfg /usr/local/janus/etc/janus/janus.plugin.videoroom.jcfg
COPY conf/janus.transport.http.jcfg /usr/local/janus/etc/janus/janus.transport.http.jcfg

EXPOSE 10000-10200/udp
EXPOSE 8188
EXPOSE 8088
EXPOSE 8880
EXPOSE 7088

CMD ["/usr/local/bin/janus"]
