# execute on the vm f20-rdo
sudo yum remove -y mariadb mariadb-libs mariadb-server
sudo yum install -y http://rdo.fedorapeople.org/rdo-release.rpm
sudo yum install -y openstack-packstack
packstack --allinone
