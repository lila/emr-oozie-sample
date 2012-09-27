#!/bin/bash

function jsonval {
    temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop | cut -d ":" -f 2`
    echo ${temp##*|}
}

json=`cat /mnt/var/lib/info/instance.json`
prop='isMaster'
ismaster=`jsonval`

if [[ "$ismaster" -eq "true" ]]
then
	#
	# first create the oozie user
	#
	sudo useradd oozie -m
	
	#
	# download files
	#
	cd /tmp
	wget http://apache.mirrors.tds.net/incubator/oozie/oozie-3.1.3-incubating/oozie-3.1.3-incubating-distro.tar.gz
	wget http://extjs.com/deploy/ext-2.2.zip
	
	#
	# unpack oozie and setup
	# 
	sudo sh -c "mkdir /opt"
	sudo sh -c "cd /opt; tar -zxvf /tmp/oozie-3.1.3-incubating-distro.tar.gz"
	sudo sh -c "cd /opt/oozie-3.1.3-incubating/; ./bin/oozie-setup.sh -extjs /tmp/ext-2.2.zip -hadoop 0.20.200 /home/hadoop/"
	
	# add config
	sudo sh -c "grep -v '/configuration' /opt/oozie-3.1.3-incubating/conf/oozie-site.xml > /opt/oozie-3.1.3-incubating/conf/oozie-site.xml.new; echo ' 
	<property><name>oozie.services.ext</name><value>org.apache.oozie.service.HadoopAccessorService</value><description>To add/replace services defined in 'oozie.services' with custom implementations.Class names must be separated by commas.</description></property>' >> /opt/oozie-3.1.3-incubating/conf/oozie-site.xml.new; echo '    <property>
	<name>hadoop.proxyuser.oozie.hosts</name>
	<value>*</value>
    </property>

    <property>
	<name>hadoop.proxyuser.oozie.groups</name>
  	<value>*</value>
    </property>
</configuration>' >> /opt/oozie-3.1.3-incubating/conf/oozie-site.xml.new"
	sudo sh -c "mv /opt/oozie-3.1.3-incubating/conf/oozie-site.xml /opt/oozie-3.1.3-incubating/conf/oozie-site.xml.orig"
	sudo sh -c "mv /opt/oozie-3.1.3-incubating/conf/oozie-site.xml.new /opt/oozie-3.1.3-incubating/conf/oozie-site.xml"
	sudo sh -c "chown -R oozie /opt/oozie-3.1.3-incubating"
	

	#
	# copy emr jars to oozie webapp
	#
	sudo sh -c "sudo -u oozie sh -c 'cp /home/hadoop/lib/* /opt/oozie-3.1.3-incubating/oozie-server/lib'"
	sudo sh -c "sudo -u oozie sh -c 'cp /home/hadoop/*.jar /opt/oozie-3.1.3-incubating/oozie-server/lib'"

	#
	# startup oozie 
	#
	sudo sh -c "sudo -u oozie sh -c /opt/oozie-3.1.3-incubating/bin/oozie-start.sh"

	#
	# stop oozie after 5 second
	#

else
  echo "not master... skipping"
fi
