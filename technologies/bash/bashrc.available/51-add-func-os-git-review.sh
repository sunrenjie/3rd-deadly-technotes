# Please set environment variable OS_GIT_REVIEW_OUTDIR to the directory to
# which the output file is to be written.
function git_review {
  if [ "$1" = "" ]; then
    echo "Usage: (at git working dir) os-git-review commit-hash"
  else
    git log $1 -1 -p --stat=1000 | perl -we '
use strict;
use warnings;

my $destdir = $ENV{"OS_GIT_REVIEW_OUTDIR"};
$destdir ||= "/tmp";

sub get_title {
  my $l = $_[0];
  chomp($l);
  $l =~ s/^ *//;
  my @m = split(//, $l);
  my @n;
  map { $_ = "-" if $_ eq " ";
        push @n, $_ if (/[,\w\-]/);
  } @m;
  return join("", @n);
}

# input: "Date:   Tue Apr 1 15:06:36 2014 -0700"
# output: 20140401
sub get_date {
  my %mon = (
  "jan" => 1,
  "feb" => 2,
  "mar" => 3,
  "apr" => 4,
  "may" => 5,
  "jun" => 6,
  "jul" => 7,
  "aug" => 8,
  "sep" => 9,
  "oct" => 10,
  "nov" => 11,
  "dec" => 12,
  );
  my $l = $_[0];
  chomp($l);
  my @d = split(/\s+/, $l);
  my $year = $d[5];
  my $month = $mon{lc($d[2])};
  my $day =  $d[3];
  ($d[0] eq "Date:" && $year && $month && $day) or return undef;
  return sprintf("%04d%02d%02d", $year, $month, $day);
}

sub get_commit_hash {
  my $l = $_[0];
  chomp($l);
  my @d = split(/\s+/, $l);
  return $d[1];
}

my $c = 0;
my $id;
my $title;
my $date;
my @lines;
my $commit;
while (<STDIN>) {
  $c++;
  chomp;
  push @lines, $_;
  $commit = get_commit_hash($_) if ($c == 1);
  $date = get_date($_) if ($c == 3);
  $title = get_title($_) if ($c == 5);
  if (/Change\-Id\: ([A-Za-z0-9]{9}).*/) {
    $id = $1;
  }
}
$id = substr($commit, 0, 6) unless defined $id;

if (defined($title) && defined($id) && defined($date)) {
  my $f = "/tmp/${date}-${id}-${title}";
  open(OUT, ">$f") or die $!;
  print OUT join("\n", @lines), "\n";
  close OUT;
  print STDERR "#Info: Finished write to $f\n";
  print "#Info: you may wish to copy it via:\n";
  print "cp -v $f $destdir/\n";
} else {
  print "#Warning: no meaningful content found.\n";
}
'
  fi
}

