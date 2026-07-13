# User Commands Reference

This is a comprehensive reference of DXSpider commands available to users and sysops. Commands are organized by category.

---

## Privilege Levels

DXSpider uses privilege levels to control who can run which commands:

| Level | Role | What They Can Do |
| :--- | :--- | :--- |
| 0 | User | Basic commands: spot, show, set personal info, send messages |
| 1 | Remote User | Same as user, but connected from a remote node |
| 5 | Sysop | Manage connections, nodes, announcements to sysops |
| 8 | Remote Sysop | Set filters for users, manage hop counts |
| 9 | Console | Full admin: create/delete users, reload config, shutdown |

You gain sysop privileges by logging in with your sysop callsign (set via `CLUSTER_SYSOP_CALLSIGN`). If you log in remotely and need privileges, type `sysop` and enter your password.

---

## DX Spot Commands

### Posting a Spot

```
dx <frequency> <callsign> <comments>
```

Examples:
```
dx 14.195 ZL2ABC Strong signal on 20m CW
dx 7.090 VK9XYZ New DXCC on 40m SSB
dx by G1TLH 14.025 ZL2ABC Nice CW signal
```

The `by` variant lets you post a spot on behalf of another operator.

> [!NOTE]
> If `$main::reqreg = 1` is set (default in this project), you must be registered before you can post spots. The sysop can register you with `set/register YOURCALL`.

### Viewing Spots

| Command | Description |
| :--- | :--- |
| `sh/dx` | Show recent DX spots |
| `sh/dx 20` | Show last 20 spots |
| `sh/dx 20m` | Show recent spots on the 20m band |
| `sh/dx on 14` | Show spots on frequencies starting with 14 |
| `sh/dx by ZL*` | Show spots spotted by ZL callsigns |
| `sh/dx info *CW*` | Show spots containing "CW" in comments |
| `sh/dx dxcc ZL` | Show spots from New Zealand |
| `sh/dx zone itu 28` | Show spots in ITU zone 28 |
| `sh/dx zone cq 28` | Show spots in CQ zone 28 |
| `sh/dx state CA` | Show spots from US state California |
| `sh/dx iota` | Show IOTA-related spots |
| `sh/dx qra OJ03` | Show spots near grid square OJ03 |
| `sh/dx day 30` | Show spots from the last 30 days |
| `sh/fdx` | Show DX data in realtime format |
| `sh/mydx` | Show DX data filtered with your spot filter |

### Spot Statistics

| Command | Description |
| :--- | :--- |
| `sh/dxstats` | Show DX statistics |
| `sh/hfstats` | Show HF DX statistics |
| `sh/vhfstats` | Show VHF DX statistics |
| `sh/hftable` | Show HF DX spotter table |
| `sh/vhftable` | Show VHF DX spotter table |

---

## Announcement Commands

```
announce <text>              # Local announcement only
announce full <text>         # Cluster-wide announcement
announce sysop <text>        # Sysops only (privilege 5+)
```

Examples:
```
ann 73 to all and good DX
ann full QSO party this weekend on 20m
ann sysop Rebooting node in 10 minutes
```

View announcements:
```
sh/ann               # Show recent announcements
sh/ann 20            # Show last 20 announcements
sh/ann <from>-<to>   # Show range of announcements
```

---

## Talk (Private Messages)

Send a one-line message to another station:
```
talk G1TLH Hi Dirk, how are you?
talk ZL2ABC > GB7DJK Hi via GB7DJK
```

View talk history:
```
sh/talk
sh/talk 20
```

---

## Message System (Bulletins and Personal Mail)

### Sending Messages

```
send <call>                  # Send a message (interactive)
send private <call>          # Send a personal message
send noprivate <call>        # Send a bulletin (public)
send rr <call>               # Send with read receipt request
send copy <msgno> <call>     # Send a copy of an existing message
```

After typing `send`, you'll be prompted for a subject and body. End the message with `/EX` (send) or `/ABORT` (cancel).

### Reading Messages

```
read                         # Read next unread personal message
read <msgno>                 # Read a specific message by number
```

### Listing Messages

```
directory                    # List recent messages
dir all                      # List all messages
dir own                      # List your own messages
dir new                      # List all new (unread) messages
dir to <call>                # List messages addressed to <call>
dir from <call>              # List messages from <call>
dir subject <string>         # List messages with <string> in subject
dir 20                       # List last 20 messages
dir 100-200                  # List messages 100 through 200
```

### Replying to Messages

```
reply                        # Reply to the last message you read
reply <msgno>                # Reply to a specific message
reply b <msgno>              # Reply as a bulletin (public)
reply rr <msgno>             # Reply with read receipt request
reply noprivate <msgno>      # Reply as a bulletin
```

### Deleting Messages

```
kill <msgno>                 # Delete a message
kill <from>-<to>             # Delete a range of messages
kill from <call>             # Delete all messages from <call>
kill to <call>               # Delete all messages to <call>
kill full <msgno>            # Delete from the entire cluster (sysop)
kill expunge <msgno>         # Permanently expunge a message
```

