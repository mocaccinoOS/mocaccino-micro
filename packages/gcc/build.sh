#!/bin/sh
set -x

cd gcc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac
# See also: https://github.com/dslm4515/Musl-LFS/blob/master/doc/005-Cross-Tools-GCC-Final
# Configure in a dedicated build directory
mkdir build && cd  build
AR=ar LDFLAGS="-Wl,-rpath,/lib" \
../configure \
    --prefix=/ \
    --build=${MUSL_HOST} \
    --host=${MUSL_HOST} \
    --target=${MUSL_TARGET} \
    --disable-multilib \
    --with-sysroot=/ \
    --disable-nls \
    --enable-shared \
    --enable-languages=c,c++ \
    --enable-threads=posix \
    --enable-clocale=generic \
    --enable-libstdcxx-time \
    --enable-fully-dynamic-string \
    --disable-symvers \
    --disable-libsanitizer \
    --disable-lto-plugin \
    --disable-libssp 

# Build
make AS_FOR_TARGET="${MUSL_TARGET}-as" \
    LD_FOR_TARGET="${MUSL_TARGET}-ld"

# Install
#make install