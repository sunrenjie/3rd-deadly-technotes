# A naive dumper of linux system networking configurations.

function dump_helper {
  cmd=$*
  echo "================================================================="
  echo "# Output of command '$cmd':"
  sudo $cmd
}

function dump_ns {
  if [ -z $1 ]; then
    ns="(default)"
    ns_prefix=""
  else
    ns=$1
    ns_prefix="ip netns exec $1"
  fi
  echo _____________________________________________________________________
  echo Dumping info for namespace $ns
  echo
  for subcmd in route a; do
    dump_helper $ns_prefix "ip $subcmd"
  done
  for table in filter nat mangle raw security; do
    dump_helper $ns_prefix "iptables -t $table -S"
  done
}

function dump_network {
  dump_ns
  for ns in $(sudo ip netns list); do
    dump_ns $ns
  done
  vsctl=$(which ovs-vsctl 2>/dev/null)
  ofctl=$(which ovs-ofctl 2>/dev/null)
  if [ ! -z $vsctl -a ! -z $ofctl ]; then
    dump_helper $vsctl show
    for br in $(sudo $vsctl list-br); do
      dump_helper $ofctl show $br
      dump_helper $ofctl dump-flows $br
    done
  fi
}

