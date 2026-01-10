#!/usr/bin/perl

#
# List of PC92 A/D packets by node pairs
#
# Usage: conndisc_all.pl                            # For the current day
#        conndisc_all.pl AAAA-MM-DD <epoch_time>    # From epoch time 
#
# chmod +x conndisc_all.pl
#
# Kin EA3CV
#
# 20250115 v0.1
#

use strict;
use warnings;
use feature 'say';
use Time::Piece;

my $day_to_analyze = $ARGV[0] // localtime->ymd;
my $epoch_threshold = $ARGV[1] // 0;

my $time = eval { Time::Piece->strptime($day_to_analyze, "%Y-%m-%d") }
    or die "Invalid date format. Use YYYY-MM-DD.\n";

my $year = localtime->year;
my $day_of_year = $time->yday + 1;
my $input_file = sprintf("/spider/local_data/debug/%d/%03d.dat", $year, $day_of_year);
#my $input_file = sprintf("/root/volumenes/dxspider/nodo-3/local_data/debug/%d/%03d.dat", $year, $day_of_year);

my %data;

my $start_epoch = $time->epoch;
my $end_epoch = $start_epoch + 86399;

open my $fh, '<', $input_file or die "Unable to open file $input_file: $!";
while (<$fh>) {
    chomp;

    my @fields = split /\^/;

    next unless $fields[0] >= $epoch_threshold && $fields[0] >= $start_epoch && $fields[0] <= $end_epoch;

    next unless $fields[1] =~ /PC92$/;
    next unless $fields[4] eq 'A' || $fields[4] eq 'D';

    my $hop_field = $fields[6];
    next unless $hop_field =~ /^[4-7]/;
    $hop_field =~ s/:.*$//;

    $hop_field =~ s/^[4-7]//;

    my $unique_key = join('|', @fields[2, 3, 4], $hop_field);

    $data{$unique_key} = [@fields[2, 4], $hop_field] unless exists $data{$unique_key};
}
close $fh;

# Contar los totales por Pairs, A, D y A/D
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
        my ($node1, $node2) = split / /, $pair;
        my $a_count = $totals_ref->{$pair}{'A'} // 0;
        my $d_count = $totals_ref->{$pair}{'D'} // 0;
        my $ad_count = $a_count + $d_count;

        $total_a += $a_count;
        $total_d += $d_count;
        $total_ad += $ad_count;

        say sprintf("%-10s %-10s %-6d %-6d %-6d", $node1, $node2, $a_count, $d_count, $ad_count);
    }

    say "-" x 40;
    say sprintf("%-10s %-10s %-6d %-6d %-6d", "Total", "", $total_a, $total_d, $total_ad);
}

say sprintf("%-10s %-10s %-6s %-6s %-6s", "Node-1", "Node-2", "Conn", "Disc", "ALL");
say "-" x 40;

print_totals(\%totals);

say "-" x 40;

# Mostrar solo las parejas con A/D > 24
say "Resumen de Pairs con A/D > 24:";
say sprintf("%-10s %-10s %-6s %-6s %-6s", "Node-1", "Node-2", "Conn", "Disc", "ALL");
say "-" x 40;

# Filtrar y mostrar solo las parejas con A/D > 24
my %totals_filtered;
foreach my $pair (sort keys %totals) {
    my $a_count = $totals{$pair}{'A'} // 0;
    my $d_count = $totals{$pair}{'D'} // 0;
    my $ad_count = $a_count + $d_count;

    if ($ad_count > 24) {
        $totals_filtered{$pair} = $totals{$pair};
    }
}

print_totals(\%totals_filtered);
