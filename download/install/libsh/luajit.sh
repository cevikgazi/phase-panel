#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

run_path="/root"

cd ${run_path}

wget -c -O LuaJIT-2.0.4.tar.gz https://luajit.org/download/LuaJIT-2.0.4.tar.gz -T 5
tar xvf LuaJIT-2.0.4.tar.gz
cd LuaJIT-2.0.4
make linux
make install
cd ..
rm -rf LuaJIT-*
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.0/
ln -sf /usr/local/lib/libluajit-5.1.so.2 /usr/local/lib64/libluajit-5.1.so.2
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig