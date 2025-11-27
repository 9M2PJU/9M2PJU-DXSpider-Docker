# DXSpider Notification System - Integration Guide

This guide shows how to integrate the notification system into your DXSpider installation.

## Integration Points

The notification system hooks into the spot processing pipeline at a single point in `cmd/dx.pl` after spots are added to the database.

## Step-by-Step Integration

### Step 1: Update Dockerfile

Add YAML::XS and HTTP::Tiny Perl modules to your Dockerfile:

```dockerfile
# Add to your RUN apk add section
RUN apk add --no-cache \
    perl-yaml-libyaml \
    perl-http-tiny \
    perl-json \
    perl-uri \
    # ... other packages
```

Or install at runtime in entrypoint.sh:

```bash
# Install Perl modules if needed
cpan -i YAML::XS HTTP::Tiny JSON URI::Escape
```

### Step 2: Mount Notifications Directory

Update `docker-compose.yml` to mount the notifications directory:

```yaml
services:
  dxspider:
    volumes:
      # Existing volumes...
      - ./notifications:/spider/notifications:ro
```

### Step 3: Update entrypoint.sh

Add notification system initialization to `entrypoint.sh`:

```bash
#!/bin/sh

# ... existing code ...

# Initialize notification system (before starting DXSpider)
cat > /spider/local/Notify_init.pl <<'NOTIFY_INIT'
#!/usr/bin/perl
#
# Initialize notification system
#
# Add this to DXVars.pm or load during startup

use lib '/spider/notifications/lib';

# Try to load notification system
eval {
    require Notify;

    # Initialize from config file
    if (-f '/spider/notifications/config/notifications.yml') {
        my $result = Notify::init('/spider/notifications/config/notifications.yml');

        if ($result) {
            DXDebug::dbg("Notification system initialized");
        } else {
            DXDebug::dbg("Notification system disabled");
        }
    } else {
        DXDebug::dbg("Notification config not found, notifications disabled");
    }
};

if ($@) {
    DXDebug::dbg("Failed to load notification system: $@");
}

1;
NOTIFY_INIT

chmod +x /spider/local/Notify_init.pl

# ... rest of entrypoint.sh ...
```

### Step 4: Modify DXVars.pm Generation

Update the DXVars.pm generation in `entrypoint.sh` to include the notification initialization:

```bash
cat > /spider/local/DXVars.pm <<DXVARS
# ... existing DXVars content ...

# Load notification system
do '/spider/local/Notify_init.pl';

1;
DXVARS
```

### Step 5: Modify cmd/dx.pl

This is the core integration point. Modify `cmd/dx.pl` to dispatch notifications after spots are added.

**Option A: Patch the File (Recommended)**

Create a patch file `notifications/patches/dx.pl.patch`:

```patch
--- a/cmd/dx.pl
+++ b/cmd/dx.pl
@@ -184,6 +184,14 @@ if ($freq =~ /^69/ || $localonly) {
 	} else {
 		# store in spots database
 		Spot::add(@spot);
+
+		# Dispatch to notification system
+		eval {
+			require Notify;
+			Notify::dispatch(\@spot) if $Notify::enabled;
+		};
+		# Silently ignore notification errors
+
 		DXProt::send_dx_spot($self, $spot, @spot);
 	}
 }
```

Apply in entrypoint.sh:

```bash
# Apply notification patch to dx.pl
if [ -f /spider/notifications/patches/dx.pl.patch ]; then
    patch -p1 -d /spider < /spider/notifications/patches/dx.pl.patch
fi
```

**Option B: Direct Modification**

If you can't use patches, modify `/spider/cmd/dx.pl` directly.

Find this section (around line 186):

```perl
} else {
    # send orf to the users
    $ipaddr ||= $main::mycall;	# emergency backstop
    my $spot = DXProt::pc61($spotter, $freq, $spotted, unpad($line),  $ipaddr);

    $self->dx_spot(undef, undef, @spot);
    if ($self->isslugged) {
        push @{$self->{sluggedpcs}}, [61, $spot, \@spot];
    } else {
        # store in spots database
        Spot::add(@spot);
        DXProt::send_dx_spot($self, $spot, @spot);
    }
}
```

Change to:

```perl
} else {
    # send orf to the users
    $ipaddr ||= $main::mycall;	# emergency backstop
    my $spot = DXProt::pc61($spotter, $freq, $spotted, unpad($line),  $ipaddr);

    $self->dx_spot(undef, undef, @spot);
    if ($self->isslugged) {
        push @{$self->{sluggedpcs}}, [61, $spot, \@spot];
    } else {
        # store in spots database
        Spot::add(@spot);

        # Dispatch to notification system
        eval {
            require Notify;
            Notify::dispatch(\@spot) if $Notify::enabled;
        };
        # Silently ignore notification errors - don't impact spot processing

        DXProt::send_dx_spot($self, $spot, @spot);
    }
}
```

### Step 6: Configure Notifications

1. Copy example config:
```bash
cp notifications/config/notifications.yml.example notifications/config/notifications.yml
```

2. Edit `notifications/config/notifications.yml` with your settings

3. Set environment variables in `.env`:
```bash
# Discord
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...

# Telegram
TELEGRAM_BOT_TOKEN=123456:ABC-DEF...
TELEGRAM_CHAT_ID=-1001234567890

# Generic Webhook
WEBHOOK_API_TOKEN=your-secret-token
```

### Step 7: Rebuild and Test

