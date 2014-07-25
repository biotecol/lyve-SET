#!/usr/bin/env perl
# Infer the index case of a cluster using Eigenvectors

use strict;
use warnings;
use Data::Dumper;
use Graph::Centrality::Pagerank;
use Getopt::Long;
use FindBin;
use lib "$FindBin::RealBin/lib";
use File::Basename qw/basename/;

sub logmsg {local $0=basename $0;my $FH = *STDOUT; print $FH "$0: ".(caller(1))[3].": @_\n";}
exit main();

sub main{
  my $settings={};
  GetOptions($settings,qw());

  my @pairwise=@ARGV;

  die "ERROR: need pairwise file\n".usage() if(!@pairwise);

  eigen(\@pairwise,$settings);
}

# TODO put this in a separate script
sub eigen{
  my($pairwise,$settings)=@_;
  my $ranker = Graph::Centrality::Pagerank->new(-useEdgeWeights=>1);

  # read the pairwise file to get "edges"
  my @listOfEdges=gatherEdges($pairwise,$settings);
  my $dump=$ranker->getPagerankOfNodes(listOfEdges=>\@listOfEdges,useEdgeWeights=>1);
  while(my($node,$eigen)=each(%$dump)){
    print join("\t",$node,$eigen)."\n";
  }

  return 1;
}
sub gatherEdges{
  my($pairwise,$settings)=@_;
  my @listOfEdges;
  my %seen;
  for my $p(@$pairwise){
    open(PW,$p) or die "ERROR: cannot open pairwise distances file $p $!";
    while(my $line=<PW>){
      chomp $line;
      my($from,$to,$weight)=split(/\t/,$line);
      # transform the weight
      $weight=1/$weight;
      push(@listOfEdges,[$from,$to,$weight]);
      push(@listOfEdges,[$to,$from,$weight]);

      # check for duplicates across files
      if(defined($seen{$from}{$to}) || defined($seen{$to}{$from})){
        logmsg "Warning: this edge has already been seen and will be overwritten: $from $to";
      }
      $seen{$from}{$to}++;
      $seen{$to}{$from}++;
    }
  }
  close PW;
  return @listOfEdges;
}

sub usage{
  local $0=basename $0;
  "Infers the index case of a cluster using Eigenvectors
  $0 pairwise.tsv [pairwise2.tsv ... ] > connectedness.tsv
    You can combine multiple pairwise files but a warning will be expressed if duplicate pairs are found.
  EXAMPLE
  $0 1.tsv 2.tsv | sort -k2,2nr | head -n 1 | cut -f 1 # the most connected node
  "
}
