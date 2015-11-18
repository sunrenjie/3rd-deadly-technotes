
# These ssh options make the login faster in sacrifice of security; but this
# is OK for local purposes.
function SSH {
  env ssh -o StrictHostKeyChecking=no -o GSSAPIAuthentication=no \
      -o UserKnownHostsFile=/dev/null $@
}

function ssh_execute {
  local login=$1
  local cmds=$2 # a string of commands separated by ';'
  if [ -z "$login" ] || [ -z "$cmds" ]; then
    echo "#Usage: ssh_execute user@host 'cmd1 ; cmd2 ; cmd3 ; ...'"
    return
  fi
  echo "#Info: executing SSH $login $cmds"
  # N.B.:
  # 1. Quoting "$cmds" considered necessary
  # 2. '-t' specified to force tty allocation (for sudo commands)
  SSH -t $login "$cmds"
}

# set ip-host binding in /etc/hosts in ssh host.
function ssh_set_ip_host_binding {
  local ip=$1
  local host=$2
  if [ -z "$ip" ] || [ -z "$host" ] || \
     ! echo $host | grep '^[0-9A-Za-z\.-]*$' >/dev/null; then
    echo \
"Usage: ssh_set_ip_host_binding ip host-name [ user@host ],
  whereas 'user' defaults to current user and 'host' defaults to localhost.
Also, the host-name shall only contain characters from [0-9A-Za-z\.-]."
    return
  fi
  # The param $login is of the format 'user@host', or 'host' (user is the one
  # running this command), or null (interpreted as localhost). On modern
  # UNIX-like hosts, system commands are supposed to be executed as sudo,
  # therefore we execute commands here by 'sudo bash -c "commands"'. When login
  # is root@host, sudo asks no password and everything is OK.
  local login=$3
  if [ -z "$login" ]; then
    login='localhost'
  fi
  # remove any entry
  
  local c1="grep -v \"^[0-9].*$host$\" /etc/hosts > /tmp/hosts"
  # add new entry
  local entry="$ip $host"
  local c2="echo -e $entry >> /tmp/hosts"
  local c3="if grep \"$entry\" /tmp/hosts >/dev/null; then mv /tmp/hosts /etc/hosts ; fi"
  local c="$c1; $c2; $c3"
  ssh_execute $login "sudo bash -c '$c'"
}

# install my ssh key in remote computer to allow ssh login without password
function ssh_install_key {
  local dir=.ssh
  local ak=$dir/authorized_keys
  local login=$1
  if [ -z "$login" ] ; then
    login='localhost'
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

# set hostname of the ssh host
function ssh_set_hostname {
  local ip=$1
  local name=$2
  local user=root # setting hostname requires root; so default to root
  if [ -z "$ip" ] || [ -z "$name" ]; then
    echo "#Usage: ssh_set_hostname ip host-name"
    return
  fi
  local c1="hostname $name"
  local c2="echo '$name' > /etc/hostname"
  local c3="echo '127.0.0.1 $name' >> /etc/hosts"
  local c4="echo '::1 $name' >> /etc/hosts"
  ssh_execute $user@$ip "$c1 ; $c2 ; $c3 ; $c4"
}

function ssh_set_password {
  local login="$1"
  local user="$2"
  local password="$3"
  if [ -z "$login" ] || [ -z "$user" ] || [ -z "$password" ]; then
    echo "#Usage: ssh_set_password user@host user password-string"
    return
  fi
  ssh_execute $login "echo $password | passwd --stdin $user"
}

