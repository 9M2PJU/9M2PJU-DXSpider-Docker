#
# Displays the PC92 A and D of the current day with the callsign of our node.
# Reports connections/disconnections or attempted connections to or from nodes.
#
# Usage: sh/conndisc
#
# Requirements:
#    Have debug chan and nologchan:
#    set/debug chan
#    unset/debug nologchan
#
# Installation:
#    Create if no show directory exists in local_cmd from Linux
#    mkdir /spider/local_cmd/show
#    Copy the file conndisc.pl to /spider/local_cmd/show
#
# Kin EA3CV, ea3cv@cronux.net
#
# 20250116 v0.1
#

use strict;
use warnings;
use feature 'say';
use POSIX qw(strftime);

DXCommandmode::clear_cmd_cache();

my $self = shift;

return 1 unless $self->{priv} >= 9;

chdir "$main::root";

my @out;
my $field_2_filter = $main::mycall;

my $year = strftime('%Y', localtime);
my $day_of_year = strftime('%j', localtime);
my $input_file = "local_data/debug/$year/$day_of_year.dat";

my %data;

open my $fh, '<', $input_file or die push(@out, "No se puede abrir el archivo $input_file: $!") && return (0, @out);
while (<$fh>) {
    chomp;

    my @fields = split /\^/;

    next unless $fields[1] =~ /PC92$/;
    next unless $fields[4] eq 'A' || $fields[4] eq 'D';

    next if defined $field_2_filter && $fields[2] ne $field_2_filter;

    my $hop_field = $fields[6];
    next unless $hop_field =~ /^[4-7]/; # Solo si comienza por 4, 5, 6, o 7
    $hop_field =~ s/:.*$//; # Eliminar desde ":" hasta el final si contiene ":"

    $hop_field =~ s/^[4-7]//;

    my $unique_key = join('|', @fields[2, 3, 4], $hop_field);

    $data{$unique_key} = [@fields[2, 4], $hop_field] unless exists $data{$unique_key};
}
close $fh;

my %totals;
foreach my $key (values %data) {
    my ($pair, $type, $hop) = @$key;
    $totals{"$pair $hop"}{$type}++;
}

sub print_totals {
    my ($totals_ref) = @_;
    my $total_a = 0;
    my $total_d = 0;
    my $total_ad = 0;

    foreach my $pair (sort keys %$totals_ref) {
        my ($node1, $node2) = split / /, $pair;  # Separar la "pair" en los dos nodos
        my $a_count = $totals_ref->{$pair}{'A'} // 0;
        my $d_count = $totals_ref->{$pair}{'D'} // 0;
        my $ad_count = $a_count + $d_count;

        $total_a += $a_count;
        $total_d += $d_count;
        $total_ad += $ad_count;

        push @out, sprintf("%-10s %-10s %-6d %-6d %-6d", $node1, $node2, $a_count, $d_count, $ad_count);
    }

    push @out, "-" x 40;
    push @out, sprintf("%-10s %-10s %-6d %-6d %-6d", "Total", "", $total_a, $total_d, $total_ad);
}

push @out, sprintf("%-10s %-10s %-6s %-6s %-6s", "Node-1", "Node-2", "Conn", "Disc", "ALL");
push @out, "-" x 40;

print_totals(\%totals);

return (1, @out);
