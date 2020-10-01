# let ssh/scp be faster in sacrifice of minor security and features.
ssh_options='-o StrictHostKeyChecking=no -o GSSAPIAuthentication=no'
ssh_options+=' -o UserKnownHostsFile=/dev/null'
alias ssh="env ssh $ssh_options"
alias scp="env scp $ssh_options"
unset ssh_options

alias grep='grep --color' # both bsd and gnu grep accepts '--color'

# arch-specific part
if uname -a | grep -q Darwin; then # macosx

alias ll='/bin/ls -Gl'
alias lh='/bin/ls -Glh'
alias la='/bin/ls -Glah'

alias top='/usr/bin/top -u'

# gedit mac port
if [ -d /Applications/gedit.app ]; then
  alias gedit='open -a /Applications/gedit.app'
fi

elif uname -a | grep -q Linux; then # linux

alias ll='/bin/ls -l --color'
alias lh='/bin/ls -lh --color'
alias la='/bin/ls -la --color'

if echo $XDG_MENU_PREFIX | grep -q gnome; then
  alias open='nautilus'
elif [ "_$XDG_SESSION_DESKTOP" = "_mate" ]; then
  alias open='caja'
fi

alias virsh='sudo virsh'

fi

alias git_checkout_all='git status | awk '"'"'$1=="modified:"{print $2}'"'"' | xargs echo git checkout --'

timer() {
  if [ "_$1" == "_" ]; then
    echo shall supply the seconds to wait.
    return
  fi
  m=$(( $1 / 60))
  s=$(( $1 - 60 * m))
  echo "$(date '+%Y-%m-%d %a %H%M %Ss'): will wait up to $m minutes, $s seconds ..."
  for ((i=$1; i>=1; i--)); do
    m=$(( i / 60))
    s=$((i - 60 * m))
    echo -ne "$(date '+%Y-%m-%d %a %H%M %Ss'): remaining $m minutes, $s seconds ...\033[0K\r"
    sleep 1
  done
  echo "$(date '+%Y-%m-%d %a %H%M %Ss'): done."
}

