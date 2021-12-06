#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

download_Url="https://raw.githubusercontent.com/cevikgazi/phase-panel/main/"
#Temel verileri hazırlayın
Root_Path=`cat /var/bt_setupPath.conf`
run_path='/root'
Is_64bit=`getconf LONG_BIT`
tomcat7='7.0.108'
tomcat8='8.5.69'
tomcat9='9.0.50'

#Tomcat'i yükleyin
Install_Tomcat()
{
	#ön hazırlık
	Uninstall_Tomcat
	Install_JavaJdk
	pkill -9 yum 
	yum install rng-tools -y
	service rngd start
	systemctl start rngd
	useradd www
	chown -R www.www $Setup_Path
	#Ana programı indirin ve kurun
	filename=apache-tomcat-$tomcatVersion.tar.gz
	wget -c -O $filename  $download_Url/install/src/$filename -T 20
	tar xvf $filename
	useradd www
	
	mv -f apache-tomcat-$tomcatVersion $Setup_Path
	rm -f $filename
	if [ "$tomcatVersion" == "$tomcat9" ];then
		tomcatVersion="9.0.0";
	fi
	echo "$tomcatVersion" > $Setup_Path/version.pl

	#Varsayılan yapılandırmayı değiştirin
	sxml=$Setup_Path/conf/server.xml
	sed -i "s#TOMCAT_USER=tomcat#TOMCAT_USER=www#" $Setup_Path/bin/daemon.sh
	chown -R www.www $Setup_Path
}

is_jdk_chekc(){
	if [ "${PM}" == "apt-get" ]; then
		return 
	fi
	if [ "$jdk" == "8u121" ];then
		is_check=`/usr/java/jdk1.8.0_121/bin/java -version |grep "Error occurred during initialization of VM"`
		echo $is_check
		if [ "$is_check" == "Error occurred during initialization of VM" ];then
			if [ -f /usr/bin/yum ];then
				rpm_data=`rpm -qa |grep jdk1.8.0 |head -n 1`
				echo $rpm_data
				rpm -e rpm_data
				rpm -ivh /tmp/java-jdk.rpm --force --nodeps
			fi
		fi
	fi
	if [ "$jdk" == "7u80" ];then
		is_check=`/usr/java/jdk1.7.0_80/bin/java -version |grep "Error occurred during initialization of VM"`
		if [ "$is_check" == "Error occurred during initialization of VM" ];then
			if [ -f /usr/bin/yum ];then
				rpm_data=`rpm -qa |grep jdk-1.7.0_80 |head -n 1`
				rpm -e rpm_data
				rpm -ivh /tmp/java-jdk.rpm --force --nodeps
			fi
		fi
	fi
}

#java-jdk'yi yükleyin
Install_JavaJdk()
{	
	if [ "${PM}" == "apt-get" ]; then
		if [ ! -f "/usr/local/btjdk/jdk8/bin/java" ];then
			mkdir -p /usr/local/btjdk/
			cd /usr/local/btjdk/
			wget -O java-1.8.0-openjdk.tar.gz ${download_Url}/src/java-1.8.0-openjdk.tar.gz
			tar -xvf java-1.8.0-openjdk.tar.gz
			mv java-1.8.0 jdk8
			rm -f java-1.8.0-openjdk.tar.gz
		fi
		/usr/local/btjdk/jdk8/bin/java -version 
		if [ "$?" -ne "0" ];then
			echo "jdk install failed"
			rm -rf /usr/local/btjdk/jdk8
			exit
		fi 
		jdk_path='/usr/local/btjdk/jdk8'
		return
	fi
    if [ "${PM}" == "yum" ]; then
		if [ ! -f "/usr/local/btjdk/jdk8/bin/java" ];then
			mkdir -p /usr/local/btjdk/
			cd /usr/local/btjdk/
			wget -O java-1.8.0-openjdk.tar.gz ${download_Url}/src/java-1.8.0-openjdk.tar.gz
			tar -xvf java-1.8.0-openjdk.tar.gz
			mv java-1.8.0 jdk8
			rm -f java-1.8.0-openjdk.tar.gz
		fi
		/usr/local/btjdk/jdk8/bin/java -version 
		if [ "$?" -ne "0" ];then
			echo "jdk install failed"
			rm -rf /usr/local/btjdk/jdk8
			exit
		fi 
		jdk_path='/usr/local/btjdk/jdk8'
		return
	fi
	if [ -d "$jdk_path" ];then
		if [ "$jdk" == "8u121" ];then
			is_check=`/usr/java/jdk1.8.0_121/bin/java -version |grep "Error occurred during initialization of VM"`
			echo $is_check
			if [ "$is_check" == "Error occurred during initialization of VM" ];then
				if [ -f /usr/bin/yum ];then
					rpm_data=`rpm -qa |grep jdk1.8.0 |head -n 1`
					echo $rpm_data
					rpm -e $rpm_data
					sleep 1
					rm -rf $jdk_path
					
				fi
			fi
		fi
		
		if [ "$jdk" == "7u80" ];then
			is_check=`/usr/java/jdk1.7.0_80/bin/java -version |grep "Error occurred during initialization of VM"`
			if [ "$is_check" == "Error occurred during initialization of VM" ];then
				if [ -f /usr/bin/yum ];then
					rpm_data=`rpm -qa |grep jdk-1.7.0_80 |head -n 1`
					rpm -e $rpm_data
					sleep 1
					rm -rf $jdk_path
				fi
			fi
		fi
	fi
	
	if [ ! -d "$jdk_path" ];then
		if [ ! -f "/tmp/java-jdk.rpm" ];then
			wget -c -O /tmp/java-jdk.rpm $download_Url/install/src/jdk-$jdk-linux-x$Is_64bit.rpm -T 20
		fi
		rpm -ivh /tmp/java-jdk.rpm --force --nodeps
		is_jdk_chekc
	fi
	rm -f /tmp/java-jdk.rpm
}

