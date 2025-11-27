#!/usr/bin/perl
#
# Notify.pm - Main notification dispatcher for DXSpider
#
# Hooks into spot processing pipeline and dispatches notifications
# to configured adapters (Webhook, Discord, Telegram, etc.)
#
# Copyright (c) 2025 9M2PJU-DXSpider-Docker Project
#
# Usage:
#   use Notify;
#   Notify::init('/path/to/notifications.yml');
#   Notify::dispatch(\@spot);
#

package Notify;

use strict;
use warnings;
use YAML::XS qw(LoadFile);
use Time::HiRes qw(time);
use DXDebug;
use Notify::Filter;

our $VERSION = '1.0.0';
our $enabled = 0;
our $config = {};
our @adapters = ();
our %rate_limit = (
    count => 0,
    window_start => time(),
    max_per_minute => 60,
);

#
# Initialize the notification system
# Load configuration and set up adapters
#
sub init {
    my $config_file = shift || '/spider/notifications/config/notifications.yml';

    unless (-f $config_file) {
        LogDbg('notify', "Config file not found: $config_file");
        return 0;
    }

    eval {
        $config = LoadFile($config_file);

        # Check if notifications are enabled globally
        unless ($config->{enabled}) {
            LogDbg('notify', "Notifications disabled in config");
            return 0;
        }

        # Set rate limiting
        if ($config->{rate_limit} && $config->{rate_limit}->{max_per_minute}) {
            $rate_limit{max_per_minute} = $config->{rate_limit}->{max_per_minute};
        }

        # Load and initialize adapters
        foreach my $adapter_config (@{$config->{adapters} || []}) {
            next unless $adapter_config->{enabled};

            my $type = $adapter_config->{type};
            my $module = "Notify::" . ucfirst(lc($type));

            eval "require $module";
            if ($@) {
                LogDbg('notify', "Failed to load adapter $module: $@");
                next;
            }

            # Initialize adapter
            my $adapter = $module->new($adapter_config);
            if ($adapter) {
                push @adapters, $adapter;
                LogDbg('notify', "Loaded adapter: $type (" . $adapter_config->{name} . ")");
            }
        }

        $enabled = 1;
        LogDbg('notify', "Notification system initialized with " . scalar(@adapters) . " adapters");
    };

    if ($@) {
        LogDbg('notify', "Failed to initialize notifications: $@");
        return 0;
    }

    return 1;
}

#
# Dispatch a spot to all configured adapters
# @spot array format: [freq, call, time, comment, spotter, origin, ipaddr]
#
sub dispatch {
    my $spot_ref = shift;
    return unless $enabled;
    return unless $spot_ref && ref($spot_ref) eq 'ARRAY';

    # Rate limiting check
    if (!check_rate_limit()) {
        LogDbg('notify', "Rate limit exceeded, dropping notification");
        return;
    }

    # Convert spot array to hash for easier handling
    my $spot = {
        freq     => $spot_ref->[0],
        call     => $spot_ref->[1],
        time     => $spot_ref->[2],
        comment  => $spot_ref->[3] || '',
        spotter  => $spot_ref->[4],
        origin   => $spot_ref->[5] || '',
        ipaddr   => $spot_ref->[6] || '',
    };

    # Add derived fields
    $spot->{band} = freq_to_band($spot->{freq});
    $spot->{mode} = extract_mode($spot->{comment});

    # Dispatch to each adapter
    foreach my $adapter (@adapters) {
        eval {
            # Apply adapter-specific filters
            if ($adapter->should_notify($spot)) {
                $adapter->send($spot);
            }
        };
        if ($@) {
            LogDbg('notify', "Adapter " . ref($adapter) . " failed: $@");
        }
    }
}

#
# Check rate limiting
# Returns 1 if notification can proceed, 0 if rate limited
#
sub check_rate_limit {
    my $now = time();
    my $window = 60; # 1 minute window

    # Reset counter if window has passed
    if ($now - $rate_limit{window_start} >= $window) {
        $rate_limit{count} = 0;
        $rate_limit{window_start} = $now;
    }

    # Check if we're over limit
    if ($rate_limit{count} >= $rate_limit{max_per_minute}) {
        return 0;
    }

    # Increment counter
    $rate_limit{count}++;
    return 1;
}

