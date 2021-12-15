#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8


run_path="/root"

cd ${run_path}
wget -O libmcrypt-2.5.8.tar.gz https://src.fedoraproject.org/repo/pkgs/libmcrypt/libmcrypt-2.5.8.tar.gz/0821830d930a86a5c69110837c55b7da/libmcrypt-2.5.8.tar.gz -T 5
tar zxf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure
make && make install
/sbin/ldconfig
cd libltdl/
./configure --enable-ltdl-install
make && make install
ln -sf /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la
ln -sf /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so
ln -sf /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4
ln -sf /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8
ldconfig
cd ${run_path}
rm -rf libmcrypt-2.5.8
rm -f libmcrypt-2.5.8.tar.gz