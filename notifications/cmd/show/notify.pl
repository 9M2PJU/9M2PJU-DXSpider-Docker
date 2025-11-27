#!/usr/bin/perl
#
# show/notify - Display notification system status
#
# Copyright (c) 2025 9M2PJU-DXSpider-Docker Project
#
# Usage:
#   show/notify          - Show status
#   show/notify stats    - Show detailed statistics
#   show/notify adapters - Show adapter information
#

my ($self, $line) = @_;
my @out;

# Check privilege level
return (1, $self->msg('e5')) if $self->priv < 5;

my $cmd = lc($line || '');

eval {
    require Notify;

    if ($Notify::enabled) {
        if ($cmd eq 'stats') {
            # Detailed statistics
            push @out, "Notification System Statistics";
            push @out, "=" x 50;

            my $stats = Notify::stats();

            push @out, sprintf("Status: ENABLED");
            push @out, sprintf("Adapters: %d loaded", $stats->{adapters});
            push @out, "";
            push @out, "Rate Limiting:";
            push @out, sprintf("  Current: %d notifications",
                             $stats->{rate_limit}->{count});
            push @out, sprintf("  Limit: %d per minute",
                             $stats->{rate_limit}->{max_per_minute});
            push @out, sprintf("  Window start: %s",
                             scalar gmtime($stats->{rate_limit}->{window_start}));

        } elsif ($cmd eq 'adapters') {
            # Adapter details
            push @out, "Loaded Notification Adapters";
            push @out, "=" x 50;

            foreach my $adapter (@Notify::adapters) {
                push @out, "";
                push @out, "Adapter: " . ref($adapter);
                push @out, "  Name: " . $adapter->{name};

                if ($adapter->{filter} && $adapter->{filter}->{filters}) {
                    my $filter_count = scalar(@{$adapter->{filter}->{filters}});
                    push @out, "  Filters: $filter_count configured";
                } else {
                    push @out, "  Filters: none (matches all spots)";
                }

                # Adapter-specific info
                if (ref($adapter) eq 'Notify::Discord') {
                    push @out, "  Color scheme: " . $adapter->{color_scheme};
                } elsif (ref($adapter) eq 'Notify::Telegram') {
                    push @out, "  Parse mode: " . $adapter->{parse_mode};
                    push @out, "  Inline keyboard: " .
                             ($adapter->{enable_keyboard} ? 'enabled' : 'disabled');
                } elsif (ref($adapter) eq 'Notify::Webhook') {
                    push @out, "  Method: " . $adapter->{method};
                    push @out, "  Max retries: " . $adapter->{max_retries};
                }
            }

        } else {
            # Default status
            push @out, "Notification System Status";
            push @out, "=" x 50;
            push @out, "Status: ENABLED";
            push @out, "Adapters: " . scalar(@Notify::adapters);

            foreach my $adapter (@Notify::adapters) {
                push @out, sprintf("  - %s (%s)",
                                 ref($adapter), $adapter->{name});
            }

            push @out, "";
            my $stats = Notify::stats();
            push @out, sprintf("Rate limit: %d/%d per minute",
                             $stats->{rate_limit}->{count},
                             $stats->{rate_limit}->{max_per_minute});

            push @out, "";
            push @out, "Usage:";
            push @out, "  show/notify stats    - Detailed statistics";
            push @out, "  show/notify adapters - Adapter information";
        }

    } else {
        push @out, "Notification System: DISABLED";
        push @out, "";
        push @out, "To enable:";
        push @out, "  1. Configure notifications/config/notifications.yml";
        push @out, "  2. Set enabled: true";
        push @out, "  3. Restart DXSpider";
    }
};

if ($@) {
    push @out, "Notification System: NOT LOADED";
    push @out, "Error: $@";
    push @out, "";
    push @out, "Check:";
    push @out, "  - notifications directory mounted";
    push @out, "  - Perl modules installed (YAML::XS, HTTP::Tiny)";
    push @out, "  - entrypoint.sh configured correctly";
}

return (1, @out);
