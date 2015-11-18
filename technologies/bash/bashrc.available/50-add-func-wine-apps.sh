# wine apps
function ahd4 {
  echo Running wine app ahd4 ... 
  sh -c 'cd ~/.wine/drive_c/AHD4 && wine AHD4.exe &' 1>/dev/null 2>/dev/null
}
function oed {
  echo Running wine app oed ...
  sh -c 'cd ~/.wine/drive_c/Program\ Files/OED && wine OED.EXE &' \
    1>/dev/null 2>/dev/null
}
function oald8 {
  echo Running wine app oald8 ...
  sh -c 'cd ~/.wine/drive_c/OALD8 && wine oald8.exe &' 1>/dev/null 2>/dev/null
}
function mw {
  echo Running wine app mw ...
  sh -c 'cd ~/.wine/drive_c/merriam-webster && wine merriam-webster.exe &' \
    1>/dev/null 2>/dev/null
}

function winword {
  echo Running wine app winword ...
  sh -c "wine 'C:\Program Files\Microsoft Office\Office\winword.exe' &" \
    1>/dev/null 2>/dev/null
}

function excel {
  echo Running wine app excel ...
  sh -c "wine 'C:\Program Files\Microsoft Office\Office\excel.exe' &" \
    1>/dev/null 2>/dev/null
}

function powerpnt {
  echo Running wine app powerpnt ...
  sh -c "wine 'C:\Program Files\Microsoft Office\Office\powerpnt.exe' &" \
    1>/dev/null 2>/dev/null
}
