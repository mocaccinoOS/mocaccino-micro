# NATIVE = 1
# TARGET = x86_64-linux-musl

# DL_CMD = curl -Lo

COMMON_CONFIG += CC='cc -static --static'
COMMON_CONFIG += CXX='c++ -static --static'

COMMON_CONFIG += CFLAGS='-O2 -pipe'
COMMON_CONFIG += CXXFLAGS='-O2 -pipe'
COMMON_CONFIG += LDFLAGS='-s'

COMMON_CONFIG += --build=$(TARGET)
COMMON_CONFIG += --with-build-sysroot=/
COMMON_CONFIG += --disable-nls
#COMMON_CONFIG += --prefix=/usr
COMMON_CONFIG += --enable-deterministic-archives
COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)=

GCC_CONFIG += --with-native-system-header-dir=/usr/include
GCC_CONFIG += --disable-bootstrap
GCC_CONFIG += --disable-libgomp
GCC_CONFIG += --disable-libquadmath
GCC_CONFIG += --disable-lto

GCC_CONFIG += --bindir=/usr/bin
GCC_CONFIG += --prefix=/usr
#GCC_CONFIG += --with-local-prefix=/usr/include

KERNEL_VARS += HOSTCC='cc -static'

# only static
COMMON_CONFIG += --disable-shared
MUSL_CONFIG += --disable-shared