### Message Management (Sysop)

```
msg <cmd> <msgno> [data]     # Alter message parameters
msg to <msgno> <call>        # Change recipient
msg subject <msgno> <text>   # Change subject
msg private <msgno>          # Mark as private
msg noprivate <msgno>        # Mark as bulletin
msg keep <msgno>             # Prevent auto-deletion
msg nokeep <msgno>           # Allow auto-deletion
msg queue                    # Show queued messages
```

---

## User Settings Commands

### Personal Information

```
set/name <your name>         # Set your name
set/qth <your qth>           # Set your QTH
set/location <lat> <long>    # Set your latitude/longitude
set/qra <locator>            # Set your Maidenhead grid square
set/homenode <node>          # Set your home cluster node
set/email <email>            # Set email (forwards personal messages)
set/address <address>        # Set your postal address
set/password                # Set your password
set/prompt <string>          # Set a custom prompt
set/language <lang>          # Set language (en, de, es, fr)
```

### Display Preferences

```
set/dx                       # Show DX spots (default: on)
unset/dx                     # Hide DX spots
set/announce                 # Show announcements (default: on)
unset/announce               # Hide announcements
set/talk                     # Show talk messages (default: on)
unset/talk                   # Hide talk messages
set/wwv                      # Show WWV solar data
unset/wwv                    # Hide WWV
set/wcy                      # Show WCY geomagnetic data
unset/wcy                    # Hide WCY
set/wx                       # Show weather messages
unset/wx                     # Hide weather
set/beep                     # Add beep to DX/other messages
unset/beep                   # Remove beep
set/echo                     # Echo your input
unset/echo                   # Don't echo input
set/logininfo                # Notify when users log in/out
unset/logininfo              # Don't notify
set/page <lines>             # Set lines per page (pagination)
set/here                     # Mark yourself as present
unset/here                   # Mark yourself as away
```

### DX Display Options

```
set/dxcq                     # Show CQ zones on DX spots
unset/dxcq                   # Hide CQ zones
set/dxitu                    # Show ITU zones on DX spots
unset/dxitu                  # Hide ITU zones
set/dxgrid                   # Show grid squares on DX spots
unset/dxgrid                 # Hide grid squares
set/usstate                  # Show US state info on DX spots
unset/usstate                # Hide US state info
```

### Buddy List

```
set/buddy <call>             # Add a callsign to your buddy list
unset/buddy <call>           # Remove a callsign
sh/buddy                     # Show your buddy list
```

### Startup Script (Per-User)

```
set/startup                  # Create your startup script (runs on login)
unset/startup                # Remove your startup script
sh/startup                   # View your startup script
```

---

## Show Commands (Information)

### Cluster Information

| Command | Description |
| :--- | :--- |
| `sh/configuration` | Show all nodes and users visible on the network |
| `sh/c` | Abbreviation for show/configuration |
| `sh/configuration/node` | Show all nodes connected locally |
| `sh/newconfiguration` | Show the cluster map (modern format) |
| `links` | Show which nodes are physically connected |
| `who` | Show who is physically connected to your node |
| `sh/node` | Show type and version of connected nodes |
| `sh/connect` | Show all active connections (sysop) |
| `sh/version` | Show DXSpider version |

### Station Information

| Command | Description |
| :--- | :--- |
| `sh/station` | Show info about a callsign |
| `sh/station all` | Show all users in the system |
| `sh/station <call>` | Show info about a specific callsign |
| `sh/registered` | Show registered users (sysop) |
| `sh/users` | Show user count |

### Propagation & Astronomy

| Command | Description |
| :--- | :--- |
| `sh/sun` | Show sun rise/set times |
| `sh/moon` | Show moon rise/set times |
| `sh/grayline` | Show civil dawn/dusk times (grayline map) |
| `sh/muf <prefix>` | Show MUF propagation prediction to a prefix |
| `sh/wwv` | Show last 10 WWV solar broadcasts |
| `sh/wwv <n>` | Show last <n> WWV broadcasts |
| `sh/wcy` | Show last 10 WCY broadcasts |
| `sh/wcy <n>` | Show last <n> WCY broadcasts |

### Time & Date

| Command | Description |
| :--- | :--- |
| `sh/time` | Show local time at your QTH |
| `sh/time <prefix>` | Show local time at a prefix/callsign |
| `sh/date` | Show local date |
| `sh/date <prefix>` | Show date at a prefix/callsign |

### QSL Information

| Command | Description |
| :--- | :--- |
| `sh/dxqsl <call>` | Show QSL info gathered from spots |
| `sh/qrz <call>` | Show callbook details |
| `sh/ik3qar <call>` | QSL info from IK3QAR database |
| `sh/db0sdx <call>` | QSL info from DB0SDX database |
| `sh/wm7d <call>` | Callbook details for US callsigns |

### Database Commands

| Command | Description |
| :--- | :--- |
| `dbavail` | Show list of all databases in the system |
| `dbshow <dbname> <key>` | Display an entry in a database |

