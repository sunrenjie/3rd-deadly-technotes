function screenit {
  local SCREEN=$(which screen)
  if [ -z $SCREEN ]; then
    echo "#Info: please install gnu screen first."
  fi
  local rc="$1"
  if [ -z "$rc" ]; then
    echo "#Usage: screenit screenrc-file."
    return
  elif [ ! -e "$rc" ]; then
    echo "#Error: file '$rc' not found."
    return
  fi
  local name=$(awk '$1=="sessionname"{print $2}' "$rc")
  if [ -z "$name" ]; then
    echo "#Error: screen name not defined in screenrc file '$rc'."
    return
  fi
  local session=$(screen -ls | grep '(Detached)' | awk '{print $1}' | \
    grep "[0-9].$name$" | head -1)
  if [ ! -z $session ]; then
    echo "#Info: Attaching to existing session '$session' for '$name' ..."
    screen -r "$session"
  else
    screen -c "$rc"
  fi
}

function unscreenit {
  local SCREEN=$(which screen)
  if [ -z $SCREEN ]; then
    echo "#Info: please install gnu screen first."
  fi
  if [ -z $1 ]; then
    echo "#Usage:"
    echo "  unscreenit screenrc-file"
    echo "Or:"
    echo "  unscreenit -n screen-name"
    return
  fi
  local name=
  if [ "_$1" = "_-n" ]; then
    local name=$2
  elif [ -e "$1" ]; then
    local name=$(cat "$1" | awk '$1=="sessionname"{print $2}')
  fi
  if [ -z $name ]; then
    echo "#Error: screen name not specified."
    return
  fi

  for session in $(screen -ls | awk '{print $1}' | grep "[0-9].$name$"); do
    screen -X -S $session quit
  done
}

