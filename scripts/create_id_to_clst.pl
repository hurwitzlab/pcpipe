#!/usr/bin/env perl

=head1 NAME

   create_id_to_clst.pl 

=head1 SYNOPSIS

  create_id_to_clst.pl cdhit-cluster-file 

Options:
 
   none.

=head1 DESCRIPTION

   creates a list of ids to clusters 
 
=head1 SEE ALSO

perl.

=head1 AUTHOR

Bonnie Hurwitz E<lt>bhurwitz@email.arizona.eduE<gt>,

=head1 COPYRIGHT

Copyright (c) 2011 Bonnie Hurwitz 

This library is free software;  you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use autodie;

my $in  = shift or die "No input.\n";
my $out = shift or die "No output.\n";

open my $IN,  '<', $in;
open my $OUT, '>', $out;

my $curr_clstr;
my %cluster_to_count;
my $first = 0;
while (<$IN>) {
    chomp $_;
    if ( $_ =~ /^>/ ) {
        my $clust = $_;
        $clust =~ s/>//;
        $first++;
        if ( $first > 1 ) {
            $curr_clstr = $clust;
        }
        else {
            $curr_clstr = $clust;
        }
    }
    else {
        push( @{ $cluster_to_count{$curr_clstr} }, $_ );
    }
}

for my $c ( 
    sort { $cluster_to_count{$b} <=> $cluster_to_count{$a} }
    keys %cluster_to_count 
) {
    my $size = @{ $cluster_to_count{$c} };
    for my $cl ( @{ $cluster_to_count{$c} } ) {
        $cl =~ s/.*>//;
        $cl =~ s/\..*//;
        $c  =~ s/\s+/_/;
        print $OUT "$c\t$cl\n";
    }
}
