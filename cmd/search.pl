#!/usr/bin/perl
#
# search.pl — Search DXSpider debug logs with time filters and logical expressions
#
# Description:
#   This script allows you to search DXSpider debug files based on a time range
#   (epoch or human-readable) and logical string filters (AND, OR, quoted, nested).
#
#   It highlights matched terms with colours and handles flexible time parsing.
#
#   Supports:
#     - Logical filters: AND (&), OR (|), parentheses, quoted terms
#     - Time filtering: -s and -e with -l (epoch) or -h (human time)
#     - Color highlighting for matched terms
#
# Usage:
#   ./search.pl -f <file> -l|-h [-s <start>] [-e <end>] --filter <expression>
#
#   See help (-? or --help) for detailed options and examples.
#
# Location:
#   /spider/local_cmd/search.pl
#
# Make globally accessible:
#   To run this script from anywhere:
#     1. Make it executable: chmod +x /spider/local_cmd/search.pl
#     2. Create a symbolic link or copy it to a directory in your PATH, e.g.:
#        sudo ln -s /spider/local_cmd/search.pl /usr/local/bin/search
#     3. Then simply use: search -f <file> ...
#
# Requirements:
#   Perl core modules only (no external dependencies)
#
# Author : Kin EA3CV (ea3cv@cronux.net)
# Version: 20250406 v1.2
# Note   : For a good friend... but stubborn.
#

use strict;
use warnings;
use Getopt::Long;
use Time::Local;
use POSIX qw(strftime);
use Term::ANSIColor;

my @colors = ('blue', 'red', 'yellow', 'cyan', 'green');

my ($file, $epoch_mode, $human_mode, $start, $end, $help);
my $filter_expr;

GetOptions(
    'f=s'        => \$file,
    'l'          => \$epoch_mode,
    'h'          => \$human_mode,
    's=s'        => \$start,
    'e=s'        => \$end,
    'filter=s'   => \$filter_expr,
    'help|?'     => \$help,
) or die "Error in arguments. Use --help for usage info.\n";

if ($help) {
    print_help();
    exit 0;
}

unless ($file) {
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
    my $day_of_year = strftime("%j", localtime);
    $year = $year + 1900;
    $file = "/spider/local_data/debug/$year/$day_of_year.dat";
#    $file = "/root/volumenes/dxspider/nodo-3/local_data/debug/$year/$day_of_year.dat"; # Docker
    print STDERR " -f was not specified. The file will be used automatically.: $file\n";
}

my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
$year += 1900;
$mon  += 1;

sub parse_time {
    my $t = shift;
    if ($t =~ /^(\d{8})-(\d{6})$/) {
        my ($date, $time) = ($1, $2);
        return timelocal(substr($time,4,2), substr($time,2,2), substr($time,0,2),
                         substr($date,6,2), substr($date,4,2)-1, substr($date,0,4)-1900);
    } elsif ($t =~ /^(\d{6})$/) {
        return timelocal(substr($t,4,2), substr($t,2,2), substr($t,0,2),
                         $mday, $mon-1, $year-1900);
    } elsif ($t =~ /^\d+$/) {
        return $t;
    } else {
        die "Invalid time format: $t\n";
    }
}

my $start_epoch;
if (defined $start) {
    $start_epoch = parse_time($start);
} elsif (defined $end) {
    $start_epoch = 0;
} elsif ($epoch_mode || $human_mode) {
    $start_epoch = timelocal(0,0,0,$mday,$mon-1,$year-1900);
} else {
    $start_epoch = 0;
}

my $end_epoch = defined($end) ? parse_time($end) : time();

if ($filter_expr && $filter_expr =~ /"[^"]*[\|\&][^"]*"/) {
    print STDERR "\n⚠️  Warning: You used '|' or '&' inside double quotes in the filter:\n";
    print STDERR "    '$filter_expr'\n";
    print STDERR "    This will be treated as a literal string, NOT a logical condition.\n";
    my $suggested = $filter_expr =~ s/"//gr;
    print STDERR "    Did you mean: $suggested ? [Y/n]: ";
    my $answer = <STDIN>;
    chomp $answer;
    if (lc($answer) eq 'y' || $answer eq '') {
        $filter_expr = $suggested;
        print STDERR "✅ Filter automatically corrected to: $filter_expr\n";
    } else {
        print STDERR "🔸 Using original filter as-is.\n";
    }
}

