# SYNOPSIS:
# Open vSwitch (ovs) bridges and ports used together with linux bridges and
# ports are ubuquitus in linux-based virtual networks. Yet unlike linux
# counterparts, ovs bridges and ports cannot be directly analyzed by linux
# tools like tcpdump. Port mirroring is one way of dealing with this.
# Functions in this script implement such idea; they create snoopers for
# one port or whole bridge such that ovs traffic can be analyzed by tools like
# tcpdump.

# create snooper for the port specified
function ovs_snooper_create_for_port {
  if [ -z $(which ovs-vsctl) ]; then
    echo "#Error: please install open vswitch first."
    return
  fi
  local port=$1
  if [ -z $port ]; then
    echo "#Usage: ovs_snooper_create_for_port ovs-port"
    return
  fi
  local br=$(sudo ovs-vsctl port-to-br $port 2>/dev/null)
  if [ -z $br ]; then
    echo "#Error: no port named '$port'" 
    return
  fi
  local prefix=$(echo s-$port | awk '{print substr($1,0,11)}')- # 2 chars left
  local last=$(ip a | grep -o "$prefix[0-9]*" | grep -o '[0-9]*' | sort -n | \
    tail -1)
  if [ -z $last ]; then
    local last=-1
  fi
  local i=$((last+1))
  local dev=$prefix$i
  sudo ip link add name $dev type dummy
  sudo ip link set dev $dev up
  sudo ovs-vsctl add-port $br $dev
  sudo ovs-vsctl -- set Bridge $br mirrors=@m -- --id=@dev \
         get Port $dev  -- --id=@port get Port $port  \
         -- --id=@m create Mirror name=m-$dev select-dst-port=@port \
         select-src-port=@port output-port=@dev
  if ip a | grep -q "$dev:"; then
    echo "#Info: created mirror m-$dev at bridge '$br': '$port' => '$dev'"
  fi
}

# create snooper for the whole bridge
function ovs_snooper_create_for_br {
  if [ -z $(which ovs-vsctl) ]; then
    echo "#Error: please install open vswitch first."
    return
  fi
  local br=$1
  if [ -z $br ]; then
    echo "#Usage: ovs_snooper_create_for_br ovs-bridge"
    return
  fi
  if [ -z "$(sudo ovs-vsctl list bridge $br 2>/dev/null)" ]; then
    echo "#Error: ovs bridge '$br' not found"
    return
  fi

  local prefix=$(echo sa-$br | awk '{print substr($1,0,11)}')- # 2 chars left
  local last=$(ip a | grep -o "$prefix[0-9]*" | grep -o '[0-9]*' | sort -n | \
    tail -1)
  if [ -z $last ]; then
    local last=-1
  fi
  local i=$((last+1))
  local dev=$prefix$i
  sudo ip link add name $dev type dummy
  sudo ip link set dev $dev up
  sudo ovs-vsctl add-port $br $dev
  sudo ovs-vsctl -- set Bridge $br mirrors=@m -- --id=@dev \
       get Port $dev -- --id=@m create Mirror name=m-$dev select_all=true \
       output-port=@dev
  if ip a | grep -q "$dev:"; then
    echo "#Info: created mirror m-$dev for bridge '$br': '$dev'"
  fi
}

function ovs_snooper_clear_for_br {
  if [ -z $(which ovs-vsctl) ]; then
    echo "#Error: please install open vswitch first."
    return
  fi
  local br=$1
  if [ -z $br ]; then
    echo "#Usage: ovs_snooper_clear_for_br ovs-bridge"
    return
  fi
  if [ -z "$(sudo ovs-vsctl list bridge $br 2>/dev/null)" ]; then
    echo "#Error: ovs bridge '$br' not found"
    return
  fi
  sudo ovs-vsctl clear bridge $br mirrors
  for port in $(sudo ovs-vsctl list-ports $br | grep "^s[a]*-"); do
    sudo ovs-vsctl del-port $port
  done
}

