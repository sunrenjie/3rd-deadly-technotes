# A set of utility functions that together implement a simple-minded todo
# management system.

function __todo_new {
  local dir=TODO
  local suffix=bp
  echo "Please enter a short description line for the todo:
_______________________________________________________"
  read line
  echo
  local line=$(echo $line | sed -e 's:^ *::' -e 's: *$::')
  if echo $line | grep -q [A-Za-z0-9_,-]; then
    true # any valid content in the line? then ok.
  else
    echo "#Error: no valid content detected; nothing done."
    return
  fi
  local title=$(echo $line | sed -e 's:[^A-Za-z0-9 _,-]*::g' -e 's: :-:g')
  local date=$(date '+%Y-%m-%d-%H%M%S')
  local head="$date-$title"
  local prefix=$(echo $date | awk -F '-' '{print $1 $2}')
  local filename="$prefix/$head.$suffix"
  echo "#Info: output file name: '$filename' ."
  local within=$(pwd | awk -F '/' '{print $(NF)}')
  if echo "$within" | grep -q "^$dir"; then
    echo "#Info: in a $dir dir; the .$suffix file will be created..."
    mkdir -p $prefix
    echo -e "$line\n\nCONTENT STARTS ..." > $filename
    echo -e "STATUS: [$date] barely created." >> $filename
    echo "#Info: done."
  else
    echo "#Info: please cd to the $dir dir to create this TODO."
  fi
}

function __todo_list_all {
  local dir=TODO
  local suffix=bp
  local within=$(pwd | awk -F '/' '{print $(NF)}')
  local solved='SOLVED'
  local status='\(STATUS\|SOLVED\)'
  if echo "$within" | grep -q "^$dir"; then
    find . -type f -name "*.$suffix" | sed 's:^\.\/::' | sort -r | \
     while read f; do
      local name=$(echo $f | awk -F '/' '{print $(NF)}')
      local l=$(tail -1 $f)
      if echo "$l" | grep -q "$solved"; then
        echo "     S $f"
      else
        echo " [*] U $f"
      fi
      if echo "$l" | grep -q "$status"; then
        echo "      \-- $l"
      fi
    done
  else
    echo "#Info: not in $dir dir; nothing done."
  fi
}

function __todo_list_solved {
  local dir=TODO
  local suffix=bp
  local within=$(pwd | awk -F '/' '{print $(NF)}')
  local solved=SOLVED
  if echo "$within" | grep -q "^$dir"; then
    find . -type f -name "*.$suffix" | sed 's:^\.\/::' | sort -r | \
     while read f; do
      local name=$(echo $f | awk -F '/' '{print $(NF)}')
      local l=$(tail -1 $f)
      if echo "$l" | grep -q "$solved"; then
        echo "     S $f"
        echo "      \-- $l"
      fi
    done
  else
    echo "#Info: not in $dir dir; nothing done."
  fi
}

function __todo_list_unsolved {
  local dir=TODO
  local suffix=bp
  local within=$(pwd | awk -F '/' '{print $(NF)}')
  local solved=SOLVED
  local status=STATUS
  if echo "$within" | grep -q "^$dir"; then
    find . -type f -name "*.$suffix" | sed 's:^\.\/::' | sort -r | \
     while read f; do
      local name=$(echo $f | awk -F '/' '{print $(NF)}')
      local l=$(tail -1 $f)
      if echo "$l" | grep -q "$solved"; then
        true # does nothing
      else
        echo " [*] U $f"
      fi
      if echo "$l" | grep -q "$status"; then
        echo "      \-- $l"
      fi
    done
  else
    echo "#Info: not in $dir dir; nothing done."
  fi
}

function __todo_help1 {
  echo \
'This is a simple-minded TODO management system.
Type "todo help" for more.
'
}

function __todo_help2 {
  echo \
'This is a simple-minded TODO management system.
Command line options:
    todo [command]
where command can be any of:
    + list-all, la (default is not specified)
      List all TODOs, including both solved and unsolved, latest first.
    + list-solved, ls
      List all solved TODOs, latest first.
    + list-unsolved, lu
      List all unsolved TOODs, latest first.
    + new
      Launch wizzard that help create a new TODO.
    + help
      Display this help information.
'
}

function todo {
  if [ "$1" = "help" ]; then
    __todo_help2
    return
  fi
  __todo_help1 # default to all non-helping operations
  if [ -z "$1" ]; then
    __todo_list_all
  elif [ "$1" = "list-all" ] || [ "$1" = "la" ]; then
    __todo_list_all
  elif [ "$1" = "list-solved" ] || [ "$1" = "ls" ]; then
    __todo_list_solved
  elif [ "$1" = "list-unsolved" ] || [ "$1" = "lu" ]; then
    __todo_list_unsolved
  elif [ "$1" = "new" ]; then
    __todo_new
  fi
}

