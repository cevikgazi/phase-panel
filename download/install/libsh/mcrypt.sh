#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

run_path="/root"

cd ${run_path}
wget -O mcrypt-2.6.8.tar.gz https://src.fedoraproject.org/repo/pkgs/mcrypt/mcrypt-2.6.8.tar.gz/97639f8821b10f80943fa17da302607e/mcrypt-2.6.8.tar.gz -T 5
tar zxf mcrypt-2.6.8.tar.gz
cd mcrypt-2.6.8
./configure
make && make install
cd ${run_path}
rm -rf mcrypt-2.6.8
rm -f mcrypt-2.6.8.tar.gz