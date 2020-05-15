#!/bin/sh
set -x
wget http://ftp.gnu.org/gnu/gcc/gcc-${PACKAGE_VERSION}/gcc-${PACKAGE_VERSION}.tar.xz
tar -xf gcc-${PACKAGE_VERSION}.tar.xz
mv -v gcc-${PACKAGE_VERSION} gcc
cd gcc
wget http://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz
wget http://www.mpfr.org/mpfr-4.0.2/mpfr-${MPFR_VERSION}.tar.xz
wget https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz

tar -xf mpfr-${MPFR_VERSION}.tar.xz
mv -v mpfr-${MPFR_VERSION} mpfr
tar -xf gmp-${GMP_VERSION}.tar.xz
mv -v gmp-${GMP_VERSION} gmp
tar -xf mpc-${MPC_VERSION}.tar.gz
mv -v mpc-${MPC_VERSION} mpc

for i in `ls ../patches/alpine/*.patch | sort -V`; do patch -Np1 -i  "$i"; done;
