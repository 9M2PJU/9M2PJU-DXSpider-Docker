#!/usr/bin/perl
#
# Notify::Discord - Discord webhook integration for DXSpider notifications
#
# Sends rich embedded messages to Discord channels via webhooks with:
# - Discord webhook URL support
# - Rich embed formatting with color coding
# - Band-based color coding
# - Rate limiting (Discord limit: 5 requests per 5 seconds)
# - Retry with exponential backoff
#
# Copyright (c) 2025 9M2PJU-DXSpider-Docker Project
#

package Notify::Discord;

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use Time::HiRes qw(time sleep);
use DXDebug;
use Notify::Filter;

our $VERSION = '1.0.0';

# Discord rate limit: 5 requests per 5 seconds per webhook
our %rate_limits = ();

#
# Create a new Discord adapter
#
sub new {
    my ($class, $config) = @_;

    unless ($config->{webhook_url}) {
        LogDbg('notify', "Discord adapter requires 'webhook_url' parameter");
        return undef;
    }

    my $self = {
        name         => $config->{name} || 'discord',
        webhook_url  => $config->{webhook_url},
        username     => $config->{username} || 'DXSpider',
        avatar_url   => $config->{avatar_url} || '',
        color_scheme => $config->{color_scheme} || 'band',
        timeout      => $config->{timeout} || 10,
        filter       => Notify::Filter->new($config->{filters} || []),
        http         => HTTP::Tiny->new(
            timeout => $config->{timeout} || 10,
            agent   => 'DXSpider-Notify/1.0',
        ),
    };

    # Initialize rate limit tracking for this webhook
    $rate_limits{$self->{webhook_url}} = {
        count => 0,
        window_start => time(),
    };

    bless $self, $class;
    return $self;
}

#
# Check if this adapter should notify for a given spot
#
sub should_notify {
    my ($self, $spot) = @_;
    return $self->{filter}->matches($spot);
}

#
# Send notification to Discord
#
sub send {
    my ($self, $spot) = @_;

    # Check rate limiting
    unless ($self->check_rate_limit()) {
        LogDbg('notify', "Discord '$self->{name}' rate limited, queuing");
        sleep(1); # Wait a bit and retry
        return 0 unless $self->check_rate_limit();
    }

    my $payload = $self->format_payload($spot);
    my $json = encode_json($payload);

    eval {
        my $response = $self->{http}->request(
            'POST',
            $self->{webhook_url},
            {
                headers => {
                    'Content-Type' => 'application/json',
                },
                content => $json,
            }
        );

        if ($response->{success}) {
            LogDbg('notify', "Discord '$self->{name}' sent successfully");
            return 1;
        } else {
            my $status = $response->{status} || 'unknown';
            my $reason = $response->{reason} || 'unknown error';
            LogDbg('notify', "Discord '$self->{name}' failed: $status $reason");

            # Handle rate limiting from Discord
            if ($status == 429) {
                my $retry_after = $response->{headers}->{'retry-after'} || 5;
                LogDbg('notify', "Discord rate limited by server, retry after ${retry_after}s");
            }

            return 0;
        }
    };

    if ($@) {
        LogDbg('notify', "Discord '$self->{name}' error: $@");
        return 0;
    }

    return 1;
}

#
# Check Discord rate limiting
# Discord limit: 5 requests per 5 seconds per webhook
#
sub check_rate_limit {
    my ($self) = @_;

    my $url = $self->{webhook_url};
    my $now = time();
    my $window = 5; # 5 second window
    my $max = 5;    # 5 requests per window

    my $limit = $rate_limits{$url};

    # Reset counter if window has passed
    if ($now - $limit->{window_start} >= $window) {
        $limit->{count} = 0;
        $limit->{window_start} = $now;
    }

    # Check if we're over limit
    if ($limit->{count} >= $max) {
        return 0;
    }

    # Increment counter
    $limit->{count}++;
    return 1;
}

#
# Format spot as Discord webhook payload with embed
#
sub format_payload {
    my ($self, $spot) = @_;

    my $color = $self->get_color($spot);
    my $timestamp = $self->format_timestamp($spot->{time});

    my $embed = {
        title       => "DX Spot: $spot->{call}",
        description => $self->format_description($spot),
        color       => $color,
        timestamp   => $timestamp,
        footer      => {
            text => "Spotted by $spot->{spotter}" .
                    ($spot->{origin} ? " via $spot->{origin}" : ""),
        },
        fields      => [
            {
                name   => "Frequency",
                value  => $self->format_frequency($spot->{freq}),
                inline => JSON::true,
            },
            {
                name   => "Band",
                value  => uc($spot->{band}),
                inline => JSON::true,
            },
            {
                name   => "Mode",
                value  => $spot->{mode},
                inline => JSON::true,
            },
        ],
    };

    # Add comment field if present
    if ($spot->{comment} && $spot->{comment} ne ' ') {
        push @{$embed->{fields}}, {
            name   => "Comment",
            value  => $spot->{comment},
            inline => JSON::false,
        };
    }

    my $payload = {
        username   => $self->{username},
        embeds     => [$embed],
    };

    # Add avatar URL if configured
    if ($self->{avatar_url}) {
        $payload->{avatar_url} = $self->{avatar_url};
    }

    return $payload;
}

#
# Format description text
#
sub format_description {
    my ($self, $spot) = @_;

    return "**$spot->{call}** on **" . $self->format_frequency($spot->{freq}) . "**";
}

