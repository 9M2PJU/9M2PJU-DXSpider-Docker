# DXSpider Notification System

## Overview

The DXSpider Notification System is a comprehensive real-time notification framework for DX spots. It supports multiple notification channels (Discord, Telegram, generic webhooks) with sophisticated filtering and rate limiting.

## Features

- **Multiple Adapters**: Discord, Telegram, and generic HTTP webhooks
- **Advanced Filtering**: Filter by band, mode, DXCC entity, callsign patterns, and more
- **Rate Limiting**: Prevents overwhelming external services and respects API limits
- **Retry Logic**: Automatic retry with exponential backoff for failed requests
- **Rich Formatting**: Beautiful embedded messages for Discord, Markdown for Telegram
- **Environment Variables**: Secure credential management via environment variables
- **Non-Blocking**: Async dispatch doesn't slow down spot processing

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        DXSpider                              │
│                    cmd/dx.pl (Spot Entry)                    │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  Notify.pm (Dispatcher)                      │
│  • Load configuration                                        │
│  • Apply rate limiting                                       │
│  • Route to adapters                                         │
└───────────────────────────┬─────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
┌─────────────────┐ ┌─────────────┐ ┌─────────────┐
│  Discord.pm     │ │ Telegram.pm │ │ Webhook.pm  │
│  • Rich embeds  │ │ • Markdown  │ │ • Generic   │
│  • Color coding │ │ • Keyboards │ │ • Custom    │
│  • 5/5s limit   │ │ • 20/1s lmt │ │ • Auth      │
└────────┬────────┘ └──────┬──────┘ └──────┬──────┘
         │                 │                │
         ▼                 ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│              Notify::Filter (Filter Engine)                  │
│  • Band filters                                              │
│  • Mode filters                                              │
│  • DXCC filters                                              │
│  • Callsign patterns                                         │
│  • AND/OR logic                                              │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Installation

The notification system is included in the Docker container. No additional installation required.

### 2. Configuration

Copy the example configuration:

```bash
cp notifications/config/notifications.yml.example notifications/config/notifications.yml
```

Edit `notifications/config/notifications.yml` to configure your adapters.

### 3. Set Environment Variables

Add notification credentials to your `.env` file:

```bash
# Discord
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/123456789/abcdef...

# Telegram
TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_CHAT_ID=-1001234567890

# Generic Webhook
WEBHOOK_API_TOKEN=your-secret-token
```

### 4. Enable in DXSpider

Add to `entrypoint.sh` or startup script:

```perl
# Load notification system
use lib '/spider/notifications/lib';
use Notify;

# Initialize with config file
Notify::init('/spider/notifications/config/notifications.yml');
```

### 5. Integrate with dx.pl

Modify `cmd/dx.pl` to dispatch notifications. Add after line 186 (after `Spot::add(@spot)`):

```perl
# Send notifications (if enabled)
eval {
    require Notify;
    Notify::dispatch(\@spot) if $Notify::enabled;
};
```

### 6. Rebuild Container

```bash
docker compose down
docker compose up -d --build
```

## Adapter Setup Guides

### Discord Setup

1. **Create Webhook**:
   - Open Discord channel
   - Channel Settings → Integrations → Webhooks
   - Click "New Webhook"
   - Name it (e.g., "DXSpider")
   - Copy webhook URL

2. **Configure**:
   ```yaml
   - type: discord
     name: "Main Channel"
     enabled: true
     webhook_url: "${DISCORD_WEBHOOK_URL}"
     username: "DXSpider"
     color_scheme: "band"
     filters:
       - bands: ['20m', '40m']
   ```

3. **Set Environment Variable**:
   ```bash
   DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
   ```

### Telegram Setup

1. **Create Bot**:
   - Message @BotFather on Telegram
   - Send: `/newbot`
   - Follow prompts to name your bot
   - Save the API token

2. **Get Chat ID**:
   - Message @userinfobot or @getidsbot
   - For channels: Add bot to channel, get ID (format: `-1001234567890`)

3. **Configure**:
   ```yaml
   - type: telegram
     name: "Personal Alerts"
     enabled: true
     bot_token: "${TELEGRAM_BOT_TOKEN}"
     chat_id: "${TELEGRAM_CHAT_ID}"
     parse_mode: "Markdown"
     enable_inline_keyboard: true
     filters:
       - bands: ['20m', '15m']
   ```

4. **Set Environment Variables**:
   ```bash
   TELEGRAM_BOT_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
   TELEGRAM_CHAT_ID=-1001234567890
   ```

### Generic Webhook Setup

1. **Configure**:
   ```yaml
   - type: webhook
     name: "Custom API"
     enabled: true
     url: "https://your-server.com/api/webhook"
     method: "POST"
     headers:
       Authorization: "Bearer ${WEBHOOK_API_TOKEN}"
     timeout: 10
     max_retries: 3
     filters:
       - bands: ['6m']
   ```

2. **Payload Format**:
   ```json
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
     }
   }
   ```

## Filter Examples

### Basic Filters

**Specific Bands**:
```yaml
filters:
  - bands: ['20m', '40m', '15m']
```

**Specific Modes**:
```yaml
filters:
  - modes: ['CW', 'FT8']
```

**DXCC Entities**:
```yaml
filters:
  - dxcc: [291, 150]  # USA, Netherlands
```

