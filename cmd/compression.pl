#!/usr/bin/perl

#
# Compression of the previous day's debug files
#
# To be copied to /spider/local_cmd
# This can be included in DXSpider's crontab as something like this:
# 10 0 * * * spawn("/spider/local_cmd/compression.pl")
#
# Kin EA3CV <ea3cv@cronux.net>
#
# 20260105 v0.4
#

use strict;
use warnings;
use POSIX qw(strftime);
use Time::Piece;

$ENV{TZ} = "UTC";

my $today = strftime("%Y-%j", gmtime);       # e.g. "2026-005"
my ($current_year, $current_day) = split('-', $today);

my ($y, $d);

if ($current_day == 1) {
    $y = $current_year - 1;

    # 365 or 366 depending on leap year (of previous year)
    $d = 365;
    $d = 366 if Time::Piece->strptime("$y-12-31", "%Y-%m-%d")->is_leap_year;
} else {
    $y = $current_year;
    $d = $current_day - 1;
}

# Always enforce 3-digit day-of-year formatting
$d = sprintf("%03d", $d);

my $file = "/spider/local_data/debug/$y/$d.dat";

if (-e $file) {
    my @compress = ('gzip', '-9', $file);
    system(@compress);

    if ($? == -1) {
        warn "Failed to execute gzip: $!";
    } elsif ($? & 127) {
        warn sprintf "gzip died with signal %d%s\n", ($? & 127), (($? & 128) ? ' (core dumped)' : '');
    } else {
        my $exit = $? >> 8;
        warn "gzip exited with status $exit\n" if $exit != 0;
    }
} else {
    warn "File $file does not exist.\n";
}