Install_Jsvs(){
	cd $Setup_Path/bin
	tar -zxf commons-daemon-native.tar.gz
	cd commons-daemon-1.2.4-native-src/unix
	./configure --with-java=$jdk_path
	make
	\cp jsvc $Setup_Path/bin
	sed -i "/Set JAVA_HOME/a\JAVA_HOME=$jdk_path" $Setup_Path/bin/daemon.sh
	if [ -f "$start_tomcat" ]; then
		rm -f $start_tomcat
	fi

cat>>$start_tomcat<<EOF
#!/bin/bash
# chkconfig: 2345 55 25
# description: tomcat Service
### BEGIN INIT INFO
# Provides:          tomcat
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts tomcat
# Description:       starts the tomcat
### END INIT INFO
path=$Setup_Path/bin
cd \$path
bash daemon.sh \$1
EOF

if [ "$version" == "7" ];then
if [ -f "$Setup_Path/conf/server.xml" ]; then
		rm -f $Setup_Path/conf/server.xml
fi
cat>>$Setup_Path/conf/server.xml<<EOF
	<Server port="8005" shutdown="SHUTDOWN">
	  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
	  <Listener SSLEngine="on" className="org.apache.catalina.core.AprLifecycleListener" />
	  <Listener className="org.apache.catalina.core.JasperListener" />
	  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
	  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
	  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
	  <GlobalNamingResources>
	    <Resource auth="Container" description="User database that can be updated and saved" factory="org.apache.catalina.users.MemoryUserDatabaseFactory" name="UserDatabase" pathname="conf/tomcat-users.xml" type="org.apache.catalina.UserDatabase" />
	  </GlobalNamingResources>
	  <Service name="Catalina">
	    <Connector connectionTimeout="20000" port="8231" protocol="HTTP/1.1" redirectPort="8443" />
	    <!--<Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />-->
	    <Engine defaultHost="localhost" name="Catalina">
	      <Realm className="org.apache.catalina.realm.LockOutRealm">
	        <Realm className="org.apache.catalina.realm.UserDatabaseRealm" resourceName="UserDatabase" />
	      </Realm>
	      <Host appBase="webapps" autoDeploy="true" name="localhost" unpackWARs="true">
	        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs" pattern="%h %l %u %t &quot;%r&quot; %s %b" prefix="localhost_access_log." suffix=".txt" />
	      </Host>
	    </Engine>
	  </Service>
	</Server>
EOF
fi

if [ "$version" == "8" ];then
if [ -f "$Setup_Path/conf/server.xml" ]; then
		rm -f $Setup_Path/conf/server.xml
fi
cat>>$Setup_Path/conf/server.xml<<EOF
<Server port="8098" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <Listener SSLEngine="on" className="org.apache.catalina.core.AprLifecycleListener" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
  <GlobalNamingResources>
    <Resource auth="Container" description="User database that can be updated and saved" factory="org.apache.catalina.users.MemoryUserDatabaseFactory" name="UserDatabase" pathname="conf/tomcat-users.xml" type="org.apache.catalina.UserDatabase" />
  </GlobalNamingResources>
  <Service name="Catalina">
    <Connector connectionTimeout="20000" port="8232" protocol="HTTP/1.1" redirectPort="8490" />
    <!--<Connector port="8008" protocol="AJP/1.3" redirectPort="8490" />-->
    <Engine defaultHost="localhost" name="Catalina">
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm" resourceName="UserDatabase" />
      </Realm>
      <Host appBase="webapps" autoDeploy="true" name="localhost" unpackWARs="true">
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs" pattern="%h %l %u %t &quot;%r&quot; %s %b" prefix="localhost_access_log" suffix=".txt" />
      </Host>
    </Engine>
  </Service>
</Server>
EOF
fi
if [ "$version" == "9" ];then
if [ -f "$Setup_Path/conf/server.xml" ]; then
		rm -f $Setup_Path/conf/server.xml
fi
cat>>$Setup_Path/conf/server.xml<<EOF
<Server port="8098" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <Listener SSLEngine="on" className="org.apache.catalina.core.AprLifecycleListener" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
  <GlobalNamingResources>
    <Resource auth="Container" description="User database that can be updated and saved" factory="org.apache.catalina.users.MemoryUserDatabaseFactory" name="UserDatabase" pathname="conf/tomcat-users.xml" type="org.apache.catalina.UserDatabase" />
  </GlobalNamingResources>
  <Service name="Catalina">
    <Connector connectionTimeout="20000" port="8233" protocol="HTTP/1.1" redirectPort="8490" />
    <!--<Connector port="8008" protocol="AJP/1.3" redirectPort="8490" />-->
    <Engine defaultHost="localhost" name="Catalina">
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm" resourceName="UserDatabase" />
      </Realm>
      <Host appBase="webapps" autoDeploy="true" name="localhost" unpackWARs="true">
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs" pattern="%h %l %u %t &quot;%r&quot; %s %b" prefix="localhost_access_log" suffix=".txt" />
      </Host>
    </Engine>
  </Service>
</Server>
EOF
fi
	chmod +x $start_tomcat
	#chkconfig --add $tomcat_version
	#chkconfig --level 2345 $tomcat_version on
	$start_tomcat start

	#Orijinal Tomcat dizinini yedekleyin
	echo '|-Successify --- Komut yürütüldü! ---'
	if [ ! -f "/usr/local/bttomcat/tomcat_bak$version" ];then
		cp -rp  /usr/local/bttomcat/tomcat$version /usr/local/bttomcat/tomcat_bak$version
	else
		rm -rf /usr/local/bttomcat/tomcat_bak$version
		cp -rp /usr/local/bttomcat/tomcat$version /usr/local/bttomcat/tomcat_bak$version
	fi
# 	echo '|-Successify --- Komut yürütüldü! ---'
# 	sleep 0.1
}

