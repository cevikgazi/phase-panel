#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

run_path="/root"

cd ${run_path}
wget -O mhash-0.9.9.9.tar.gz https://netix.dl.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz -T 5
tar zxf mhash-0.9.9.9.tar.gz
cd mhash-0.9.9.9
./configure
make && make install
ln -sf /usr/local/lib/libmhash.a /usr/lib/libmhash.a
ln -sf /usr/local/lib/libmhash.la /usr/lib/libmhash.la
ln -sf /usr/local/lib/libmhash.so /usr/lib/libmhash.so
ln -sf /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
ln -sf /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1
ldconfig
cd ${run_path}
rm -rf mhash-0.9.9.9*
echo -e "Install_Mhash" >> /www/server/lib.pl