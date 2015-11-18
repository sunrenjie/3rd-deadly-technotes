
function libvirt_lxc_fedora_pkgs_devstack_minimal {
  echo "systemd passwd yum fedora-release vim-minimal vim-common telnet
  dhclient git-core openssh-server"
}

function libvirt_lxc_fedora_pkgs_devstack_full {
  echo "systemd passwd yum fedora-release vim-minimal vim-common procps-ng
  iproute telnet net-tools dhclient bridge-utils curl dbus euca2ools git-core
  openssh-server openssl openssl-devel psmisc pylint python-setuptools
  python-unittest2 python-virtualenv python-devel screen tar tcpdump unzip wget
  which bc gcc libffi-devel python-argparse python-eventlet python-greenlet
  python-lxml python-paste-deploy python-routes python-sqlalchemy
  python-wsgiref pyxattr python-greenlet libxslt-devel python-lxml python-paste
  python-paste-deploy python-paste-script python-routes python-sqlalchemy
  python-webob sqlite python-dateutil fping MySQL-python curl dnsmasq-utils
  ebtables gawk genisoimage iptables iputils kpartx libxml2-python numpy
  m2crypto parted polkit python-boto python-cheetah python-eventlet
  python-feedparser python-greenlet python-iso8601 python-kombu python-lockfile
  python-migrate python-mox python-paramiko python-paste python-paste-deploy
  python-qpid python-routes python-sqlalchemy python-suds python-tempita sqlite
  sudo iscsi-initiator-utils lvm2 genisoimage sysfsutils sg3_utils numpy Django
  gcc pylint python-anyjson python-BeautifulSoup python-boto python-coverage
  python-dateutil python-eventlet python-greenlet python-httplib2 python-kombu
  python-migrate python-mox python-nose python-paste python-paste-deploy
  python-routes python-sphinx python-sqlalchemy python-webob pyxattr Django gcc
  pylint python-anyjson python-BeautifulSoup python-boto python-coverage
  python-dateutil python-eventlet python-greenlet python-httplib2 python-kombu
  python-migrate python-mox python-nose python-paste python-paste-deploy
  python-routes python-sphinx python-sqlalchemy python-webob pyxattr
  MySQL-python dnsmasq-utils ebtables iptables iputils python-boto
  python-eventlet python-greenlet python-iso8601 python-kombu python-paste
  python-paste-deploy python-qpid python-routes python-sqlalchemy python-suds
  sqlite sudo MySQL-python dnsmasq-utils ebtables iptables iputils python-boto
  python-eventlet python-greenlet python-iso8601 python-kombu python-paste
  python-paste-deploy python-qpid python-routes python-sqlalchemy python-suds
  sqlite sudo rabbitmq-server mysql-server openvswitch haproxy kvm libvirt
  libvirt-python python-libguestfs httpd mod_wsgi openswan glusterfs-libs
  glusterfs glusterfs-api glusterfs-fuse"
}

