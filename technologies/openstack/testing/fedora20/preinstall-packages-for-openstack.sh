# This script is generally used in preparation of template to avoid
# installing the same stuff again and again.

# update vim-minimal if possible to avoid conflict.
yum install -y vim-minimal
# below is extracted from devstack installation log.
yum install -y bridge-utils curl dbus euca2ools git-core openssh-server openssl openssl-devel psmisc pylint python-setuptools python-unittest2 python-virtualenv python-devel screen tar tcpdump unzip wget which bc gcc libffi-devel python-argparse python-eventlet python-greenlet python-lxml python-paste-deploy python-routes python-sqlalchemy python-wsgiref pyxattr python-greenlet libxslt-devel python-lxml python-paste python-paste-deploy python-paste-script python-routes python-sqlalchemy python-webob sqlite python-dateutil fping MySQL-python curl dnsmasq-utils ebtables gawk genisoimage iptables iputils kpartx libxml2-python numpy m2crypto parted polkit python-boto python-cheetah python-eventlet python-feedparser python-greenlet python-iso8601 python-kombu python-lockfile python-migrate python-mox python-paramiko python-paste python-paste-deploy python-qpid python-routes python-sqlalchemy python-suds python-tempita sqlite sudo iscsi-initiator-utils lvm2 genisoimage sysfsutils sg3_utils numpy Django gcc pylint python-anyjson python-BeautifulSoup python-boto python-coverage python-dateutil python-eventlet python-greenlet python-httplib2 python-kombu python-migrate python-mox python-nose python-paste python-paste-deploy python-routes python-sphinx python-sqlalchemy python-webob pyxattr Django gcc pylint python-anyjson python-BeautifulSoup python-boto python-coverage python-dateutil python-eventlet python-greenlet python-httplib2 python-kombu python-migrate python-mox python-nose python-paste python-paste-deploy python-routes python-sphinx python-sqlalchemy python-webob pyxattr MySQL-python dnsmasq-utils ebtables iptables iputils python-boto python-eventlet python-greenlet python-iso8601 python-kombu python-paste python-paste-deploy python-qpid python-routes python-sqlalchemy python-suds sqlite sudo MySQL-python dnsmasq-utils ebtables iptables iputils python-boto python-eventlet python-greenlet python-iso8601 python-kombu python-paste python-paste-deploy python-qpid python-routes python-sqlalchemy python-suds sqlite sudo
#yum install -y rabbitmq-server # better installed after host name modification
yum install -y mysql-server
yum install -y openvswitch
yum install -y haproxy
yum install -y kvm
yum install -y libvirt
yum install -y libvirt-python
yum install -y python-libguestfs
yum install -y httpd mod_wsgi
yum install -y openswan
# These libs shall be kept up-to-date as well; needed by qemu.
# see https://bugzilla.redhat.com/show_bug.cgi?id=1066630
yum install -y glusterfs-libs glusterfs glusterfs-api glusterfs-fuse

