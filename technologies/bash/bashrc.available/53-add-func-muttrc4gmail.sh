
function muttrc4gmail {
  if [ -z "$1" -o -z "$2" ]; then
    echo "#Usage: muttrc4gmail gmail-username gmail-password"
    return
  fi
  if echo $1 | grep '\@gmail.com$' >/dev/null; then
    local user=$(echo $1 | sed 's:\@gmail.com$::')
  else
    local user="$1"
  fi
  local pass=$2
  cat <<EOF
  set imap_user = "$user@gmail.com"
  set imap_pass = "$pass"

  set smtp_url = "smtp://$user@smtp.gmail.com:587/"
  set smtp_pass = "$pass"
  set from = "$user@gmail.com"
  set realname = "$user@gmail.com"

  set folder = "imaps://imap.gmail.com:993"
  set spoolfile = "+INBOX"
  set postponed="+[Gmail]/Drafts"

  set header_cache=~/.mutt/cache/headers
  set message_cachedir=~/.mutt/cache/bodies
  set certificate_file=~/.mutt/certificates

  set move = no

  set sort = 'threads'
  set sort_aux = 'last-date-received'
  set imap_check_subscribed

  ignore "Authentication-Results:"
  ignore "DomainKey-Signature:"
  ignore "DKIM-Signature:"
  hdr_order Date From To Cc

  # Automatically attempt to decrypt traditional PGP messages
  set pgp_auto_decode=yes
EOF
}

