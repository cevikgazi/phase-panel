#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

run_path="/root"

cd ${run_path}
wget -O libiconv-1.14.tar.gz https://ftp.gnu.org/gnu/libiconv/libiconv-1.14.tar.gz -T 5
mkdir /patch
wget -O /patch/libiconv-glibc-2.16.patch http://file.wepcc.com/Linux/lnmp1.5/src/patch/libiconv-glibc-2.16.patch -T 5
tar zxf libiconv-1.14.tar.gz
cd libiconv-1.14
patch -p0 < /patch/libiconv-glibc-2.16.patch
./configure --prefix=/usr/local/libiconv --enable-static
make && make install
cd ${run_path}
rm -rf libiconv-1.14
rm -f libiconv-1.14.tar.gz