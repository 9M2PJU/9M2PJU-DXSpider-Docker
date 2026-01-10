#!/usr/bin/perl
#
# Script for real-time debug analysis and save a count file.
#
# Description:
# This script monitors a log file in real-time using the `tail -f` command.
# Entries matching specific patterns are counted and stored in an output file
# (`recuento.txt`), which is updated every few seconds (by default, every 10 seconds).
# The patterns it searches for include logs related to "DXDupe", "Bad Node", "PC92", among others.
#
# The output file contains a summary of the counts for each search pattern in the order
# specified in the script. Labels and their values are aligned to the left (labels)
# and to the right (numeric values).
#
# Usage:
#   perl counter.pl <input_file_name>
#   ./counter.pl <input_file_name>
#
# Parameters:
#   - <input_file_name>: The log file to monitor. Example: "086.dat".
#
# Functionality:
# 1. Monitors the input file in real-time using `tail -f`.
# 2. For each line read, it searches for matches with the regular expressions defined in the script.
# 3. It increments the corresponding counters based on the found patterns.
# 4. It saves the updated count in the output file (`count.txt`) every 10 seconds.
# 5. The output file contains the results organized by specific labels in a format
#    aligned to the right.
#
# Example usage:
#   $ perl counter.pl 086.dat
#   This will generate an `count.txt` file with the updated count every 10 seconds.
#
# To view the counters in real time:
#   watch -n 1 cat count.txt
#
# Kin EA3CV ea3cv@cronux.net
# 20250328 v0.0
#
# Requirements:
#  chmod +x counter.pl
#  Perl 5.x or higher
#  Access to the `tail -f` command to monitor logs in real-time.
#

use strict;
use warnings;
use Time::HiRes qw(sleep);

my %counts = (
    "DXDupe::add"      => 0,
    "DXDupe::del"      => 0,
    "DXDupe::clean"    => 0,
    "Bad Spot"         => 0,
    "Bad Node"         => 0,
    "Badwords"         => 0,
    "Normalised call"  => 0,
    "RFC1918-dropped"  => 0,
    "RBN: ERROR inv"   => 0,
    "RBN: ERROR"       => 0,
    "PC11 in"          => 0,
    "PC11 out"         => 0,
    "PC61 in"          => 0,
    "PC61 out"         => 0,
    # Eliminamos las viejas PC92 in y PC92 out
    "PC92 A in"        => 0,
    "PC92 A out"       => 0,
    "PC92 D in"        => 0,
    "PC92 D out"       => 0,
    "PC92 C in"        => 0,
    "PC92 C out"       => 0,
);

my %patterns = (
    "DXDupe::add"      => qr/DXDupe::add/,
    "DXDupe::del"      => qr/DXDupe::del/,
    "DXDupe::clean"    => qr/DXDupe::clean/,
    "RBN: ERROR inv"   => qr/RBN:\sERROR\sinvalid/,  # Busca "RBN: RBN: ERROR invalid"
    "RBN: ERROR"       => qr/RBN:\sERROR(?!\sinvalid)/,  # Busca "RBN: ERROR" sin "invalid"
    "Bad Spot"         => qr/Bad\sSpot/,
    "Bad Node"         => qr/Bad\sNode/,
    "Badwords"         => qr/Badwords/,
    "Normalised call"  => qr/DXProt::_add_thingy\s+normalised\s+call/,
    "RFC1918-dropped"  => qr/PCPROT:\s+PC61\s+dropped/,
    "PC11 in"          => qr/I\s+.*\s+PC11/,
    "PC11 out"         => qr/D\s+.*\s+PC11/,
    "PC61 in"          => qr/I\s+.*\s+PC61/,
    "PC61 out"         => qr/D\s+.*\s+PC61/,
    "PC92 A in"        => qr/I\s+.*\s+PC92.*\^A\^/,  # Busca "^A^"
    "PC92 A out"       => qr/D\s+.*\s+PC92.*\^A\^/,  # Busca "^A^"
    "PC92 D in"        => qr/I\s+.*\s+PC92.*\^D\^/,  # Busca "^D^"
    "PC92 D out"       => qr/D\s+.*\s+PC92.*\^D\^/,  # Busca "^D^"
    "PC92 C in"        => qr/I\s+.*\s+PC92.*\^C\^/,  # Busca "^C^"
    "PC92 C out"       => qr/D\s+.*\s+PC92.*\^C\^/,  # Busca "^C^"
);

my $input_file = $ARGV[0] or die "Please input file.\n";
my $output_file = "count.txt";

my @order = (
    "DXDupe::add",
    "DXDupe::del",
    "DXDupe::clean",
    "Bad Spot",
    "Bad Node",
    "Badwords",
    "Normalised call",
    "RFC1918-dropped",
    "RBN: ERROR inv",
    "RBN: ERROR",
    "PC11 in",
    "PC11 out",
    "PC61 in",
    "PC61 out",
    "PC92 A in",
    "PC92 A out",
    "PC92 D in",
    "PC92 D out",
    "PC92 C in",
    "PC92 C out",
);

open my $fh, '-|', "tail -f $input_file" or die "Unable to open the file '$input_file': $!\n";

sub save_counts {
    open my $out, '>', $output_file or die "Unable to open '$output_file': $!\n";
    print $out "Updated count:\n";
    print $out "---------------  -------\n";

    foreach my $key (@order) {
        printf $out "%-20s %3d\n", $key, $counts{$key};
    }

    print $out "\n";
    close $out;
}

while (my $line = <$fh>) {
    chomp $line;

    foreach my $key (keys %patterns) {
        if ($line =~ $patterns{$key}) {
            $counts{$key}++;
        }
    }

    my $current_time = time;
    if ($current_time % 10 == 0) {
        save_counts();
    }

    sleep(0.001);
}