**Callsign Patterns**:
```yaml
filters:
  - callsign: 'VK*'     # Australian calls
  - callsign: '^K[0-9]' # US K + digit
```

### Advanced Filters

**AND Logic** (all conditions must match):
```yaml
filters:
  - and:
      - bands: ['20m']
      - modes: ['CW']
      - dxcc: [291]  # 20m CW from USA only
```

**OR Logic** (any condition matches):
```yaml
filters:
  - or:
      - bands: ['6m']
      - comment_contains: 'POTA'
      - comment_contains: 'SOTA'
```

**Frequency Range**:
```yaml
filters:
  - freq_min: 14000
    freq_max: 14070  # 20m CW segment
```

**Comment Search**:
```yaml
filters:
  - comment_contains: 'IOTA'
  - comment_contains: 'POTA'
```

**Spotter Filter**:
```yaml
filters:
  - spotter: '9M2.*'  # Only Malaysian spotters
```

### Complex Filter Examples

**DXCC Chasing**:
```yaml
filters:
  - and:
      - bands: ['20m', '15m', '10m']
      - modes: ['SSB']
      - dxcc: [257, 246, 406]  # Rare entities
```

**Contest Mode**:
```yaml
filters:
  - or:
      - comment_contains: 'CONTEST'
      - comment_contains: 'CQ TEST'
      - comment_contains: 'CQ WPX'
      - comment_contains: 'CQ WW'
```

**6m Sporadic E**:
```yaml
filters:
  - and:
      - bands: ['6m']
      - freq_min: 50000
        freq_max: 54000
```

## Rate Limiting

### Global Rate Limit

Configured in `notifications.yml`:
```yaml
rate_limit:
  max_per_minute: 60  # Total across all adapters
```

### Adapter-Specific Limits

- **Discord**: 5 requests per 5 seconds (per webhook)
- **Telegram**: 20 messages per second (conservative limit)
- **Webhook**: Configurable retry with exponential backoff

## Troubleshooting

### Enable Debug Logging

Check DXSpider logs for notification activity:
```bash
docker compose logs -f | grep notify
```

### Test Configuration

```perl
# Test from Perl
use lib '/spider/notifications/lib';
use Notify;

# Load config
my $result = Notify::init('/spider/notifications/config/notifications.yml');
print "Enabled: $Notify::enabled\n";

# Test spot
my $spot = {
    freq => 14074,
    call => 'K1ABC',
    time => time(),
    comment => 'CQ NA FT8',
    spotter => 'W1XYZ',
    band => '20m',
    mode => 'FT8',
};

Notify::dispatch($spot);
```

### Common Issues

**No notifications sent**:
- Check `enabled: true` in config
- Verify environment variables are set
- Check filter configuration (too restrictive?)
- Review logs for errors

**Rate limiting errors**:
- Reduce `max_per_minute` in config
- Use more restrictive filters
- Spread notifications across multiple adapters

**Discord errors**:
- Verify webhook URL is correct
- Check webhook hasn't been deleted
- Ensure bot has channel permissions

**Telegram errors**:
- Verify bot token is valid
- Check chat ID is correct (including `-100` prefix for channels)
- Ensure bot is member of channel/group

## Module Reference

### Notify.pm

Main dispatcher module.

**Methods**:
- `Notify::init($config_file)` - Initialize from YAML config
- `Notify::dispatch(\@spot)` - Dispatch spot to adapters
- `Notify::reload()` - Reload configuration
- `Notify::stats()` - Get statistics

### Notify::Filter

Filter engine for spot matching.

**Methods**:
- `new(\@filters)` - Create filter engine
- `matches($spot)` - Check if spot matches filters
- `apply_filter($spot, $filter)` - Apply single filter

### Notify::Discord

Discord webhook adapter.

**Methods**:
- `new(\%config)` - Create adapter
- `should_notify($spot)` - Check filters
- `send($spot)` - Send notification

### Notify::Telegram

Telegram bot adapter.

**Methods**:
- `new(\%config)` - Create adapter
- `should_notify($spot)` - Check filters
- `send($spot)` - Send notification

### Notify::Webhook

Generic HTTP webhook adapter.

**Methods**:
- `new(\%config)` - Create adapter
- `should_notify($spot)` - Check filters
- `send($spot)` - Send notification

## Security Considerations

1. **Never commit credentials** - Use environment variables
2. **Restrict webhook URLs** - Keep URLs secret (they grant access)
3. **Use HTTPS** - All adapters default to HTTPS
4. **Rate limiting** - Prevents abuse and API bans
5. **Input validation** - All user data is sanitized

## Performance

- **Non-blocking**: Notification dispatch doesn't block spot processing
- **Rate limiting**: Prevents overwhelming external services
- **Efficient filtering**: Filters applied before network requests
- **Caching**: Environment variable expansion cached

## Contributing

See main project CONTRIBUTING.md for guidelines.

## License

See main project LICENSE file.

## Support

- GitHub Issues: https://github.com/9M2PJU/9M2PJU-DXSpider-Docker/issues
- Discord: [Your Discord invite]
- Email: [Your email]

## Credits

Created by the 9M2PJU-DXSpider-Docker Project team.

Based on DXSpider by Dirk Koopman G1TLH.
