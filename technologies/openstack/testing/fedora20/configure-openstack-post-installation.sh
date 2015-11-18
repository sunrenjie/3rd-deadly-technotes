#!/bin/bash

# Utilitiy functions that fixes openstack installations on fedora 20 in kvm
# that does not function normally after reboot. In one word, the OS fedora 20
# have minor bugs.

# Please distinguish between configuring the operating system and configuring
# openstack. The former requires root and is performed in this script, while
# the latter requires openstack admin credential and can be performed by any
# user. Usually, the latter is put in local bashrc for convenience.

# Add br-ex if necessary (needed in devstack and not in RDO packstack)
# Mysteriously the configuration for br-ex in devstack is via command line
# without even attempt to make the configuration persistent (RDO packstack
# makes such attempt by writing the config file, which though is not actually
# working).
function add_br_ex {
  local config='/etc/sysconfig/network-scripts/ifcfg-br-ex'
  if [ -e $config ]; then
    return
  fi
  cat <<EOF > $config
DEVICE=br-ex
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=static
IPADDR=172.24.4.1
NETMASK=255.255.255.0
ONBOOT=yes
EOF
}

# Fix that make network service work for br-ex.
# Mysteriously, configuration for br-ex does not persist after OS reboot. It
# turned out that the configuration file is OK, but the OS does not process
# it as expected.
function fix_ifup_for_br_ex {
  cd /etc/sysconfig/network-scripts/
  local old=./ifup
  local new=./ifup.renamed-to-fix-br-ex-in-ad-hoc-manner
  if [ "_$1" = "_fix" -a -e $old -a ! -e $new ]; then
    mv $old $new
    cat <<EOF > $old
# wrapper for $old for br-ex (now renamed to $new)
if [ "_\$1" = "_br-ex" ]; then
  $new \$@
  ./ifdown \$@
  $new \$@
else
  $new \$@
fi
EOF
    chmod +x $old
  elif [ "_$1" = "_restore" -a -e $old -a -e $new ]; then
    rm -f $old
    mv $new $old
  else
    echo "#Info: fix_ifup_for_br_ex: nothing to do."
  fi
}

# Fix that make network service work for all nics.
# These pecularities make network to complain. Maybe this is a way of
# disabling network service and use NetworkManager.
function fix_config_for_all_nics {
  ls /etc/sysconfig/network-scripts/ifcfg-* | grep -P 'ifcfg\-[a-z]+[0-9]+$' \
   | while read l; do
    sed -i -e 's/^NAME=/DEVICE=/' -e 's/^HWADDR=/#HWADDR=/' $l
  done
}

function disable_service {
  if [ -z "$1" ]; then
    return
  fi
  chkconfig $1 off
  service $1 stop
}

function enable_service {
  if [ -z "$1" ]; then
    return
  fi
  chkconfig $1 on
  service $1 start
}

function fix_network_service {
  disable_service NetworkManager
  enable_service network
}

function fix_firewall {
  disable_service firewalld
  enable_service iptables
}

function fix_rabbitmq_server {
  if rabbitmqctl status 2>&1 | sed 1d | head -n 1 | grep '^Error:' >/dev/null; then
    echo "#Info: trying to restart rabbitmq-server that is down ..."
    service rabbitmq-server restart
  fi
}

# detect-and-fix of httpd service in a simple-mined way, assuming the listening
# port is 80.
function fix_httpd {
  if telnet localhost 80 < /dev/null 2>/dev/null | \
   grep '^Connected to' > /dev/null; then
    return
  fi
  echo "Info: trying to restart httpd that seems to be abnormal ..."
  service httpd restart
}

function doit {
  if hostname | grep compute >/dev/null; then # compute node
    # explicitly disable mariadb if possible in compute node
    disable_service mariadb >/dev/null 2>/dev/null
  else
    # br-ex and mariadb are only for control node
    add_br_ex
    fix_ifup_for_br_ex fix
    enable_service mariadb
  fi
  fix_config_for_all_nics
  fix_network_service
  fix_firewall
  enable_service rabbitmq-server
  # in case rabbitmq-server is running in error status before doit()
  fix_rabbitmq_server
  enable_service openvswitch
}

# entry point; force root
if [ "_$UID" = "_0" -a "_$1" = "_doit" ]; then
  doit
else
  echo "Usage: sudo bash configure-openstack-post-installation.sh doit"
fi

