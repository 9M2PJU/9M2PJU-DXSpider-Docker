#!/usr/bin/perl
#
# Test script for DXSpider Notification System
#
# Usage:
#   perl notifications/test_notify.pl
#
# This script tests the notification system without requiring
# a running DXSpider instance.
#

use strict;
use warnings;
use lib 'notifications/lib';
use Data::Dumper;

# Mock DXDebug if not available
BEGIN {
    unless (eval { require DXDebug; 1 }) {
        package DXDebug;
        sub dbg { print STDERR "DEBUG: ", join(' ', @_), "\n"; }
        sub LogDbg { print STDERR "LOG: $_[0]: $_[1]\n"; }
        $INC{'DXDebug.pm'} = 1;
    }
}

use Notify;

print "=" x 70, "\n";
print "DXSpider Notification System - Test Script\n";
print "=" x 70, "\n\n";

# Test 1: Load configuration
print "Test 1: Loading configuration...\n";
my $config_file = 'notifications/config/notifications.yml';

unless (-f $config_file) {
    print "ERROR: Config file not found: $config_file\n";
    print "       Copy notifications.yml.example to notifications.yml first.\n";
    exit 1;
}

my $result = Notify::init($config_file);

if ($result) {
    print "✓ Configuration loaded successfully\n";
    print "  Enabled: $Notify::enabled\n";
    print "  Adapters: " . scalar(@Notify::adapters) . "\n\n";

    foreach my $adapter (@Notify::adapters) {
        print "  - " . ref($adapter) . " (" . $adapter->{name} . ")\n";
    }
} else {
    print "✗ Failed to load configuration\n";
    exit 1;
}

print "\n";

# Test 2: Test stats
print "Test 2: Checking system stats...\n";
my $stats = Notify::stats();
print Dumper($stats);
print "\n";

# Test 3: Create test spots
print "Test 3: Creating test spots...\n\n";

my @test_spots = (
    {
        name => "20m FT8",
        freq => 14074.0,
        call => 'K1ABC',
        time => time(),
        comment => 'CQ NA FT8',
        spotter => 'W1XYZ',
        origin => 'N1ABC-2',
        band => '20m',
        mode => 'FT8',
    },
    {
        name => "40m CW",
        freq => 7025.0,
        call => 'DL1ABC',
        time => time(),
        comment => 'CQ DX',
        spotter => 'G3XYZ',
        origin => 'GB7DX',
        band => '40m',
        mode => 'CW',
    },
    {
        name => "6m FM",
        freq => 52525.0,
        call => 'VK2XYZ',
        time => time(),
        comment => 'FM Sporadic E',
        spotter => 'ZL1ABC',
        origin => 'ZL1DX',
        band => '6m',
        mode => 'FM',
    },
    {
        name => "Rare DX",
        freq => 21074.0,
        call => 'VP8ABC',
        time => time(),
        comment => 'FT8 Falklands',
        spotter => 'K1ABC',
        origin => 'W1DX',
        band => '15m',
        mode => 'FT8',
    },
);

# Test 4: Check filters
print "Test 4: Testing filters...\n\n";

foreach my $test (@test_spots) {
    print "Testing: $test->{name} ($test->{call} on $test->{freq} kHz)\n";

    my $matched = 0;
    foreach my $adapter (@Notify::adapters) {
        my $should = $adapter->should_notify($test);
        if ($should) {
            print "  ✓ Matches: " . ref($adapter) . " (" . $adapter->{name} . ")\n";
            $matched++;
        }
    }

    unless ($matched) {
        print "  ✗ No adapters matched\n";
    }

    print "\n";
}

# Test 5: Send test notifications (if requested)
print "Test 5: Send test notifications?\n";
print "  WARNING: This will send real notifications to configured services!\n";
print "  Continue? (yes/no): ";

my $answer = <STDIN>;
chomp $answer;

if (lc($answer) eq 'yes') {
    print "\nSending test notifications...\n\n";

    foreach my $test (@test_spots) {
        print "Dispatching: $test->{name}\n";

        eval {
            Notify::dispatch($test);
        };

        if ($@) {
            print "  ✗ Error: $@\n";
        } else {
            print "  ✓ Dispatched\n";
        }

        # Small delay between notifications
        sleep(1);
    }

    print "\nCheck your Discord/Telegram for notifications!\n";
} else {
    print "Skipped sending test notifications.\n";
}

print "\n";
print "=" x 70, "\n";
print "Test Complete\n";
print "=" x 70, "\n";

# Final stats
print "\nFinal Stats:\n";
my $final_stats = Notify::stats();
print "  Rate limit count: $final_stats->{rate_limit}->{count}\n";
print "  Max per minute: $final_stats->{rate_limit}->{max_per_minute}\n";

print "\n";
print "Tips:\n";
print "  - Review notifications in Discord/Telegram\n";
print "  - Check logs for any errors\n";
print "  - Adjust filters in notifications.yml as needed\n";
print "  - Set more restrictive filters to avoid spam\n";
print "\n";

exit 0;

__END__

=head1 NAME

test_notify.pl - Test script for DXSpider Notification System

=head1 SYNOPSIS

  perl notifications/test_notify.pl

=head1 DESCRIPTION

This script tests the notification system configuration without requiring
a running DXSpider instance. It loads the configuration, checks filters,
and optionally sends test notifications.

=head1 PREREQUISITES

- notifications/config/notifications.yml exists
- Environment variables set in .env or shell
- Perl modules installed (YAML::XS, HTTP::Tiny, JSON)

=head1 TESTS

1. Load configuration from YAML
2. Check system stats
3. Create test spots (various bands/modes)
4. Test filter matching
5. Optionally send real notifications

=head1 ENVIRONMENT VARIABLES

Set these before running:

  export DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."
  export TELEGRAM_BOT_TOKEN="123456:ABC-DEF..."
  export TELEGRAM_CHAT_ID="-1001234567890"

Or source from .env:

  set -a
  source .env
  set +a
  perl notifications/test_notify.pl

=head1 AUTHOR

9M2PJU-DXSpider-Docker Project

=cut
