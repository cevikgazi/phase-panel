#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

run_path="/root"

cd ${run_path}
wget https://ftp.openssl.org/source/old/1.0.2/openssl-1.0.2l.tar.gz -T 20
tar -zxf openssl-1.0.2l.tar.gz
rm -f openssl-1.0.2l.tar.gz
cd openssl-1.0.2l
./config --openssldir=/usr/local/openssl zlib-dynamic shared
make && make install
echo '1.0.2l_shared' > /usr/local/openssl/version.pl
cd ..
rm -rf openssl-1.0.2l
cat > /etc/ld.so.conf.d/openssl.conf <<EOF
/usr/local/openssl/lib
EOF
ldconfig
