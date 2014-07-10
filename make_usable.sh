#!/bin/bash

PORT=$2
if [ "x$PORT" == "x" ] ; then
   echo Port missing
   exit 1
fi


scp -P $PORT -i ~/.ssh/bootstrap_key_rsa utils.sh bootstrap@$1:
echo Enabling regular root access

ssh -p $PORT -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'cat > local_make_usable.sh' <<EOF
source ~bootstrap/utils.sh
echo > /etc/hosts.allow
echo > /etc/hosts.deny
sed -i.orig 's/PermitRootLogin .*/PermitRootLogin yes/; s/ChallengeResponseAuthentication .*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
/etc/init.d/sshd restart
setenforce Permissive
sed -i.orig 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
if grep -q sunbeam /etc/hosts ; then
  echo hosts OK
else 
  echo 178.237.34.20 sunbeam.strocamp.net >> /etc/hosts
fi
EOF
ssh -p $PORT -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'sudo bash local_make_usable.sh'

echo Downloading CloudStack RPMS
ssh -p $PORT -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'cat > prepare_for_cloudstack.sh' <<EOF
source ~bootstrap/utils.sh
yum update -y
mkdir /opt/cloudstack-rpms
cd /opt/cloudstack-rpms
download cloudstack-common-4.4.0-SNAPSHOT.el6.x86_64.rpm cloudstack-common-4.4.0-SNAPSHOT.el6.x86_64.rpm fded8ba356e0d2ccc2441709064f8c7f
download cloudstack-awsapi-4.4.0-SNAPSHOT.el6.x86_64.rpm cloudstack-awsapi-4.4.0-SNAPSHOT.el6.x86_64.rpm 588bf04c4a9975c378a1747df5ea53db
download cloudstack-management-4.4.0-SNAPSHOT.el6.x86_64.rpm cloudstack-management-4.4.0-SNAPSHOT.el6.x86_64.rpm 6ad7daacbcbfcd53874f141df545dc6d
download vhd-util vhd-util 2f3b434842d25d9672cc0a75d103ae90

for PACKAGE in cloudstack-common-4.4.0-SNAPSHOT.el6.x86_64.rpm cloudstack-awsapi-4.4.0-SNAPSHOT.el6.x86_64.rpm cloudstack-management-4.4.0-SNAPSHOT.el6.x86_64.rpm ; do
   yum deplist \$PACKAGE | grep provider | awk '{print \$2}' | sort | uniq | grep -v \$PACKAGE | sed ':a;N;$!ba;s/\n/ /g' | xargs yum -y install
done

EOF
ssh -p $PORT -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'sudo bash -x prepare_for_cloudstack.sh'
scp -P $PORT -i ~/.ssh/bootstrap_key_rsa post_install.sql bootstrap@$1: 

echo Installing MySQL Server
ssh -p $PORT -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'cat > prepare_for_mysql.sh' <<EOF
source ~bootstrap/utils.sh
if /bin/rpm -qa | grep mysql-server ; then
   echo Skipping MySQL server install
   exit 0
fi
yum install -y mysql-server
/etc/init.d/mysqld start
/usr/bin/mysqladmin -u root password 'cloud'
EOF
ssh -p $PORT -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'sudo bash -x prepare_for_mysql.sh'

echo Installing NFS Server
ssh -p $PORT -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'cat > prepare_for_nfs.sh' <<EOF
source ~bootstrap/utils.sh
mkdir -p /opt/storage/primary
mkdir -p /opt/storage/secondary
echo '/opt/storage/primary 10.1.1.0/24(rw,wdelay,no_root_squash,no_subtree_check)' > /etc/exports
echo '/opt/storage/secondary 10.1.1.0/24(rw,wdelay,no_root_squash,no_subtree_check)' >> /etc/exports
exportfs -a
cd /opt/storage/secondary
mkdir -p template/tmpl/1/1
mkdir -p template/tmpl/1/5
cd template/tmpl/1/5
UUID=ac671f72-ba33-4d36-ab30-481010700f1f
rm -f \`ls *vhd | grep -v \$UUID.vhd\`
download ttylinux_pv.vhd \$UUID.vhd 046e134e642e6d344b34648223ba4bc1
echo filename=\$UUID.vhd > template.properties
echo description=tiny linux >> template.properties
echo checksum=046e134e642e6d344b34648223ba4bc1 >> template.properties
echo hvm=false >> template.properties
echo size=52428800 >> template.properties
echo vhd=true >> template.properties
echo id=5 >> template.properties
echo public=true >> template.properties
echo vhd.filename=\$UUID.vhd >> template.properties
echo uniquename=tiny-linux >> template.properties
echo vhd.virtualsize=52428800 >> template.properties
echo virtualsize=52428800 >> template.properties
echo vhd.size=52428800 >> template.properties

cd /opt/storage/secondary/template/tmpl/1/1
UUID=731f83d1-1808-447c-8285-02636114c464
CHECKSUM=34df350c1ff9dd3da07972182ef3db20
rm -f \`ls *vhd | grep -v 731f83d1-1808-447c-8285-02636114c464\`
CURRENTCS=\`/usr/bin/md5sum \$UUID.vhd | awk '{print \$1}'\`
if [ "\$CHECKSUM" != "\$CURRENTCS" ] ; then
  rm -f *
  download systemvm64template-unknown-xen.vhd.bz2 \$UUID.vhd.bz2 90cd128a99fb1299d071eeb980f61ae3
  bunzip2 \$UUID.vhd.bz2
fi
echo filename=\$UUID.vhd > template.properties
echo description=SystemVM Template >> template.properties
echo checksum=\$CHECKSUM >> template.properties
echo hvm=false >> template.properties
echo size=565240320 >> template.properties
echo vhd=true >> template.properties
echo id=1 >> template.properties
echo public=true >> template.properties
echo vhd.filename=\$UUID.vhd >> template.properties
echo uniquename=routing-1 >> template.properties
echo vhd.virtualsize=565240320 >> template.properties
echo virtualsize=565240320 >> template.properties
echo vhd.size=565240320 >> template.properties

/etc/init.d/nfs start
chkconfig nfs on

EOF
ssh -p $PORT -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'sudo bash -x prepare_for_nfs.sh'

echo Cleanup
ssh -p $PORT -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'cat > cleanup.sh' <<EOF
source ~bootstrap/utils.sh
if grep student /etc/passwd ; then
  echo User already exists
else
    useradd -m -p '\$1\$v7S2RHMn\$M5KoYzIFHw0i/9z5iZ44w0' student
    echo 'student ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/student
fi
rm *.sh
EOF
ssh -p $PORT -i ~/.ssh/bootstrap_key_rsa bootstrap@$1 'sudo bash -x cleanup.sh'








