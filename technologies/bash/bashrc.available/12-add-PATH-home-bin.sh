# This file collects ~/bin and all sub-directory that has a non-number
# character [^0-9] as ending of its name and contains a 'bin' dir,
# then merge them at the front of PATH. This way we encourage symlinks like
# 'software-1.2.3' => 'software', and effectively avoids redundancies.

if [ -d ~/bin ]; then
  # Pecularities:
  # 1. Pipes create sub-process; variable exporting there will not take effect
  #    in our environment.
  # 2. Don't collect path if it is already in PATH.
  export PATH=~/bin:$PATH
  LOCAL_PATH=$(ls -d ~/bin/*/bin 2>/dev/null | grep '[^0-9]\/bin$' | \
    while read l; do if ! echo $PATH | grep -q "$l"; then printf "$l:"; fi \
    done)
  if [ ! -z $LOCAL_PATH ]; then
    export PATH=$LOCAL_PATH:$PATH
  fi
  unset LOCAL_PATH
fi
