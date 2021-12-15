#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

run_path="/root"

cd ${run_path}
curl_version="7.54.1"
if [ ! -f "curl-$curl_version.tar.gz" ];then
	wget -O curl-$curl_version.tar.gz https://curl.se/download/curl-$curl_version.tar.gz -T 5
fi
tar zxf curl-$curl_version.tar.gz
cd curl-$curl_version
./configure --prefix=/usr/local/curl --enable-ares --without-nss --with-ssl=/usr/local/openssl
make && make install
cd ..
rm -rf curl-$curl_version
rm -rf curl-$curl_version.tar.gz
echo -e "Install_Curl" >> /www/server/lib.pl
echo -e "Ture" >> /usr/local/curl/newcurl.pl
