#!/usr/bin/perl
#
# reload/notify - Reload notification system configuration
#
# Copyright (c) 2025 9M2PJU-DXSpider-Docker Project
#
# This command reloads the notification configuration without
# restarting DXSpider. Useful after modifying notifications.yml.
#
# Usage:
#   reload/notify
#

my ($self, $line) = @_;
my @out;

# Check privilege level (sysop only)
return (1, $self->msg('e5')) if $self->priv < 9;

push @out, "Reloading notification system configuration...";

eval {
    require Notify;

    my $result = Notify::reload();

    if ($result) {
        push @out, "✓ Configuration reloaded successfully";
        push @out, "  Enabled: " . ($Notify::enabled ? 'YES' : 'NO');
        push @out, "  Adapters: " . scalar(@Notify::adapters);

        foreach my $adapter (@Notify::adapters) {
            push @out, sprintf("    - %s (%s)",
                             ref($adapter), $adapter->{name});
        }
    } else {
        push @out, "✗ Failed to reload configuration";
        push @out, "  Check notifications.yml for errors";
    }
};

if ($@) {
    push @out, "✗ Error reloading notification system";
    push @out, "Error: $@";
}

return (1, @out);
