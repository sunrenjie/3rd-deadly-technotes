function l {
  if [ "$1" = "" ] ; then
    echo "Usage: l filename"
  else
    grep -Hnr '.*' $1 | less -S
  fi
}

function g {
  if [ "$1" = "" ] ; then
    echo "Usage: g string"
  else
    grep -Hnr "$1" * | grep -v ^Binary | grep -v MESSAGE | grep -v locale | grep -v tests | grep --color "$1"
  fi
}