```bash
# Rebuild container
docker compose down
docker compose up -d --build

# Watch logs for notification activity
docker compose logs -f | grep -i notify

# Test by posting a spot
telnet localhost 7300
# Login with your call
dx 14074.0 K1ABC FT8 Test spot
```

## Complete entrypoint.sh Example

Here's a complete example of the modified entrypoint.sh:

```bash
#!/bin/sh
set -e

# ... existing code for Listeners.pm and DXVars.pm ...

# Create notification initialization script
cat > /spider/local/Notify_init.pl <<'NOTIFY_INIT'
#!/usr/bin/perl
use lib '/spider/notifications/lib';

eval {
    require Notify;

    if (-f '/spider/notifications/config/notifications.yml') {
        my $result = Notify::init('/spider/notifications/config/notifications.yml');

        if ($result) {
            DXDebug::dbg("Notification system initialized with " .
                        scalar(@Notify::adapters) . " adapters");
        }
    }
};

if ($@) {
    DXDebug::dbg("Notification system load failed: $@");
}

1;
NOTIFY_INIT

chmod +x /spider/local/Notify_init.pl

# Update DXVars.pm to load notifications
cat >> /spider/local/DXVars.pm <<'DXVARS_APPEND'

# Load notification system
do '/spider/local/Notify_init.pl';

1;
DXVARS_APPEND

# Apply notification patch if available
if [ -f /spider/notifications/patches/dx.pl.patch ]; then
    echo "Applying notification system patch..."
    cd /spider
    patch -p1 -N -r - < /spider/notifications/patches/dx.pl.patch || true
fi

# ... rest of entrypoint.sh (start DXSpider, ttyd, etc.) ...
```

## Verification

### Check System Loaded

Connect to your cluster and check logs:

```bash
docker compose logs | grep -i notify
```

You should see:
```
Notification system initialized with 2 adapters
```

### Check Stats

Create a debug command `cmd/show/notify.pl`:

```perl
#!/usr/bin/perl
#
# Show notification system status
#

my ($self, $line) = @_;
my @out;

eval {
    require Notify;

    if ($Notify::enabled) {
        push @out, "Notification system: ENABLED";
        push @out, "Adapters loaded: " . scalar(@Notify::adapters);

        foreach my $adapter (@Notify::adapters) {
            push @out, "  - " . ref($adapter) . " (" . $adapter->{name} . ")";
        }

        my $stats = Notify::stats();
        push @out, "Rate limit: " . $stats->{rate_limit}->{count} .
                   "/" . $stats->{rate_limit}->{max_per_minute} . " per minute";
    } else {
        push @out, "Notification system: DISABLED";
    }
};

if ($@) {
    push @out, "Notification system: NOT LOADED";
    push @out, "Error: $@";
}

return (1, @out);
```

Then run:
```
sh/notify
```

### Test Notification

Post a test spot that matches your filters:

```bash
telnet localhost 7300
# Login
dx 14074.0 K1ABC FT8 Test notification
```

Check Discord/Telegram for notification.

## Troubleshooting

### Module Load Errors

**Error**: `Can't locate YAML/XS.pm`

**Solution**: Install Perl modules:
```dockerfile
RUN apk add --no-cache perl-yaml-libyaml
```

### Configuration Errors

**Error**: `Config file not found`

**Solution**: Verify file path and volume mount:
```bash
docker compose exec dxspider ls -la /spider/notifications/config/
```

### No Notifications Sent

**Check**:
1. `enabled: true` in config
2. Environment variables set correctly
3. Filters not too restrictive
4. Adapter credentials valid
5. Logs for errors: `docker compose logs | grep notify`

### Patch Fails to Apply

If the patch doesn't apply cleanly, manually edit `cmd/dx.pl` as shown in Option B above.

## Advanced Integration

### Custom Spot Processing

You can add custom logic before notifications:

```perl
# In dx.pl, before Notify::dispatch
my %custom_spot = (
    %{$spot},
    custom_field => calculate_something(@spot),
);

Notify::dispatch(\%custom_spot);
```

### Multiple Notification Points

You can call `Notify::dispatch()` from multiple places:

- `cmd/dx.pl` - For DX spots
- `cmd/announce.pl` - For announcements
- Custom scripts - For scheduled alerts

### Dynamic Configuration

Reload config without restart:

```perl
# In a sysop command
Notify::reload();
```

## Performance Considerations

- Notifications are dispatched after `Spot::add()` completes
- Errors in notification system don't affect spot processing (wrapped in eval)
- Rate limiting prevents overwhelming external services
- Non-blocking HTTP requests (with timeout)

## Security Best Practices

1. **Never commit credentials** to git
2. **Use environment variables** for all secrets
3. **Mount config as read-only**: `:ro` in docker-compose.yml
4. **Restrict webhook URLs** - they grant access to your channels
5. **Use HTTPS** for all webhooks (enforced by adapters)

## Support

If you encounter issues:

1. Check logs: `docker compose logs | grep notify`
2. Verify configuration syntax (YAML is whitespace-sensitive)
3. Test with minimal config (one adapter, one filter)
4. Review GitHub issues
5. Ask in Discord/Forum

## See Also

- [README.md](README.md) - Overview and features
- [notifications.yml.example](config/notifications.yml.example) - Configuration examples
- [Notify.pm](lib/Notify.pm) - Main module documentation
- [Notify::Filter](lib/Notify/Filter.pm) - Filter engine documentation