# Devstack nodes will have two NICs, whose MAC addresses will be randomly
# generated.
function __libvirt_lxc_devstack_node_install_config_file {
  local name=$1   # VM name; e.g.: 'fedora20'
  local memory=$2 # in KB; e.g.: 524288, which is 512MB
  local vcpus=$3  # number of vcpus; e.g.: 4
  local rootfs=$4 # root file system

  if [ -z "$name" -o -z "$memory" -o -z "$vcpus" ]; then
    echo "#Usage: libvirt_lxc_install_config_file_for_devstack name memory \
    vcpus"
    return
  fi
  echo "#Info: installing config file for node '$name' ..."
  local xml=$(libvirt_lxc_config_dir)/$name.xml
  if [ -f $xml ]; then
    echo "#Info: config file '$xml' exists; skipped."
    return
  fi
  local uuid=$(cat /proc/sys/kernel/random/uuid)
  # random mac addresses
  local mac1=$(cat /proc/sys/kernel/random/uuid | md5sum | \
    sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
  local mac2=$(cat /proc/sys/kernel/random/uuid | md5sum | \
    sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
  local shared=$(libvirt_lxc_shared_dir)
  cat <<EOF > $xml
<!--
WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
OVERWRITTEN AND LOST. Changes to this xml configuration should be made using:
  virsh edit $name
or other application using the libvirt API.
-->

<domain type='lxc'>
  <name>$name</name>
  <uuid>$uuid</uuid>
  <memory unit='KiB'>$memory</memory>
  <currentMemory unit='KiB'>$memory</currentMemory>
  <vcpu placement='static'>$vcpus</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='x86_64'>exe</type>
    <init>/sbin/init</init>
  </os>
  <features>
    <privnet/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/libexec/libvirt_lxc</emulator>
    <filesystem type='mount' accessmode='passthrough'>
      <source dir='$rootfs'/>
      <target dir='/'/>
    </filesystem>
    <filesystem type='mount' accessmode='passthrough'>
      <source dir='$shared'/>
      <target dir='$shared'/>
    </filesystem>
    <filesystem type='mount'>
      <source dir='/proc/sys'/>
      <target dir='/proc/sys'/>
    </filesystem>
    <interface type='bridge'>
      <mac address='$mac1'/>
      <source bridge='br0'/>
    </interface>
    <interface type='bridge'>
      <mac address='$mac2'/>
      <source bridge='br1'/>
    </interface>
    <console type='pty'>
      <target type='lxc' port='0'/>
    </console>
    <hostdev mode='capabilities' type='misc'>
      <source>
        <char>/dev/net/tun</char>
      </source>
    </hostdev>
  </devices>
</domain>
EOF
  service libvirtd restart # TODO: more portable method required
}

function libvirt_lxc_devstack_node_deploy {
  local name=$1    # vm name
  local memory=$2  # vm memory in KB
  local vcpus=$3   # vm number of vcpus
  local mac=$4     # mac addr of the 1st nic to assign predefined IP address
  local ip=$5      # ip address of the 2nd nic interface
  local netmask=$6 # netmask of the 2nd nic interface
  local cache=$7   # cache directory to use; containing yum and pip, etc.
  local pkgs=$8    # list of packages to install, separated by white chars
  # In addition,
  # 1) $cache shall be a directory containing cache subdirectory for yum and
  #    pip.

  local rootfs=$(libvirt_lxc_root_dir)/$name
  local shared=$(libvirt_lxc_shared_dir)

  # Mandated packages as we need to configure them below: sudo openvswitch
  __libvirt_lxc_fedora_install $name "sudo openvswitch $pkgs" $cache
  __libvirt_lxc_enable_console $rootfs
  __libvirt_lxc_write_network_script_for_nic_ovs_bridged $rootfs eth0 \
    br-ex $mac
  __libvirt_lxc_write_network_script_for_nic $rootfs eth1 \
    "TYPE=Ethernet,BOOTPROTO=static,IPADDR=$ip,NETMASK=$netmask"
  __libvirt_lxc_enable_networking $rootfs
  __libvirt_lxc_set_hostname $rootfs $name
  export ROOTFS=$rootfs # calling config functions starts
  config_sshd 'UseDNS_no'
  config_yum_keep_cache
  config_selinux_disabled
  # in-vm path /var/cache/pip is defined in libvirt_lxc_yum_install_packages
  config_pypi_mirror /root http://pypi.gocept.com/simple \
    /var/cache/pip
  export ROOTFS=        # calling config functions ends
  __libvirt_lxc_devstack_node_install_config_file $name $memory $vcpus $rootfs

  # prepare users: r and root
  local user=r
  local user_password=r
  local root_password=r
  __libvirt_lxc_add_user $rootfs $user
  __libvirt_lxc_change_password $rootfs $user $user_password
  __libvirt_lxc_change_password $rootfs root  $root_password
  echo -e "r ALL=(ALL) NOPASSWD:ALL" >> $rootfs/etc/sudoers

  # prepare notes repo
  git clone $shared/git/notes $rootfs/home/$user/notes
  bash -c "cd $rootfs/home/$user
    ln -s notes/technologies/bash/bashrc.bootstrapper
    ln -s notes/technologies/bash/bashrc.available bashrc.enabled # enable all
    echo '
# define vm type (container or kvm, etc); for optimized deployment of devstack
export VMTYPE=container

source /etc/bashrc
source \$HOME/bashrc.bootstrapper' >> .bashrc
"
}