---

## Filter Commands

See the [Filters Guide](04-filters.md) for a detailed explanation.

```
accept/spot [0-9] <pattern>     # Accept spot filter line
reject/spot [0-9] <pattern>     # Reject spot filter line
clear/spot [0-9|all]            # Clear spot filter line(s)
accept/ann [0-9] <pattern>      # Accept announce filter
reject/ann [0-9] <pattern>      # Reject announce filter
clear/ann [0-9|all]             # Clear announce filter(s)
show/filter                      # Show all your filters
```

---

## Chat / Conference Groups

```
join <group>                  # Join a chat group
leave <group>                 # Leave a chat group
chat <group> <text>           # Send a message to a group
sh/chat                       # Show recent chat messages
sh/chat <group>               # Show chat for a specific group
```

---

## Weather

```
wx <text>                     # Send weather message to local users
wx full <text>                # Send weather to all cluster users
wx sysop <text>               # Send weather to other clusters only
```

---

## Sysop Commands

### User Management

```
set/register <call>           # Mark a user as registered
unset/register <call>         # Mark a user as not registered
set/privilege <n> <call>      # Set privilege level (0-9)
set/password <call> <pass>    # Set a user's password
unset/password <call>         # Remove a user's password
set/lockout <call>            # Block a callsign from connecting
unset/lockout <call>          # Allow a callsign to connect
create/user <call>            # Create a user manually
delete/user <call>            # Delete a user from the database
set/regpass <call> <pass>     # Register + set password (combined)
unset/regpass <call>          # Unregister + remove password
```

### Node Management

```
set/spider <call>             # Mark as DXSpider node
set/node <call>               # Mark as AK1A cluster
set/clx <call>                # Mark as CLX cluster
set/arcluster <call>          # Mark as AR-Cluster
set/dxnet <call>              # Mark as DXNet
set/bbs <call>                # Mark as BBS
set/isolate                   # Isolate a node from the network
unset/isolate                 # Remove isolation
set/hops <call> spots <n>     # Set hop count for spots
set/hops <call> ann <n>       # Set hop count for announces
show/hops <call>              # Show hop counts for a node
set/maxconnect <n> <call>     # Set max incoming connections
set/pinginterval <n> <call>   # Set ping interval to a node
```

### Bad Lists (Spam Protection)

```
set/baddx <call>              # Block DX spots of this callsign
unset/baddx <call>            # Unblock
set/badspotter <call>         # Block spots from this spotter
unset/badspotter <call>       # Unblock
set/badnode <call>            # Block spots from this node
unset/badnode <call>          # Unblock
set/badword <word>            # Block spots containing this word
unset/badword <word>          # Unblock
set/badip <ip>                # Block connections from this IP
unset/badip <ip>              # Unblock
show/baddx                    # Show all bad DX calls
show/badspotter               # Show all bad spotters
show/badnode                  # Show all bad nodes
show/badword                  # Show all bad words
show/badip                    # Show all bad IPs
load/badwords                 # Reload bad words file
```

### Connection Management

```
connect <call>                # Connect to a node (uses connect/ script)
disconnect <call>             # Disconnect a user or node
init <node>                   # Re-initialize a link to AK1A node
ping <node>                   # Check link quality
rcmd <node> <cmd>             # Send a command to another cluster
merge <node>                  # Ask for latest spots and WWV from a node
```

### System Commands

```
load/forward                  # Reload message forwarding table
load/bands                    # Reload band limits table
load/prefixes                 # Reload prefix table
load/aliases                  # Reload command aliases
load/messages                 # Reload system messages
load/cmd_cache                # Reload command cache
debug                         # Toggle debug mode
show/debug                    # Show active debug levels
set/debug <name>              # Add a debug level
unset/debug <name>            # Remove a debug level
show/program                  # Show locations of program modules
show/log <call>               # Show system log excerpts
stat/user <call>              # Show full user status
stat/channel <call>           # Show channel status
stat/msg                      # Show message system status
stat/db <dbname>              # Show database status
export_users                  # Export user database to ASCII
shutdown                      # Shutdown the cluster (console only)
sysop                         # Regain privileges if logged in remotely
```

---

## Help Commands

```
help                          # Show general help
help <command>                # Show help for a specific command
apropos <string>              # Search help for a keyword
sh/bands                      # Show available band names
sh/motd                       # Show the Message of the Day
```

---

## Exiting

```
bye                           # Disconnect from the cluster
exit                          # Same as bye
quit                          # Same as bye
```

---

## Command Aliases

DXSpider supports command aliases. Common abbreviations:

| Alias | Full Command |
| :--- | :--- |
| `sh` | `show` |
| `ann` | `announce` |
| `dir` | `directory` |
| `acc` | `accept` |
| `rej` | `reject` |
| `c` | `connect` |
| `d` | `directory` |

You can create custom aliases in the `cmd/Aliases` file (sysop only). Reload with `load/aliases`.