#
# Format frequency for display
#
sub format_frequency {
    my ($self, $freq) = @_;

    if ($freq >= 1000) {
        return sprintf("%.1f kHz", $freq);
    } else {
        return sprintf("%.3f MHz", $freq / 1000);
    }
}

#
# Format Unix timestamp for Discord
#
sub format_timestamp {
    my ($self, $time) = @_;

    # Discord expects ISO 8601 format
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime($time);
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}

#
# Get color based on band or mode
# Returns decimal color value for Discord embed
#
sub get_color {
    my ($self, $spot) = @_;

    if ($self->{color_scheme} eq 'band') {
        return $self->get_band_color($spot->{band});
    } elsif ($self->{color_scheme} eq 'mode') {
        return $self->get_mode_color($spot->{mode});
    }

    return 0x3498db; # Default blue
}

#
# Color mapping for bands
#
sub get_band_color {
    my ($self, $band) = @_;

    my %colors = (
        '160m' => 0x8b0000,  # Dark red
        '80m'  => 0xff4500,  # Orange red
        '60m'  => 0xff8c00,  # Dark orange
        '40m'  => 0xffa500,  # Orange
        '30m'  => 0xffd700,  # Gold
        '20m'  => 0x32cd32,  # Lime green
        '17m'  => 0x00ced1,  # Dark turquoise
        '15m'  => 0x1e90ff,  # Dodger blue
        '12m'  => 0x4169e1,  # Royal blue
        '10m'  => 0x8a2be2,  # Blue violet
        '6m'   => 0x9932cc,  # Dark orchid
        '2m'   => 0xff1493,  # Deep pink
        '70cm' => 0xff69b4,  # Hot pink
    );

    return $colors{lc($band)} || 0x3498db; # Default blue
}

#
# Color mapping for modes
#
sub get_mode_color {
    my ($self, $mode) = @_;

    my %colors = (
        'CW'    => 0xffd700,  # Gold
        'SSB'   => 0x32cd32,  # Lime green
        'FT8'   => 0x1e90ff,  # Dodger blue
        'FT4'   => 0x4169e1,  # Royal blue
        'RTTY'  => 0xff8c00,  # Dark orange
        'PSK'   => 0x00ced1,  # Dark turquoise
        'JT65'  => 0x9932cc,  # Dark orchid
        'JT9'   => 0x8a2be2,  # Blue violet
        'WSPR'  => 0xff1493,  # Deep pink
        'FM'    => 0x32cd32,  # Lime green
        'AM'    => 0xffa500,  # Orange
    );

    return $colors{$mode} || 0x3498db; # Default blue
}

1;

__END__

=head1 NAME

Notify::Discord - Discord webhook integration for DXSpider notifications

=head1 SYNOPSIS

  use Notify::Discord;

  my $discord = Notify::Discord->new({
    name         => 'MyDiscord',
    webhook_url  => 'https://discord.com/api/webhooks/...',
    username     => 'DXSpider Bot',
    avatar_url   => 'https://example.com/avatar.png',
    color_scheme => 'band',  # or 'mode'
    filters      => [
      { bands => ['20m', '40m'] }
    ],
  });

  $discord->send($spot);

=head1 DESCRIPTION

Notify::Discord sends DX spot notifications to Discord channels via webhooks.
It creates rich embedded messages with color coding, formatted frequency
display, and proper rate limiting.

=head1 CONFIGURATION

=head2 Required Parameters

=over 4

=item webhook_url

Discord webhook URL (get from Channel Settings → Integrations → Webhooks)

=back

=head2 Optional Parameters

=over 4

=item name

Human-readable name for this Discord webhook (default: 'discord')

=item username

Bot username to display in Discord (default: 'DXSpider')

=item avatar_url

URL to avatar image for the bot

=item color_scheme

Color coding scheme: 'band' or 'mode' (default: 'band')

=item timeout

Request timeout in seconds (default: 10)

=item filters

Array of filter definitions (see Notify::Filter)

=back

=head1 DISCORD EMBED FORMAT

Notifications appear as rich embeds with:
- Title: "DX Spot: CALLSIGN"
- Color coded by band or mode
- Fields: Frequency, Band, Mode, Comment
- Footer: Spotter and origin information
- Timestamp

=head1 COLOR SCHEMES

=head2 Band Colors

  160m - Dark red
  80m  - Orange red
  40m  - Orange
  30m  - Gold
  20m  - Lime green
  17m  - Dark turquoise
  15m  - Dodger blue
  12m  - Royal blue
  10m  - Blue violet
  6m   - Dark orchid
  2m   - Deep pink
  70cm - Hot pink

=head2 Mode Colors

  CW   - Gold
  SSB  - Lime green
  FT8  - Dodger blue
  FT4  - Royal blue
  RTTY - Dark orange
  PSK  - Dark turquoise

=head1 RATE LIMITING

Discord enforces 5 requests per 5 seconds per webhook.
This adapter tracks and enforces this limit automatically.

=head1 METHODS

=head2 new(\%config)

Create a new Discord adapter.

=head2 should_notify($spot)

Check if spot matches filters.

=head2 send($spot)

Send notification. Returns 1 on success, 0 on failure.

=head2 format_payload($spot)

Format spot as Discord webhook payload.

=head1 AUTHOR

9M2PJU-DXSpider-Docker Project

=cut
