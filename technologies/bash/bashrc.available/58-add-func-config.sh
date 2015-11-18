# system configuration functions
# If environment variable ROOTFS is defined as root directory of some container
# file system, it is taken that the commands are to be run in the container.

function __config_plain_file_key_val {
  local config=$1
  local key=$2
  local val=$3
  local sep=$4
  if [ ! -f $config ]; then
    echo "#Warning: config file '$config' not found; software not installed?"
    return
  fi
  if [ -z "$sep" ]; then
    local sep=' '
  fi
  if grep -q "^$key$sep$val$" $config; then # exact key-value match
    echo "#Info: configuration '$key$sep$val' already there; nothing to do."
    return
  elif grep -q "^$key$sep" $config; then # key match with other value
    sed -i "s/^$key$sep.*$/$key$sep$val/" $config
  else # no match at all
    echo "$key$sep$val" >> $config
  fi
  echo "#Info: config file '$config' updated."
}

# configure yum to cache downloaded installation files.
function config_yum_keep_cache {
  echo '#Info: configuring yum to keep cache ...'
  local config=$ROOTFS/etc/yum.conf
  local key=keepcache
  local val=1
  __config_plain_file_key_val $config $key $val '='
}

# disable SELinux
function config_selinux_disabled {
  echo '#Info: disabling SELinux ...'
  local config=$ROOTFS/etc/selinux/config
  local key=SELINUX
  local val=disabled
  __config_plain_file_key_val $config $key $val '='
  if [ -z "$ROOTFS" -a -f $config ]; then
    setenforce 0
  fi
}

function config_sshd_restart {
  if uname -a | grep -q Darwin; then # macosx
    echo "#Info: Please run the following for changes to take effect:"
    echo "           sudo launchctl stop com.openssh.sshd"
    echo "           sudo launchctl start com.openssh.sshd"
    echo "       Or, reboot the operating system."
  elif uname -a | grep -q Linux; then # linux
    if [ -z "$ROOTFS" ]; then
      service sshd restart
    fi
  fi
}

function config_sshd {
    if [ -z "$1" ]; then
      echo "#Info: usage: config_sshd subjects"
      return
    fi
    local subjects=$1
  echo '#Info: configuring sshd ...'
  local config=$(ls $ROOTFS/etc/ssh/sshd_config $ROOTFS/etc/*/sshd_config \
    $ROOTFS/etc/sshd_config 2>/dev/null | head -n 1)
  if [ -z "$config" -o ! -f "$config" ]; then
      echo "#Warning: no sshd configuration file found; nothing to do."
      return
  fi
  { # multiple configs go here; call restart if necessary at last
    if echo "$subjects" | grep 'UseDNS_no'; then
      echo "#Info: configuring 'UseDNS no' ..."
      __config_plain_file_key_val $config UseDNS no $3 ' '
    fi
  } | grep -q 'updated' && config_sshd_restart
}

function config_pypi_mirror {
  if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
    echo "#Info: usage: config_pypi_mirror home-dir mirror-url cache-dir"
    return
  fi
  local homedir=$1
  local mirror=$2
  local cachedir=$3
  echo '#Info: configuring python mirror ...'
  local conf1=$ROOTFS/$homedir/.pip/pip.conf
  local conf2=$ROOTFS/$homedir/.pydistutils.cfg
  if [ ! -f $conf1 ] ; then
    mkdir -p `echo $conf1 | sed 's:[^\/]*$::'`
    echo "[global]
index-url = $mirror
download_cache = $cachedir
" > $conf1
    echo "#Info: created config file '$conf1' ."
  else
    echo "#Info: skipped existing config file '$conf1' ."
  fi
  
  if [ ! -f $conf2 ] ; then
    echo "[easy_install]
index-url = $mirror
" > $conf2
    echo "#Info: created config file '$conf1' ."
  else
    echo "#Info: skipped existing config file '$conf2' ."
  fi
}

