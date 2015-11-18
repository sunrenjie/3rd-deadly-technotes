#!env bash

# See usage() for details.
# Implementation notes:
# 1. If ssh commands are to be executed in loop of form
#    'while read l; do ...; done', a unique (possibly arbitrary) file
#    descriptor shall be used:
#
#    while read -u100; do # using arbitrary file descriptor 100 for input-file
#      ssh ...
#    done 100< input-file
#
#    When the content is read from stdout, however, the syntax becomes:
#
#    while read -u200; do
#      ssh ...
#    done 200< <(cat input-file)
#
#    Note that such descriptor syntax is bashism.
#
# 2. The usage() is designed to provide a real world, heavily used example,
#    which can be displayed or executed by ui() depending on whether the first
#    argument is 'doit'. Executing this program without any parameter for
#    details.

# These ssh/scp options make the login faster in sacrifice of security; but
# this is OK for manipulating VMs.
function SSH {
  ssh -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no $@
}

function SCP {
  scp -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no $@
}

function ssh_execute {
  local login=$1
  local cmds=$2 # a string of commands separated by ';'
  if [ -z "$login" ] || [ -z "$cmds" ]; then
    echo "#Info: ssh_execute user@host 'cmd1 ; cmd2 ; cmd3 ; ...'"
    return
  fi
  echo "#Info: executing $SSH $login $cmds"
  SSH $login "$cmds" # quoting "$cmds" considered necessary
}

# install ssh key in remote computer to allow ssh login without password
function install_ssh_key {
  local login=$1
  local dir=.ssh
  local ak=$dir/authorized_keys
  if [ -z "$login" ] ; then
    echo "#Info: usage: install_ssh_key user@host"
    return
  fi
  local key=`ls ~/$dir/*.pub 2>/dev/null | head -n 1`
  if [ -z "$key" ] ; then
    ssh-keygen # do keygen only if necessary
  fi
  local key=`ls ~/$dir/*.pub 2>/dev/null | head -n 1`
  if [ -z "$key" ] ; then
    echo "#Error: cannot find ssh key file in ~/.ssh after ssh-keygen attempt."
    return
  fi
  local c1="mkdir $dir 1>/dev/null 2>/dev/null"
  local c2="echo '$(cat $key)' >> $ak"
  local c3="chmod 700 $dir"
  local c4="chmod 600 $ak"
  ssh_execute $login "$c1 ; $c2 ; $c3 ; $c4"
}

function install_ssh_key_for_user_for_all {
  local mapping=$1
  local user=$2
  if [ -z "$mapping" ] || [ ! -e "$mapping" ] || [ -z "$user" ]; then 
    echo "Usage: install_ssh_key_for_user_for_all mapping-file username"
    return
  fi
  while read -u10 l; do # special file descriptor used because of ssh
    arr=($l)
    ip=${arr[1]}
    install_ssh_key $user@$ip
  done 10< $mapping
}

function set_hostname {
  local ip=$1
  local name=$2
  local user=root # setting hostname requires root; so default to root
  if [ -z "$ip" ] || [ -z "$name" ]; then
    echo "Usage: set_hostname ip(x.x.x.x) host-name"
    return
  fi
  local c1="hostname $name"
  local c2="echo '$name' > /etc/hostname"
  local c3="echo '127.0.0.1 $name' >> /etc/hosts"
  local c4="echo '::1 $name' >> /etc/hosts"
  ssh_execute $user@$ip "$c1 ; $c2 ; $c3 ; $c4"
}

function set_hostname_for_all {
  local mapping=$1
  if [ -z "$mapping" ] || [ ! -e "$mapping" ]; then
    echo "Usage: set_hostname_for_all mapping-file"
    return
  fi
  while read -u11 l; do # special file descriptor used because of ssh
    local arr=($l)
    local name=${arr[0]}
    local ip=${arr[1]}
    set_hostname $ip $name
  done 11< $mapping
}

function set_nic2 {
  local host=$1
  local nic2=$2
  local ip2=$3
  local netmask2=$4
  local user=root
  if [ -z "$host" -o -z "$nic2" -o -z "$ip2" -o \
       -z "$netmask2" -o -z "$user" ] ; then
    echo "Usage: set_nic2 host nic2-name ip2 netmask2"
    return
  fi
  cat <<EOF | SSH $user@$host "cat > /etc/sysconfig/network-scripts/ifcfg-$nic2"
TYPE="Ethernet"
BOOTPROTO="static"
DEVICE="$nic2"
ONBOOT="yes"
PEERDNS="yes"
PEERROUTES="yes"
IPADDR=$ip2
NETMASK=$netmask2
EOF
  SSH $user@$host "ifup $nic2 ; ifconfig $nic2"
}

function set_nic2_for_all {
  local mapping=$1
  if [ -z "$mapping" ] || [ ! -e "$mapping" ]; then
    echo "Usage: set_nic_for_all mapping-file"
    return
  fi
  while read -u12 l; do # special file descriptor used because of ssh
    local arr=($l)
    local name=${arr[0]}
    local ip1=${arr[1]}
    local ip2=${arr[2]}
    set_nic2 $ip1 ens7 $ip2 255.255.255.0
  done 12< $mapping
}

function scp_scripts_to_home_dir {
  local login=$1
  shift
  SCP $@ "$login:~/"
}

function scp_scripts_to_home_dir_for_all {
  local mapping=$1
  if [ -z "$mapping" ] || [ ! -e "$mapping" ]; then
    echo "Usage: scp_scripts_to_home_dir_for_all mapping-file"
    return
  fi
  shift
  while read -u13 l; do # special file descriptor used because of ssh
    local arr=($l)
    local ip1=${arr[1]}
    scp_scripts_to_home_dir r@$ip1 $@
  done 13< $mapping
}

function __usage__ {
  local SCRIPT=$(readlink -f $0 2>/dev/null)
  local DIR=$(dirname $SCRIPT 2>/dev/null)
  echo "
# $SCRIPT:
# Utilities for making (batched or individual) configurations to VMs for
# faster deployment of devstack.
# Typically usage:
#
# Given the ip-hostname mapping file for VMs 'mapping-ip-hostname' contains
#
#    f20-devstack	192.168.1.111	192.168.0.111
#    f20-compute1	192.168.1.116	192.168.0.116
#
# do the following:

# install ssh key of this active account to all VMs for user root:
install_ssh_key_for_user_for_all '$DIR/mapping-ip-hostname' root

# install ssh key of this active account to all VMs for user root:
install_ssh_key_for_user_for_all '$DIR/mapping-ip-hostname' r	

# set hostnames for all VMs:
set_hostname_for_all mapping-ip-hostname

# set 2nd nic for all VMs:
set_nic2_for_all mapping-ip-hostname

# scp scripts to home directory of the user:
scp_scripts_to_home_dir_for_all mapping-ip-hostname \
  $DIR/bashrc-local $DIR/bashrc-local-sudo \
  $DIR/configure-openstack-post-installation.sh \
  $DIR/preinstall-packages-for-openstack.sh

# If the conditions and purposes of this example fits yours precisely, you may
# add an additional argument to the command executing this script:
# bash $SCRIPT doit
"
}

function __ui__ {
  if [ "_$1" != "_doit" ]; then
    __usage__
    return
  fi
  # Execute the example
  # Note that commands shall start with an alphabet; so the grep.
  while read -u12 l; do
    echo "#Info: executing: $l"
    eval "$l"
  done 12< <(__usage__ | grep '^[a-zA-Z]' 2>/dev/null)
}

__ui__ $@

