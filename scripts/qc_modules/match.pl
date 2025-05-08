#!/usr/bin/perl -w

########################################################################################################
# match.pl-- Matches file one and file two on a specific key and then outputs a list of values from    #
#            file one to file two                                                                      #
#                                                                                                      #
# Usage: match.pl -f file1 -g filetwo -k 1 -l 2 -v 3 4 7                                               #
#                                                                                                      #
# Options:                                                                                             #
#                                                                                                      #
#         -f Name of file one                                                                          #
#         -g Name of file two                                                                          #
#         -h help                                                                                      #
#         -k position of key in file one                                                               #
#         -l position of key in file two                                                               #
#         -v position of values in file one to be appended to file two                                 #
#                                                                                                      #
########################################################################################################

use Getopt::Std;

getopts('f:g:hk:l:v:');

if ($opt_h) {
  print " match.pl-- Matches file one and file two on a specific key and then outputs a list of values from\n";
  print "            file one to file two\n\n";
  print " Usage: match.pl -f file1 -g filetwo -k 1 -l 2 -v 3 4 7\n\n";
  print " Options:\n\n";
  print "         -f Name of file one\n";
  print "         -g Name of file two\n";
  print "         -h help\n";
  print "         -k position of key in file one\n";
  print "         -l position of key in file two\n";
  print "         -v position of values in file one to be appended to file two\n\n";
  exit;
  $opt_h = 0;
}

if (!$opt_f) {
  die "Must specify file one using -f switch\n";
}

if (!$opt_g) {
  die "Must specify file one using -g switch\n";
}

open(FILE1, "$opt_f")|| die "Can't find file one $opt_f...exiting now...\n";
open(FILE2, "$opt_g")|| die "Can't find file two $opt_g...exiting now...\n";

if (!$opt_k) {
  die "Must specify position of key in file one using -k switch\n";
}

if (!$opt_l) {
  die "Must specify position of key in file two using -l switch\n";
}

if (!$opt_v) {
  die "Must specify position of values in file one to be appended using -v switch\n";
}

if ($opt_v) {
  @fields = split / /,$opt_v;
}

$col = $opt_l-1;
$ncol = @fields;

#Read in file 1
while(<FILE1>) {
  @temp = split;
  @values = ();
  foreach $i (@fields) {
    push @values, $temp[$i-1];
  }
  $key{$temp[$opt_k-1]} = [@values];
}

#Read in file 2
while(<FILE2>) {
  chomp;
  print $_,"\t";
  @temp = split;
  for($i=0;$i < $ncol;$i++) {
    if(!defined($key{$temp[$col]}[$i])) {
      print "-\t";
    } else {
      print "$key{$temp[$col]}[$i]\t";
    }
  }
  print "\n";
}

close FILE1;
close FILE2;