#Tomcat'i kaldır
Uninstall_Tomcat()
{
	if [ -d "$Setup_Path" ];then
		$Setup_Path/bin/daemon.sh stop
		rm -rf $Setup_Path
	fi
	if [ -f "$start_tomcat" ];then
		#chkconfig --del $tomcat_version
		rm -f $start_tomcat
		rm -f $init_tomcat
	fi
}

actionType=$1
version=$2
echo '' >/tmp/panelShell2.pl
if [ "$actionType" == 'install' ];then
	if [ "${PM}" == "apt-get" ] && [ "${version}" == "7" ]; then
		echo "Mevcut sistem Tomcat7'yi desteklemiyor"
		echo "not support tomcat7"
		exit
	fi
    mkdir -p /usr/local/bttomcat/
	Setup_Path=/usr/local/bttomcat/tomcat7
	start_tomcat=/etc/init.d/bttomcat7
	init_tomcat=/etc/rc.d/init.d/bttomcat7
	tomcat_version=tomcat7
	tomcatVersion=$tomcat7
	jdk='7u80'
	jdk_path='/usr/java/jdk1.7.0_80'
	if [ "$version" == "8" ];then
		Setup_Path=/usr/local/bttomcat/tomcat8
		start_tomcat=/etc/init.d/bttomcat8
		init_tomcat=/etc/rc.d/init.d/bttomcat8
		tomcat_version=tomcat8
		tomcatVersion=$tomcat8
		jdk='8u121'
		jdk_path='/usr/java/jdk1.8.0_121'
	elif [ "$version" == "9" ];then
		Setup_Path=/usr/local/bttomcat/tomcat9
		tomcat_version=tomcat9
		start_tomcat=/etc/init.d/bttomcat9
		init_tomcat=/etc/rc.d/init.d/bttomcat9
		tomcatVersion=$tomcat9
		jdk='8u121'
		jdk_path='/usr/java/jdk1.8.0_121'
	fi
	Install_Tomcat
	Install_Jsvs
	echo 'Tomcat kurulumu yenilenmezse tamamlanmıştır. Lütfen sayfayı yenileyin! ! ! ! !'
# 	sleep 0.2
	echo >/tmp/panelShell2.pl
	
elif [ "$actionType" == 'uninstall' ];then
	Setup_Path=/usr/local/bttomcat/tomcat7
	start_tomcat=/etc/init.d/bttomcat7
	init_tomcat=/etc/rc.d/init.d/bttomcat7
	tomcat_version=tomcat7
	tomcatVersion=$tomcat7
	if [ "$version" == "8" ];then
		Setup_Path=/usr/local/bttomcat/tomcat8
		start_tomcat=/etc/init.d/bttomcat8
		init_tomcat=/etc/rc.d/init.d/bttomcat8
		tomcat_version=tomcat8
		tomcatVersion=$tomcat8
	elif [ "$version" == "9" ];then
		Setup_Path=/usr/local/bttomcat/tomcat9
		tomcat_version=tomcat9
		start_tomcat=/etc/init.d/bttomcat9
		init_tomcat=/etc/rc.d/init.d/bttomcat9
		tomcatVersion=$tomcat9
	fi
	Uninstall_Tomcat
	echo "Kaldırma tamamlandı"
	echo '|-Successify --- Komut yürütüldü! ---' >>/tmp/panelShell2.pl
# 	echo '|-Successify --- Komut yürütüldü! ---' >>/tmp/panelShell2.pl
	echo >/tmp/panelShell2.pl
fi