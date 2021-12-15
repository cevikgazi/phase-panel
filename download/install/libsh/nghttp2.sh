#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

run_path="/root"

cd ${run_path}
wget http://ftp.oregonstate.edu/.1/blfs/conglomeration/nghttp2/nghttp2-1.31.0.tar.xz
tar -zxf nghttp2-1.31.0.tar.xz
cd nghttp2-1.31.0
./configure --prefix=/usr/local/nghttp2
make && make install
ln -sf /usr/local/nghttp2/lib/libnghttp2.so.14 /usr/lib/libnghttp2.so.14
ln -sf /usr/local/nghttp2/lib/libnghttp2.so.14 /usr/lib64/libnghttp2.so.14
echo '1.31.0' > /usr/local/nghttp2/version.pl
cd ..
rm -rf nghttp2-1.31.0*