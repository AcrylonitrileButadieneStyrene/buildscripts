FROM docker.io/library/ubuntu:latest

WORKDIR /root/workdir/buildscripts
COPY . .

RUN apt-get update
RUN apt-get install -y git curl python3 xz-utils lbzip2 unzip
WORKDIR /root/workdir/buildscripts/emscripten
ENV TAR_OPTIONS="--no-same-owner"
RUN bash ./1_download_library.sh
RUN apt-get install -y autoconf pkg-config libtool build-essential cmake meson
RUN bash ./2_build_toolchain.sh
RUN bash ./3_cleanup.sh

WORKDIR /root/workdir
RUN git clone https://github.com/EasyRPG/liblcf

WORKDIR /root/workdir/liblcf
ENV EM_PKG_CONFIG_PATH=/root/workdir/buildscripts/emscripten/lib/pkgconfig
RUN autoreconf -fi
RUN bash -c "source /root/workdir/buildscripts/emscripten/emsdk-portable/emsdk_env.sh; \
    	     emconfigure ./configure --prefix=/root/workdir/buildscripts/emscripten --disable-shared"
RUN make install

RUN apt-get install -y ninja-build ccache
CMD bash -c "source /root/workdir/buildscripts/emscripten/emsdk-portable/emsdk_env.sh; \
             cd /root/workdir/ynoengine; \
	     if [[ \"$NO_SIMD\" -eq 1 ]]; then \
	     	./cmake_build_nosimd.sh; \
	     else \
             	./cmake_build.sh; \
	     fi; \
	     cd build; \
	     ninja"

