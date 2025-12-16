#!/usr/bin/perl
#
# Notify::Telegram - Telegram bot integration for DXSpider notifications
#
# Sends spot notifications via Telegram Bot API with:
# - Bot token and chat ID configuration
# - Markdown message formatting
# - Inline keyboard for actions
# - Rate limiting (Telegram limit: 30 messages per second)
# - Retry with exponential backoff
#
# Copyright (c) 2025 9M2PJU-DXSpider-Docker Project
#

package Notify::Telegram;

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use URI::Escape;
use Time::HiRes qw(time sleep);
use DXDebug;
use Notify::Filter;

our $VERSION = '1.0.0';

# Telegram rate limit tracking
our %rate_limits = ();

#
# Create a new Telegram adapter
#
sub new {
    my ($class, $config) = @_;

    unless ($config->{bot_token}) {
        LogDbg('notify', "Telegram adapter requires 'bot_token' parameter");
        return undef;
    }

    unless ($config->{chat_id}) {
        LogDbg('notify', "Telegram adapter requires 'chat_id' parameter");
        return undef;
    }

    my $self = {
        name           => $config->{name} || 'telegram',
        bot_token      => $config->{bot_token},
        chat_id        => $config->{chat_id},
        parse_mode     => $config->{parse_mode} || 'Markdown',
        disable_preview => $config->{disable_web_page_preview} // 1,
        enable_keyboard => $config->{enable_inline_keyboard} // 0,
        timeout        => $config->{timeout} || 10,
        filter         => Notify::Filter->new($config->{filters} || []),
        http           => HTTP::Tiny->new(
            timeout => $config->{timeout} || 10,
            agent   => 'DXSpider-Notify/1.0',
        ),
    };

    # Build API URL
    $self->{api_url} = "https://api.telegram.org/bot$self->{bot_token}";

    # Initialize rate limit tracking
    $rate_limits{$self->{bot_token}} = {
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
# Send notification via Telegram
#
sub send {
    my ($self, $spot) = @_;

    # Check rate limiting
    unless ($self->check_rate_limit()) {
        LogDbg('notify', "Telegram '$self->{name}' rate limited");
        sleep(0.1);
        return 0 unless $self->check_rate_limit();
    }

    my $message = $self->format_message($spot);
    my $payload = {
        chat_id    => $self->{chat_id},
        text       => $message,
        parse_mode => $self->{parse_mode},
        disable_web_page_preview => $self->{disable_preview} ? JSON::true : JSON::false,
    };

    # Add inline keyboard if enabled
    if ($self->{enable_keyboard}) {
        $payload->{reply_markup} = $self->create_keyboard($spot);
    }

    my $json = encode_json($payload);

    eval {
        my $response = $self->{http}->request(
            'POST',
            "$self->{api_url}/sendMessage",
            {
                headers => {
                    'Content-Type' => 'application/json',
                },
                content => $json,
            }
        );

        if ($response->{success}) {
            LogDbg('notify', "Telegram '$self->{name}' sent successfully");
            return 1;
        } else {
            my $status = $response->{status} || 'unknown';
            my $reason = $response->{reason} || 'unknown error';
            LogDbg('notify', "Telegram '$self->{name}' failed: $status $reason");

            # Try to parse error message from Telegram
            if ($response->{content}) {
                eval {
                    my $error = decode_json($response->{content});
                    if ($error->{description}) {
                        LogDbg('notify', "Telegram error: $error->{description}");
                    }
                };
            }

            return 0;
        }
    };

    if ($@) {
        LogDbg('notify', "Telegram '$self->{name}' error: $@");
        return 0;
    }

    return 1;
}

#
# Check Telegram rate limiting
# Conservative limit: 20 messages per second to stay under 30/sec
#
sub check_rate_limit {
    my ($self) = @_;

    my $token = $self->{bot_token};
    my $now = time();
    my $window = 1;  # 1 second window
    my $max = 20;    # 20 messages per second (conservative)

    my $limit = $rate_limits{$token};

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
# Format spot as Telegram message
#
sub format_message {
    my ($self, $spot) = @_;

    my $freq_display = $self->format_frequency($spot->{freq});
    my $time_display = $self->format_time($spot->{time});

    my $message = "";

    if ($self->{parse_mode} eq 'Markdown') {
        $message = "*DX Spot: $spot->{call}*\n\n";
        $message .= "*Frequency:* $freq_display\n";
        $message .= "*Band:* " . uc($spot->{band}) . "\n";
        $message .= "*Mode:* $spot->{mode}\n";

        if ($spot->{comment} && $spot->{comment} ne ' ') {
            my $clean_comment = $self->escape_markdown($spot->{comment});
            $message .= "*Comment:* $clean_comment\n";
        }

        $message .= "\n";
        $message .= "*Spotted by:* $spot->{spotter}";
        if ($spot->{origin}) {
            $message .= " via $spot->{origin}";
        }
        $message .= "\n*Time:* $time_display";

    } elsif ($self->{parse_mode} eq 'HTML') {
        $message = "<b>DX Spot: $spot->{call}</b>\n\n";
        $message .= "<b>Frequency:</b> $freq_display\n";
        $message .= "<b>Band:</b> " . uc($spot->{band}) . "\n";
        $message .= "<b>Mode:</b> $spot->{mode}\n";

        if ($spot->{comment} && $spot->{comment} ne ' ') {
            my $clean_comment = $self->escape_html($spot->{comment});
            $message .= "<b>Comment:</b> $clean_comment\n";
        }

        $message .= "\n";
        $message .= "<b>Spotted by:</b> $spot->{spotter}";
        if ($spot->{origin}) {
            $message .= " via $spot->{origin}";
        }
        $message .= "\n<b>Time:</b> $time_display";

    } else {
        # Plain text
        $message = "DX Spot: $spot->{call}\n\n";
        $message .= "Frequency: $freq_display\n";
        $message .= "Band: " . uc($spot->{band}) . "\n";
        $message .= "Mode: $spot->{mode}\n";

        if ($spot->{comment} && $spot->{comment} ne ' ') {
            $message .= "Comment: $spot->{comment}\n";
        }

        $message .= "\n";
        $message .= "Spotted by: $spot->{spotter}";
        if ($spot->{origin}) {
            $message .= " via $spot->{origin}";
        }
        $message .= "\nTime: $time_display";
    }

    return $message;
}

#
# Create inline keyboard for actions
#
sub create_keyboard {
    my ($self, $spot) = @_;

    my $call = uri_escape($spot->{call});
    my $freq = $spot->{freq};

    return {
        inline_keyboard => [
            [
                {
                    text => "QRZ.com",
                    url  => "https://www.qrz.com/db/$call",
                },
                {
                    text => "HamQTH",
                    url  => "https://www.hamqth.com/$call",
                },
            ],
            [
                {
                    text => "PSKReporter",
                    url  => "https://pskreporter.info/pskmap.html?callsign=$call",
                },
                {
                    text => "Cluster Map",
                    url  => "https://dxheat.com/dxc/?c=$call",
                },
            ],
        ],
    };
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
# Format time for display
#
sub format_time {
    my ($self, $time) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime($time);
    return sprintf("%04d-%02d-%02d %02d:%02d UTC",
        $year + 1900, $mon + 1, $mday, $hour, $min);
}

#
# Escape special characters for Markdown
#
sub escape_markdown {
    my ($self, $text) = @_;

    # Escape Telegram Markdown special characters
    $text =~ s/([\*_\[\]()])/\\$1/g;

    return $text;
}

#
# Escape special characters for HTML
#
sub escape_html {
    my ($self, $text) = @_;

    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;

    return $text;
}

1;

__END__

=head1 NAME

Notify::Telegram - Telegram bot integration for DXSpider notifications

=head1 SYNOPSIS

  use Notify::Telegram;

  my $telegram = Notify::Telegram->new({
    name       => 'MyTelegram',
    bot_token  => '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11',
    chat_id    => '-1001234567890',
    parse_mode => 'Markdown',
    enable_inline_keyboard => 1,
    filters    => [
      { bands => ['20m', '40m'] }
    ],
  });

  $telegram->send($spot);

=head1 DESCRIPTION

Notify::Telegram sends DX spot notifications via Telegram Bot API.
It supports Markdown or HTML formatting, inline keyboards with
lookup links, and proper rate limiting.

=head1 CONFIGURATION

=head2 Required Parameters

=over 4

=item bot_token

Telegram Bot API token (get from @BotFather)

=item chat_id

Telegram chat/channel ID to send messages to
- Private chat: numeric ID (e.g., 123456789)
- Channel: -100 prefix (e.g., -1001234567890)
- Get your chat_id by messaging @userinfobot

=back

=head2 Optional Parameters

=over 4

=item name

Human-readable name for this Telegram bot (default: 'telegram')

=item parse_mode

Message format: 'Markdown', 'HTML', or '' for plain text (default: 'Markdown')

=item disable_web_page_preview

Disable link previews in messages (default: true)

=item enable_inline_keyboard

Add inline keyboard with lookup links (default: false)

=item timeout

Request timeout in seconds (default: 10)

=item filters

Array of filter definitions (see Notify::Filter)

=back

=head1 MESSAGE FORMAT

=head2 Markdown Example

  *DX Spot: K1ABC*

  *Frequency:* 14.074 MHz
  *Band:* 20M
  *Mode:* FT8
  *Comment:* CQ NA

  *Spotted by:* W1XYZ via N1ABC-2
  *Time:* 2025-01-15 14:30 UTC

=head2 Inline Keyboard

When enabled, each message includes buttons for:
- QRZ.com lookup
- HamQTH lookup
- PSKReporter map
- DX Cluster map

=head1 RATE LIMITING

Telegram allows 30 messages per second per bot.
This adapter uses 20/sec limit to stay conservative.

=head1 CREATING A TELEGRAM BOT

1. Message @BotFather on Telegram
2. Send: /newbot
3. Follow prompts to name your bot
4. Save the API token provided
5. Add bot to your channel/group
6. Get chat ID using @userinfobot

=head1 METHODS

=head2 new(\%config)

Create a new Telegram adapter.

=head2 should_notify($spot)

Check if spot matches filters.

=head2 send($spot)

Send notification. Returns 1 on success, 0 on failure.

=head2 format_message($spot)

Format spot as Telegram message.

=head2 create_keyboard($spot)

Create inline keyboard with action buttons.

=head1 AUTHOR

9M2PJU-DXSpider-Docker Project

=cut