sub expr_to_perl {
    my $expr = shift;
    my @tokens;
    my $buffer = '';
    my $in_quotes = 0;

    for (my $i = 0; $i < length($expr); $i++) {
        my $c = substr($expr, $i, 1);
        if ($c eq '"') {
            $in_quotes = !$in_quotes;
            next;
        }
        if ($in_quotes) {
            $buffer .= $c;
        } else {
            if ($c =~ /\s/) {
                next;
            } elsif ($c eq '&' || $c eq '|') {
                push @tokens, $buffer if $buffer ne '';
                push @tokens, $c;
                $buffer = '';
            } elsif ($c eq '(' || $c eq ')') {
                push @tokens, $buffer if $buffer ne '';
                push @tokens, $c;
                $buffer = '';
            } else {
                $buffer .= $c;
            }
        }
    }
    push @tokens, $buffer if $buffer ne '';

    my @perl_expr;
    foreach my $t (@tokens) {
        if ($t eq '&') {
            push @perl_expr, '&&';
        } elsif ($t eq '|') {
            push @perl_expr, '||';
        } elsif ($t eq '(' or $t eq ')') {
            push @perl_expr, $t;
        } else {
            $t =~ s/"/\\"/g;
            push @perl_expr, "index(\$line, \"$t\") >= 0";
        }
    }
    return join(' ', @perl_expr);
}

my $compiled_expr = $filter_expr ? expr_to_perl($filter_expr) : "1";

my @raw_terms;
if ($filter_expr) {
    my @quoted_terms;
    while ($filter_expr =~ /"([^"]+)"/g) {
        push @quoted_terms, $1;
    }

    my $unquoted = $filter_expr;
    $unquoted =~ s/"[^"]+"//g;
    $unquoted =~ s/[()&|]/ /g;
    my @other_terms = grep { $_ ne '' } split /\s+/, $unquoted;

    my %seen;
    @raw_terms = grep { !$seen{$_}++ } (@quoted_terms, @other_terms);
}

# DEBUG
#print "DEBUG: matched terms => @raw_terms\n";
#print "DEBUG: compiled expr => $compiled_expr\n";

open my $fh, '<', $file or die "Cannot open file $file: $!\n";

while (my $line = <$fh>) {
    chomp $line;
    if ($line =~ /^(\d+)\^\(/) {
        my $timestamp = $1;
        # Convertir epoch a formato legible
#        my $formatted_time = strftime("%Y%m%d-%H%M%S", localtime($timestamp));
        my $formatted_time = strftime("%H:%M:%S", localtime($timestamp));
#        $line =~ s/^\d+\^/\Q$formatted_time\E^/;
        $line =~ s/^\d+\^/$formatted_time^/;

        if ($timestamp >= $start_epoch && $timestamp <= $end_epoch) {
            my $eval_result = eval $compiled_expr;
            if ($@) {
                warn "Eval error: $@\n";
                next;
            }

            if ($eval_result) {
                my $colored_line = $line;
                my $color_index = 0;

                foreach my $term (@raw_terms) {
                    my $color = $colors[$color_index++ % @colors];
                    my $quoted = quotemeta($term);
                    $colored_line =~ s/($quoted)/colored($1, $color)/ge;
                }

                print "$colored_line\n";
            }
        }
    }
}
close $fh;

sub print_help {
    print <<'USO';

Usage:
./search -f <file> -l|-h [-s <start>] [-e <end>] --filter <expression>

Parameters:
-f <file>          File to analyse (format: <day_number>.dat) (optional)
-l                 Use epoch time format (e.g. 1743034000)
-h                 Use human-readable time (YYYYMMDD-HHMMSS or HHMMSS)
-s <start>         Start time (optional)
-e <end>           End time (optional)
--filter <expr>    Logical expression to filter lines (see examples)
--help, -? S       How this help message

Valid expressions:
string                      Line containing "string"
string1|string2             Line containing either "string1" or "string2"
string1&string2             Line containing both "string1" and "string2"
(string1|string2)&string3   Grouping with parentheses
"exact phrase"              For exact matches or strings with spaces/special characters

# Epoch timestamp
./search -f 086.dat -l -s 1743034000 -e 1743034600 --filter='EA4VV'
./search -f 086.dat -h -s 20250327-123000 --filter='EA4VV'
./search -f 086.dat -h -s 123000 -e 125900 --filter='EA4VV'
./search -f 086.dat --filter='EA4VV'
./search --filter='EA3CV-2'

# Multiple OR conditions
./search -f 086.dat -l --filter='PC61|PC11|PC12'

# Multiple AND conditions
./search -f 086.dat -l -s 1743034000 -e 1743034600 --filter='PC61^14291&EA4VV'
./search -f 086.dat -l -s 1743034000 -e 1743034600 --filter='(PC61^14291)&EA4VV'
./search -f 086.dat -l -s 1743034000 -e 1743034600 --filter='"PC61^14291"&EA4VV'

# Combining AND + OR
./search -f 086.dat --filter='(PC61|PC11)&EA4VV'

# Literal text in quotes
./search -f 086.dat --filter='"EA4VV^EA4RCH-5"&PC61'

# Human time format: time only
./search -f 086.dat -h -s 123000 -e 125900 --filter='EA4VV'

# Complex expression with AND + OR + quoted string
./search -f 086.dat -l -e 1743034600 --filter='"PC92^EA3CV-2"&(^C^|^K^)&^H28'

USO
}
