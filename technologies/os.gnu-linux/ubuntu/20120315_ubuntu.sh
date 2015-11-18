
# various scripts written while using ubuntu
# 20120315

# given a package name, display packages that it depends.
# This program is deprecated because we found that a tool apt-rdepends already
# exists.

dpkg-dep(){
if [ "$1" == "" ]; then
  echo "#Usage: dpkg_dep pkg-name";
  return;
fi
dpkg -p $1 | perl -we '
use strict;
use warnings;
while (<STDIN>){
  chomp;
  /^Depends:/ or next;
  s/, / /g;
  s/\([^\)]*\)//g;
  my @z = split(/\s+/, $_);
  $z[0] eq "Depends:" or next;
  print join("\t", @z[1..$#z]), "\n";
}
'
}