#
# Convert frequency (in kHz) to band name
#
sub freq_to_band {
    my $freq = shift;
    return 'unknown' unless $freq;

    # Convert to kHz if needed
    $freq = $freq / 1000 if $freq > 1000000;

    my %bands = (
        '160m'  => [1800, 2000],
        '80m'   => [3500, 4000],
        '60m'   => [5250, 5450],
        '40m'   => [7000, 7300],
        '30m'   => [10100, 10150],
        '20m'   => [14000, 14350],
        '17m'   => [18068, 18168],
        '15m'   => [21000, 21450],
        '12m'   => [24890, 24990],
        '10m'   => [28000, 29700],
        '6m'    => [50000, 54000],
        '2m'    => [144000, 148000],
        '70cm'  => [420000, 450000],
    );

    foreach my $band (keys %bands) {
        if ($freq >= $bands{$band}->[0] && $freq <= $bands{$band}->[1]) {
            return $band;
        }
    }

    return 'unknown';
}

#
# Extract mode from comment field
# Returns mode string or 'UNKNOWN'
#
sub extract_mode {
    my $comment = shift || '';

    # Common mode indicators
    my %modes = (
        'CW'    => qr/\b(CW|QRS)\b/i,
        'SSB'   => qr/\b(SSB|LSB|USB|PHONE)\b/i,
        'FT8'   => qr/\bFT8\b/i,
        'FT4'   => qr/\bFT4\b/i,
        'RTTY'  => qr/\b(RTTY|FSK)\b/i,
        'PSK'   => qr/\b(PSK|PSK31|PSK63)\b/i,
        'JT65'  => qr/\bJT65\b/i,
        'JT9'   => qr/\bJT9\b/i,
        'WSPR'  => qr/\bWSPR\b/i,
        'FM'    => qr/\bFM\b/i,
        'AM'    => qr/\bAM\b/i,
    );

    foreach my $mode (keys %modes) {
        if ($comment =~ $modes{$mode}) {
            return $mode;
        }
    }

    return 'UNKNOWN';
}

#
# Reload configuration
#
sub reload {
    @adapters = ();
    $enabled = 0;
    return init();
}

#
# Get statistics
#
sub stats {
    return {
        enabled => $enabled,
        adapters => scalar(@adapters),
        rate_limit => \%rate_limit,
    };
}

1;

__END__

=head1 NAME

Notify - Notification dispatcher for DXSpider spots

=head1 SYNOPSIS

  use Notify;

  # Initialize from config file
  Notify::init('/spider/notifications/config/notifications.yml');

  # Dispatch a spot notification
  Notify::dispatch(\@spot);

  # Reload configuration
  Notify::reload();

  # Get stats
  my $stats = Notify::stats();

=head1 DESCRIPTION

Notify is the main dispatcher for the DXSpider notification system.
It loads configuration, manages adapters (Webhook, Discord, Telegram),
applies filters, and handles rate limiting.

=head1 CONFIGURATION

Configuration is loaded from YAML file with the following structure:

  enabled: true
  rate_limit:
    max_per_minute: 60
  adapters:
    - type: discord
      name: "Main Discord"
      enabled: true
      webhook_url: "https://..."
      filters: [...]

=head1 SPOT FORMAT

Spots are passed as array references:
  [freq, call, time, comment, spotter, origin, ipaddr]

Internally converted to hash:
  {
    freq: frequency in kHz
    call: spotted callsign
    time: unix timestamp
    comment: spot comment
    spotter: spotter callsign
    origin: originating node
    ipaddr: IP address
    band: derived band (160m, 80m, etc.)
    mode: derived mode (CW, SSB, FT8, etc.)
  }

=head1 RATE LIMITING

Default: 60 notifications per minute (configurable)
Uses sliding window algorithm.

=head1 AUTHOR

9M2PJU-DXSpider-Docker Project

=cut
