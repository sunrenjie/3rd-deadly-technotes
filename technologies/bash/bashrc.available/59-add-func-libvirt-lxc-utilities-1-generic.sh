# libvirt+lxc container utility functions; currently only fedora is supported.

function libvirt_lxc_yum_get_release {
  local rootfs=$1
  local rel=$rootfs/etc/fedora-release
  if [ ! -f $rel ]; then
    return
  fi
  cat $rel | grep -o 'Fedora release [0-9]*' | awk '{print $3}'
}

function libvirt_lxc_root_dir {
  echo "/var/lib/libvirt/filesystems"
}

function libvirt_lxc_config_dir {
  echo "/etc/libvirt/lxc"
}

# This path points to the primary shared folder between host and vm, such that
# we can access the same file system content under it using the same path,
# no matter whether we are in host or vm.
function libvirt_lxc_shared_dir {
  echo '/host0'
}

# install fedora packages and make symlinks for cache sub-directories.
function __libvirt_lxc_fedora_install {
  local name=$1      # vm name
  local pkgs=$2      # list of white space-separated packages to install
  local cache_src=$3 # cache dir containing yum, pip, and other cache sub-dirs

  local rel=$(libvirt_lxc_yum_get_release)
  local rootfs=$(libvirt_lxc_root_dir)/$name
  local cache_dst=$rootfs/var/cache
  local install="yum -y --installroot=$rootfs"
  local install+=" --releasever=$rel --nogpg install"

  if [ -e $rootfs ]; then
    echo "#Error: root directory '$rootfs' already exists."
    return
  fi
  if [ ! -d $cache_src/yum -a ! -d $cache_src/pip ]; then
    echo "#Error: cache dir '$cache_src' is inadequate"
    return
  fi
  mkdir -vp $cache_dst

  # Installing package 'fedora-release':
  # The package 'fedora-release' contains repo data for yum, without
  # which yum will refuse to continue. The installation of yum in vm
  # will cause further $install commands to read in-vm configuration
  # data. Hence, here is the only one chance we could install repo
  # configuration data into the vm.
  ln -s $cache_src/yum $cache_dst/yum
  local cmd="$install fedora-release"
  echo "#Info: command to execute: $cmd"; $cmd

  # Install yum; then symlink cache subdirectories
  local cmd="$install yum"
  echo "#Info: command to execute: $cmd"; $cmd
  # Installation of yum will destroy any existing yum cache symlink
  # and create a new cache dir. Also, any further $install commands
  # will read in-vm configuration data.
  # Remove the cache dir created and re-create our own.
  rm -rf $cache_dst/yum
  for d in $cache_src/*; do # one symlink per cache subdirectory
    if [ -d $d ]; then
      bash -c "cd $cache_dst && ln -s $d"
    fi
  done
  # Configure yum to help in further $install commands
  export ROOTFS=$rootfs
  config_yum_keep_cache
  export ROOTFS=

  # Perform the remaining of the package installation
  local cmd="$install $pkgs" # yes; $pkgs not surrounded by quotes.
  echo "#Info: command to execute: $cmd"; $cmd
}

function libvirt_lxc_delete {
  if [ -z "$1" ]; then
    echo "#Info: usage: libvirt_lxc_delete vm-name"
    return
  fi
  local name=$1
  rm -rf $(libvirt_lxc_root_dir)/$name
  rm -f $(libvirt_lxc_config_dir)/$name.xml
  service libvirtd restart
}

function __libvirt_lxc_add_user {
  local rootfs=$1
  local user=$2
  echo "#Info: creating user '$user' in container '$rootfs' ..."
  chroot $rootfs /sbin/adduser $user
}

function __libvirt_lxc_change_password {
  local rootfs=$1
  local user=$2
  local password=$3
  echo "#Info: changing root password @ '$rootfs' ..."
  if [ -z "$password" ]; then # no password provided, prompt the user
    chroot $rootfs /bin/passwd $user
  else
    echo $password | chroot $rootfs /bin/passwd --stdin $user
  fi
}

function __libvirt_lxc_enable_console {
  local rootfs=$1
  echo "pts/0" >> $rootfs/etc/securetty
}

function __libvirt_lxc_enable_service {
  local rootfs=$1
  local service=$2
  chroot $rootfs /bin/systemctl enable $service
}

function __libvirt_lxc_disable_service {
  local rootfs=$1
  local service=$2
  chroot $rootfs /bin/systemctl disable $service
}

function __libvirt_lxc_enable_networking {
  local rootfs=$1
  echo 'NETWORKING=yes' > $rootfs/etc/sysconfig/network
  __libvirt_lxc_enable_service $rootfs network
}

function __libvirt_lxc_write_network_script_for_nic {
  local rootfs=$1 # root directory of the file system
  local nic=$2    # nic interface name
  local more=$3   # comma-separated list of additional entries for the script
  local script=$rootfs/etc/sysconfig/network-scripts/ifcfg-$nic
  cat <<EOF > $script
DEVICE=$nic
ONBOOT=yes
DELAY=0
EOF
  echo $more | sed 's:,:\n:g' >> $script
}

function __libvirt_lxc_write_network_script_for_nic_ovs_bridged {
  local rootfs=$1
  local nic=$2
  local br=$3
  local mac=$4
  local prefix=$rootfs/etc/sysconfig/network-scripts/ifcfg-
  cat <<EOF > $prefix$br
DEVICE=$br
DEVICETYPE=ovs
TYPE=OVSBridge
OVSBOOTPROTO=dhcp
OVSDHCPINTERFACES=$nic
ONBOOT=yes
OVS_EXTRA="set Bridge $br other-config:hwaddr=$mac"
EOF
  cat <<EOF > $prefix$nic
DEVICE=$nic
ONBOOT=yes
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=$br
EOF
}

function __libvirt_lxc_set_hostname {
  local rootfs=$1
  local hostname=$2
  echo $hostname > $rootfs/etc/hostname
  echo 127.0.0.1 $hostname >> $rootfs/etc/hosts
  echo ::1       $hostname >> $rootfs/etc/hosts
}

