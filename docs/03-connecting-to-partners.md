# Connecting to Partner Nodes

To join the global DX Cluster network, your node needs to link to at least one other node. This is both a **technical** and **social** process — you need the other sysop's permission.

---

## How Inter-Node Links Work

DXSpider nodes connect to each other via telnet (TCP). When two nodes are linked:

1. **Spots propagate** — A spot posted on your node is forwarded to all connected partner nodes, and vice versa.
2. **Announcements propagate** — Announcements (ANN) are forwarded cluster-wide.
3. **Messages forward** — Bulletins and personal messages are routed between nodes.
4. **User lists sync** — Each node knows about users connected to all other nodes.

The link is directional in configuration but bidirectional in practice: you configure your node to "dial" the partner, and they configure theirs to accept your connection.

---

## Step 1: Coordinate with a Partner Sysop

> [!IMPORTANT]
> **You cannot simply connect to any node without permission.** Connecting without coordination can get your node banned from the network.

1. **Find a partner node** — Look for nearby nodes on the cluster map (use `show/configuration` on any existing cluster to see connected nodes).
2. **Contact the sysop** — Email or send a DX message to the sysop of the node you want to link with.
3. **Agree on a password** — This is **highly recommended**. A password prevents unauthorized nodes from spoofing your callsign and protects the network from spam.
4. **Exchange callsigns** — Confirm your node callsign and their node callsign.

---

## Step 2: Create a Connection Script

Connection scripts live in the `connect/` directory on your host. Each file is named after the partner node's callsign (lowercase).

### Example: Connecting to GB7MBC

Create a file at `connect/gb7mbc`:

```bash
# Connection timeout in seconds
timeout 60

# Connect via telnet to the partner's hostname and port
connect telnet gb7mbc.spud.org 7300

# Identify ourselves as a DXSpider client
client gb7mbc telnet

# Wait for 'login:' prompt, then send our callsign
'login:' 'YOURCALL-2'

# Send the agreed-upon password
'pass' 'mysecurepassword'
```

### Connection Script Fields

| Field | Description |
| :--- | :--- |
| `timeout <seconds>` | Maximum time to wait for the connection to establish. |
| `connect telnet <host> <port>` | Connect to the partner node via telnet. |
| `connect ax25 <call> ...` | Connect via AX.25 packet radio (requires AGWPE). |
| `client <call> telnet` | Identify as a telnet client to the partner. |
| `'login:' 'YOURCALL'` | Wait for the string `login:` then send your callsign. |
| `'pass' 'password'` | Wait for the `pass` prompt then send the password. |
| `# comment` | Comment line (ignored). |

### The Pattern: `'prompt' 'response'`

The connect script uses a simple pattern-matching system. Each line with two quoted strings means:
- **Wait** until the partner sends text matching the first string
- **Then send** the second string

This lets you handle multi-step login sequences:

```bash
'login:' 'YOURCALL-2'
'password:' 'mysecurepassword'
'last login' ''
```

---

## Step 3: Mark the Partner as a Node

Before connecting, tell DXSpider that the partner is a DXSpider-type node (not a user):

From the console (telnet or web):
```
set/spider gb7mbc
```

For other cluster software types:
```
set/node gb7mbc      # AK1A cluster
set/clx gb7mbc       # CLX cluster
set/arcluster gb7mbc # AR-Cluster
set/dxnet gb7mbc     # DXNet cluster
```

---

## Step 4: Connect

### Manual Connection (One-Time)

From the console:
```
connect gb7mbc
```

Or from the host shell:
```bash
docker compose exec dxspider sh -c '/spider/perl/connect gb7mbc'
```

### Automatic Connection (On Startup)

Edit the `startup` file on your host:

```bash
load/forward
set/spider gb7mbc
connect gb7mbc
```

The `connect` command runs every time the container starts, establishing the link automatically.

### Automatic Reconnection (Via Cron)

Edit `local_cmd/crontab` to reconnect if the link drops:

```bash
# Reconnect to GB7MBC every 10 minutes if not connected
0,10,20,30,40,50 * * * * start_connect('gb7mbc') unless connected('gb7mbc')
```

---

## Step 5: Verify the Connection

From the console:
```
links
```

This shows all physically connected nodes. You should see your partner.

To see the full network topology:
```
show/configuration
```

To check the route to a specific node:
```
show/route gb7mbc
```

To ping a node:
```
ping gb7mbc
```

---

## Message Forwarding

To forward bulletins and messages between linked nodes, you need a forwarding configuration. Create or edit `msg/forward.pl` on your host:

```perl
# Forward all bulletins to GB7MBC
$main::forwardfn = sub {
    my $self = shift;
    my $msg = shift;
    
    # Forward to GB7MBC
    return ('gb7mbc');
};
1;
```

After creating or editing this file, reload it from the console:
```
load/forward
```

---

## Multiple Partner Nodes

You can connect to multiple partners. Create one connection script per partner:

```
connect/
├── gb7mbc          # Connection script for GB7MBC
├── w3lpl           # Connection script for W3LPL
├── dx0spottedpony  # Connection script for DX0SPOTTEDPONY
└── .gitkeep
```

Mark each as a node and connect:
```
set/spider gb7mbc
set/spider w3lpl
connect gb7mbc
connect w3lpl
```

Add reconnection cron entries for each:
```bash
0,10,20,30,40,50 * * * * start_connect('gb7mbc') unless connected('gb7mbc')
0,10,20,30,40,50 * * * * start_connect('w3lpl') unless connected('w3lpl')
```

---

## Disconnecting from a Partner

To disconnect a specific node:
```
disconnect gb7mbc
```

To remove the connection script:
```bash
rm connect/gb7mbc
```

---

## Security Best Practices

1. **Always use a password** — Agree on a password with every partner. Without it, anyone could spoof your callsign.
2. **Only connect to trusted nodes** — A rogue partner node can inject bad spots or spam your network.
3. **Use `set/spider` (not `set/node`)** — For DXSpider partners, use `set/spider` to enable full PC protocol support.
4. **Monitor your links** — Use `links` and `show/configuration` regularly to verify your connections are healthy.
5. **Set hop counts** — Control how far spots propagate:
   ```
   set/hops gb7mbc spots 5
   set/hops gb7mbc ann 5
   ```

---

## Troubleshooting Partner Links

| Problem | Solution |
| :--- | :--- |
| `connect gb7mbc` does nothing | Check that `connect/gb7mbc` exists and is readable. Check the hostname/port in the script. |
| Connection drops immediately | Check the password. Check that the partner has configured their node to accept you. |
| `No connection script` error | The filename must be lowercase: `connect/gb7mbc`, not `connect/GB7MBC`. |
| Spots not propagating | Verify `set/spider gb7mbc` was run. Check hop counts with `show/hops gb7mbc`. |
| `already connected` message | The link is already up. Use `disconnect` first if you need to reconnect. |

See [Troubleshooting](10-troubleshooting.md) for more.
