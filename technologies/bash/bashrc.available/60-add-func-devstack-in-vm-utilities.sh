# Devstack functions that are meant to run within vm.

function pause {
  echo -e $1
  read -n 1 -r -p ''
}

function pause_to_continue {
  pause "$1\n
    It is recommended to press Ctrl+C to quit;\n
    or if you know what you are doing, press any other key to continue ..."
}

function service_start {
  if [ -z "$1" ]; then
    return
  fi
  sudo service $1 start >/dev/null

  # services that need special treatment
  local rabbitmq='rabbitmq-server'
  local httpd='httpd'
  if [ $1 = $rabbitmq ]; then
    if sudo rabbitmqctl status 2>&1 | sed 1d | head -n 1 | \
       grep -q '^Error:'; then
      echo "#Info: service '$rabbitmq' in Error status; restart it  ..."
      sudo service $rabbitmq restart
    fi
  elif [ $1 = $httpd ]; then
    if telnet localhost 80 < /dev/null 2>/dev/null | \
       grep -q '^Connected to'; then
      return
    fi
    echo "#Info: service $httpd in trouble; restart it ..."
    sudo service httpd restart
  fi
}

function service_stop {
  if [ -z "$1" ]; then
    return
  fi
  sudo service $1 stop
}

function devstack_dependencies {
  if hostname | grep -q control; then
    service_start  mariadb
    service_start httpd
  fi
  service_start openvswitch
  service_start rabbitmq-server
  sudo /usr/share/openvswitch/scripts/ovs-ctl start
}

function devstack_tip {
  echo '
    Note that the devstack installation and running process is a long one.
    Typically devstack is installed in vm via ssh login. If this is the case
    and the ssh login connection is not perfectly reliable, it is better to
    execute the commands (./stack.sh) in the virtual console in the virtual
    machine manager (for example, virt-manager), or in some terminal manager
    (for example, GNU screen). This ensures that the process is not
    interrupted when the connection is broken.'
}

function determine_ipv4_from_interfaces {
  for dev in $@; do
    sudo ifconfig $dev 2>/dev/null
  done | awk '$1=="inet"&&$2~/[0-9]*\.[0-9]*\.[0-9]*\.[0-9]/{print $2}'
}

# modify the configuration file for use in this host.
# limitations:
# 1. We can only deduce name and IP address of this host, make modification
#    according host type; we have no way of knowing nfo of other hosts. In
#    particular, compute nodes cannot update host ip of the control node.
function local_conf_edit {
  local conf=$1 # config file to edit
  local type=$2 # control or compute
  if [ -z "$1" -o -z "$2" ]; then
    return
  fi
  local ip1=$(determine_ipv4_from_interfaces eth0 br-ex ens3)
  local ip2=$(determine_ipv4_from_interfaces eth1 ens7)
  if [ -z "$ip1" -o -z "$ip2" ]; then
    echo "#Error: cannot determine IPs for the host."
    return
  fi
  __config_plain_file_key_val $conf \
  $(echo "${type}_PUBLIC"  | tr "[:lower:]" "[:upper:]") $ip1 '='
  __config_plain_file_key_val $conf \
  $(echo "${type}_PRIVATE" | tr "[:lower:]" "[:upper:]") $ip2 '='
  if [ "$type" != "control" ]; then
    echo "#Info: pls manually update control node IPs in '$conf' if necessary."
  fi
}

function devstack {
  local shared=$(libvirt_lxc_shared_dir)
  local devstack_src=$shared/git/devstack
  local devstack=~/devstack
  local stack_src=$shared/git/openstack
  local stack=/opt/stack

  devstack_dependencies

  # prepare $stack
  if [ -d $stack ]; then
    pause_to_continue "#Warning: directory '$stack' exists with undefined
    content, we will skip any modification to it."
  else
    sudo mkdir -vp $stack
    sudo chown -R $(whoami) $stack
    bash -c "cd $stack
      for d in $stack_src/*; do
        if [ -d \$d/.git ]; then
          # While in container vm it is safe to symlink the repo dirs, in
          # full virtualization we must git-clone the repos.
          if [ _$VMTYPE = _container ]; then
            ln -s \$d
          else
            git clone \$d
          fi
        fi
      done
    "
  fi
  
  # prepare $devstack
  if [ -d $devstack ]; then
    pause_to_continue "#Warning: directory '$devstack' exists with undefined
      content, we will skip any modification to it."
  else
    git clone $devstack_src $devstack
    bash -c "
      cd $devstack/files
      for f in $devstack_src/files/*; do
        if [ -f \$f ]; then
          ln -s \$f 1>/dev/null 2>/dev/null # ignore any 'file exist' prompt
        fi
      done
    "

    # prepare local.conf
    if hostname | grep -q control; then
      type=control
    elif hostname | grep -q compute; then
      type=compute
    fi
    if [ ! -z "$type" ]; then
      echo "Auto-configuration based on hostname:"
      echo "    node type: $type"
      local conf=$(ls $devstack/local.conf.d/local.conf*$type* 2>/dev/null | \
        tail -n 1)
      if [ ! -z "$conf" ]; then
        echo "    config file: $conf"
        if echo $conf | grep -q 'local\.conf'; then
          ln -s $conf $devstack/local.conf
          local_conf_edit $conf $type
        fi
      fi
    fi
  fi
  cd $devstack # so that we could execute ./stack.sh
  echo '
A fresh copy of devstack is made; you may do the following to install it:
1. Create customized local.conf. A symlink to the last file from local.conf.d
   as reported by ls if there are any, but you are free to create your own.
2. ./stack.sh'
  devstack_tip
  echo '
3. devstack_postinstall'
}

function restack {
  devstack_dependencies
  if [ -t 0 ]; then  # tty, then as is
    bash -c 'cd ~/devstack; ./rejoin-stack.sh'
  else  # no tty; then detached
    bash -c 'cd ~/devstack; ./rejoin-stack-detached.sh'
  fi
}

function unstack {
  cd ~/devstack
  ./unstack.sh
  for s in mariadb rabbitmq-server httpd; do
    service_stop $s
  done >/dev/null 2>/dev/null
}

function os_add_my_key {
  local dir=~/.ssh
  local key=`ls $dir/*.pub 2>/dev/null | head -n 1`
  if [ -z "$key" ] ; then
    ssh-keygen # do keygen only if necessary
  fi
  local key=`ls $dir/*.pub 2>/dev/null | head -n 1`
  if [ -z "$key" ] ; then
    echo "#Error: cannot find ssh key file in $dir after ssh-keygen attempt."
    return
  fi
  nova keypair-add --pub_key $key mykey
}

function os_add_secgroup_rules_for_ssh_ping {
  nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
  nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
}

function devstack_postinstall {
  echo "
#Info: Configurations after devstack installation to perform:
  1. add ssh key $(add_my_key)
  2. add security group rules for ssh & icmp $(add_secgroup_rules_for_ssh_ping)
"
}

