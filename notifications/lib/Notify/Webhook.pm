#!/usr/bin/perl
#
# Notify::Webhook - HTTP webhook adapter for DXSpider notifications
#
# Sends spot notifications to arbitrary HTTP endpoints with:
# - Configurable URLs
# - Custom headers (for authentication)
# - JSON payload formatting
# - Retry with exponential backoff
# - Timeout handling
#
# Copyright (c) 2025 9M2PJU-DXSpider-Docker Project
#

package Notify::Webhook;

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use Time::HiRes qw(sleep);
use DXDebug;
use Notify::Filter;

our $VERSION = '1.0.0';

#
# Create a new webhook adapter
#
sub new {
    my ($class, $config) = @_;

    unless ($config->{url}) {
        LogDbg('notify', "Webhook adapter requires 'url' parameter");
        return undef;
    }

    my $self = {
        name         => $config->{name} || 'webhook',
        url          => $config->{url},
        headers      => $config->{headers} || {},
        method       => $config->{method} || 'POST',
        timeout      => $config->{timeout} || 10,
        max_retries  => $config->{max_retries} || 3,
        retry_delay  => $config->{retry_delay} || 1,
        filter       => Notify::Filter->new($config->{filters} || []),
        http         => HTTP::Tiny->new(
            timeout => $config->{timeout} || 10,
            agent   => 'DXSpider-Notify/1.0',
        ),
    };

    # Add Content-Type header if not specified
    $self->{headers}->{'Content-Type'} ||= 'application/json';

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
# Send notification via HTTP webhook
#
sub send {
    my ($self, $spot) = @_;

    my $payload = $self->format_payload($spot);
    my $json = encode_json($payload);

    my $attempt = 0;
    my $success = 0;

    while ($attempt < $self->{max_retries} && !$success) {
        $attempt++;

        eval {
            my $response = $self->{http}->request(
                $self->{method},
                $self->{url},
                {
                    headers => $self->{headers},
                    content => $json,
                }
            );

            if ($response->{success}) {
                LogDbg('notify', "Webhook '$self->{name}' sent successfully");
                $success = 1;
            } else {
                my $status = $response->{status} || 'unknown';
                my $reason = $response->{reason} || 'unknown error';
                LogDbg('notify', "Webhook '$self->{name}' failed: $status $reason");

                # Don't retry on client errors (4xx)
                if ($status =~ /^4\d\d$/) {
                    LogDbg('notify', "Client error, not retrying");
                    last;
                }

                # Exponential backoff for retries
                if ($attempt < $self->{max_retries}) {
                    my $delay = $self->{retry_delay} * (2 ** ($attempt - 1));
                    LogDbg('notify', "Retrying in ${delay}s (attempt $attempt/$self->{max_retries})");
                    sleep($delay);
                }
            }
        };

        if ($@) {
            LogDbg('notify', "Webhook '$self->{name}' error: $@");

            # Retry on exceptions
            if ($attempt < $self->{max_retries}) {
                my $delay = $self->{retry_delay} * (2 ** ($attempt - 1));
                sleep($delay);
            }
        }
    }

    return $success;
}

#
# Format spot data as JSON payload
#
sub format_payload {
    my ($self, $spot) = @_;

    return {
        type      => 'dx_spot',
        timestamp => $spot->{time},
        spot      => {
            frequency => $spot->{freq},
            callsign  => $spot->{call},
            band      => $spot->{band},
            mode      => $spot->{mode},
            comment   => $spot->{comment},
        },
        spotter   => {
            callsign  => $spot->{spotter},
            origin    => $spot->{origin},
        },
        metadata  => {
            adapter   => 'webhook',
            name      => $self->{name},
        },
    };
}

1;

__END__

=head1 NAME

Notify::Webhook - HTTP webhook adapter for DXSpider notifications

=head1 SYNOPSIS

  use Notify::Webhook;

  my $webhook = Notify::Webhook->new({
    name    => 'MyWebhook',
    url     => 'https://example.com/webhook',
    headers => {
      'Authorization' => 'Bearer token123',
      'X-Custom'      => 'value',
    },
    method  => 'POST',
    timeout => 10,
    max_retries => 3,
    filters => [
      { bands => ['20m', '40m'] }
    ],
  });

  $webhook->send($spot);

=head1 DESCRIPTION

Notify::Webhook sends DX spot notifications to arbitrary HTTP endpoints.
It supports custom headers for authentication, retry logic with exponential
backoff, and configurable timeouts.

=head1 CONFIGURATION

=head2 Required Parameters

=over 4

=item url

The webhook URL to POST notifications to.

=back

=head2 Optional Parameters

=over 4

=item name

Human-readable name for this webhook (default: 'webhook')

=item headers

Hash of HTTP headers to include in requests
  headers:
    Authorization: "Bearer token123"
    X-API-Key: "secret"

=item method

HTTP method (default: 'POST')

=item timeout

Request timeout in seconds (default: 10)

=item max_retries

Maximum retry attempts (default: 3)

=item retry_delay

Initial retry delay in seconds (default: 1)
Uses exponential backoff: delay * 2^(attempt-1)

=item filters

Array of filter definitions (see Notify::Filter)

=back

=head1 PAYLOAD FORMAT

Notifications are sent as JSON:

  {
    "type": "dx_spot",
    "timestamp": 1234567890,
    "spot": {
      "frequency": 14074.5,
      "callsign": "K1ABC",
      "band": "20m",
      "mode": "FT8",
      "comment": "CQ NA"
    },
    "spotter": {
      "callsign": "W1XYZ",
      "origin": "N1ABC-2"
    },
    "metadata": {
      "adapter": "webhook",
      "name": "MyWebhook"
    }
  }

=head1 RETRY BEHAVIOR

- Retries on 5xx errors and network failures
- No retry on 4xx client errors
- Exponential backoff: 1s, 2s, 4s, 8s...
- Configurable max retries

=head1 METHODS

=head2 new(\%config)

Create a new webhook adapter.

=head2 should_notify($spot)

Check if spot matches filters.

=head2 send($spot)

Send notification. Returns 1 on success, 0 on failure.

=head2 format_payload($spot)

Format spot as JSON payload.

=head1 AUTHOR

9M2PJU-DXSpider-Docker Project

=cut
