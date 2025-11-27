# Quick Start Guide - DXSpider Notifications

Get notifications running in 5 minutes!

## Prerequisites

- Docker and docker-compose installed
- Discord/Telegram account (for notifications)
- DXSpider container running

## Step 1: Get Your Credentials

### For Discord:

1. Open Discord, go to your server
2. Open channel settings
3. Go to Integrations → Webhooks
4. Click "New Webhook"
5. Copy the webhook URL

### For Telegram:

1. Message @BotFather on Telegram
2. Send: `/newbot`
3. Follow prompts, save the bot token
4. Message @userinfobot to get your chat ID
5. Or add bot to channel and use channel ID (format: `-1001234567890`)

## Step 2: Configure Environment Variables

Edit your `.env` file and add:

```bash
# Discord
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE

# Telegram
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=123456789  # or -1001234567890 for channels
```

## Step 3: Create Configuration

```bash
cd /home/user/9M2PJU-DXSpider-Docker
cp notifications/config/notifications.yml.example notifications/config/notifications.yml
```

Edit `notifications/config/notifications.yml`:

**Minimal Discord Setup**:
```yaml
enabled: true

rate_limit:
  max_per_minute: 60

adapters:
  - type: discord
    name: "DX Spots"
    enabled: true
    webhook_url: "${DISCORD_WEBHOOK_URL}"
    color_scheme: "band"
    filters:
      - bands: ['20m', '40m', '15m']  # Only these bands
```

**Minimal Telegram Setup**:
```yaml
enabled: true

rate_limit:
  max_per_minute: 60

adapters:
  - type: telegram
    name: "DX Alerts"
    enabled: true
    bot_token: "${TELEGRAM_BOT_TOKEN}"
    chat_id: "${TELEGRAM_CHAT_ID}"
    parse_mode: "Markdown"
    filters:
      - bands: ['20m', '40m']  # Only these bands
```

## Step 4: Update docker-compose.yml

Add the notifications volume mount:

```yaml
services:
  dxspider:
    volumes:
      # ... existing volumes ...
      - ./notifications:/spider/notifications:ro
```

## Step 5: Update entrypoint.sh

Add this before starting DXSpider (around line 120, before the `exec` command):

```bash
# Install required Perl modules
apk add --no-cache perl-yaml-libyaml perl-http-tiny perl-json perl-uri 2>/dev/null || true

# Initialize notification system
cat > /spider/local/Notify_init.pl <<'NOTIFY_INIT'
#!/usr/bin/perl
use lib '/spider/notifications/lib';

eval {
    require Notify;
    if (-f '/spider/notifications/config/notifications.yml') {
        Notify::init('/spider/notifications/config/notifications.yml');
    }
};
1;
NOTIFY_INIT

chmod +x /spider/local/Notify_init.pl

# Load in DXVars
echo "" >> /spider/local/DXVars.pm
echo "# Load notification system" >> /spider/local/DXVars.pm
echo "do '/spider/local/Notify_init.pl';" >> /spider/local/DXVars.pm
echo "1;" >> /spider/local/DXVars.pm
```

## Step 6: Update cmd/dx.pl

**IMPORTANT**: This modifies the DX command to send notifications.

Find line 186 in `cmd/dx.pl` (after `Spot::add(@spot);`):

```perl
# store in spots database
Spot::add(@spot);
DXProt::send_dx_spot($self, $spot, @spot);
```

Change to:

```perl
# store in spots database
Spot::add(@spot);

# Dispatch to notification system
eval {
    require Notify;
    Notify::dispatch(\@spot) if $Notify::enabled;
};

DXProt::send_dx_spot($self, $spot, @spot);
```

## Step 7: Rebuild Container

```bash
docker compose down
docker compose up -d --build
```

## Step 8: Test It!

Watch the logs:
```bash
docker compose logs -f | grep -i notify
```

Connect to your cluster:
```bash
telnet localhost 7300
```

Post a test spot (after logging in):
```
dx 14074.0 K1ABC FT8 Test spot
```

Check Discord/Telegram for the notification!

## Troubleshooting

### No notifications?

1. **Check logs**:
   ```bash
   docker compose logs | grep notify
   ```

2. **Verify config loaded**:
   You should see: `Notification system initialized`

3. **Check filters**:
   Your test spot must match the band/mode filters you configured

4. **Test manually**:
   ```bash
   docker compose exec dxspider perl /spider/notifications/test_notify.pl
   ```

### Module errors?

Make sure Perl modules are installed:
```bash
docker compose exec dxspider apk add perl-yaml-libyaml perl-http-tiny perl-json perl-uri
docker compose restart
```

### Discord not working?

- Verify webhook URL is correct
- Check webhook hasn't been deleted in Discord
- Try posting in Discord to verify channel is accessible

### Telegram not working?

- Verify bot token is correct
- Check chat ID is correct (include `-100` prefix for channels)
- Make sure bot is added to channel/group

## What's Next?

- **Add more filters**: See [notifications.yml.example](config/notifications.yml.example)
- **Multiple adapters**: Configure Discord AND Telegram
- **Advanced filters**: DXCC, callsign patterns, modes
- **Custom webhooks**: Integrate with your own services

## Common Filter Examples

**HF Digital Modes Only**:
```yaml
filters:
  - and:
      - bands: ['20m', '40m', '15m', '10m']
      - modes: ['FT8', 'FT4', 'RTTY']
```

**Rare DX**:
```yaml
filters:
  - dxcc: [257, 246, 406]  # VP8, FT5, 3Y
  - callsign: 'VP8.*'
  - callsign: 'FT.*'
```

**POTA/SOTA Only**:
```yaml
filters:
  - comment_contains: 'POTA'
  - comment_contains: 'SOTA'
```

**6m Openings**:
```yaml
filters:
  - bands: ['6m']
```

## Need Help?

- Read [README.md](README.md) for full documentation
- Check [INTEGRATION.md](INTEGRATION.md) for detailed setup
- Review [notifications.yml.example](config/notifications.yml.example) for examples
- Ask in GitHub Issues

## Pro Tips

1. **Start restrictive**: Use specific band filters to avoid notification spam
2. **Test first**: Use `test_notify.pl` before going live
3. **Monitor logs**: Watch for errors in the first few hours
4. **Multiple channels**: Use different Discord channels for different filters
5. **Rate limiting**: Keep `max_per_minute` reasonable (30-60)

Enjoy your DX notifications! 73 🎉
