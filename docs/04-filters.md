# Filters

Filters control what information you receive from the cluster. You can filter DX spots, announcements, WWV (solar) data, and WCY data based on various criteria like frequency, callsign, band, country, etc.

---

## How Filters Work

DXSpider uses an **accept/reject** model:

- **Accept filters** — If a spot matches an accept filter line, it IS passed to you.
- **Reject filters** — If a spot matches a reject filter line, it is NOT passed to you.

Filter lines are numbered (0-9). They are evaluated in order. The first matching line wins. If no lines match, the default behavior depends on the filter type.

### Filter Types

| Filter Type | Controls |
| :--- | :--- |
| `spot` | DX spots (frequency, callsign, band, etc.) |
| `announce` | Announcements (ANN/FULL, ANN/LOCAL) |
| `wwv` | WWV solar/geomagnetic reports |
| `wcy` | WCY geomagnetic reports |
| `route` | PC protocol routing (sysop only) |

---

## Spot Filters

Spot filters are the most commonly used. They control which DX spots you see.

### Accept Filter Examples

Show only spots on the 20-meter band:
```
accept/spot freq 14000-14350
```

Show only spots from a specific callsign:
```
accept/spot call ZL2ABC
```

Show only spots from Oceania:
```
accept/spot zone itu 28-32
```

Show only spots on HF bands:
```
accept/spot freq hf
```

Show only spots by callsigns starting with "ZL":
```
accept/spot call ZL*
```

### Reject Filter Examples

Reject spots on WARC bands (12m, 17m, 30m):
```
reject/spot freq 24890-25070
reject/spot freq 18068-18168
reject/spot freq 10100-10150
```

Reject spots from a specific spotter:
```
reject/spot by BADSPOTTER
```

Reject spots containing certain words:
```
reject/spot info *test*
```

### Available Spot Filter Fields

| Field | Description | Example |
| :--- | :--- | :--- |
| `freq <range>` | Frequency in kHz | `freq 14000-14350` |
| `freq <band>` | Named band | `freq 20m` or `freq hf` |
| `call <pattern>` | DX station callsign | `call ZL*` |
| `by <pattern>` | Spotter's callsign | `by G1*` |
| `info <pattern>` | Comment text | `info *CW*` |
| `zone itu <n>` | ITU zone | `zone itu 28` |
| `zone cq <n>` | CQ zone | `zone cq 28` |
| `state <code>` | US state | `state CA` |
| `dxcc <prefix>` | DXCC country | `dxcc ZL` |
| `origin <pattern>` | Originating node | `origin GB7*` |
| `channel <pattern>` | Channel callsign | `channel GB7MBC` |

### Band Names

You can use named bands instead of frequency ranges:

| Name | Range (kHz) |
| :--- | :--- |
| `160m` | 1800-2000 |
| `80m` | 3500-4000 |
| `40m` | 7000-7300 |
| `30m` | 10100-10150 |
| `20m` | 14000-14350 |
| `17m` | 18068-18168 |
| `15m` | 21000-21450 |
| `12m` | 24890-24990 |
| `10m` | 28000-29700 |
| `6m` | 50000-54000 |
| `2m` | 144000-148000 |
| `70cm` | 430000-440000 |
| `hf` | All HF bands |
| `vhf` | All VHF bands |
| `uhf` | All UHF bands |

Use `show/bands` to see the full list of band names available.

---

## Announce Filters

Announce filters control which announcements you see.

### Examples

Accept announcements only from specific callsigns:
```
accept/ann call 9M2PJU
```

Reject announcements containing certain words:
```
reject/ann info *test*
```

### Available Announce Filter Fields

| Field | Description | Example |
| :--- | :--- | :--- |
| `call <pattern>` | Announcer's callsign | `call G1*` |
| `info <pattern>` | Announcement text | `info *meeting*` |
| `origin <pattern>` | Originating node | `origin GB7*` |

---

## WWV and WCY Filters

WWV (solar data) and WCY (geomagnetic data) filters work similarly.

### Examples

Accept WWV only from US stations:
```
accept/wwv call K*
```

Reject all WCY:
```
reject/wcy all
```

> [!TIP]
> If you don't want WWV or WCY at all, it's simpler to use `unset/wwv` and `unset/wcy` rather than creating reject filters.

---

## Managing Filters

### View Your Filters

```
show/filter
```

This displays all filter lines you have set.

### Clear Filter Lines

Clear a specific line:
```
clear/spot 0
```

Clear all spot filter lines:
```
clear/spot all
```

Clear all announce filter lines:
```
clear/ann all
```

---

## Sysop Filters (Setting Filters for Other Users)

As sysop (privilege level 8+), you can set filters for other users or for all users by default.

### Set a Filter for a Specific User

```
accept/spot ZL2ABC freq 14000-14350
```

### Set a Default Filter for All Users

```
accept/spot default freq hf
```

### Set an Input Filter (Inbound from a Node)

```
accept/spot gb7mbc input freq hf
```

This filters spots coming IN from the GB7MBC node before they enter your cluster.

---

## Filter Tips for Beginners

1. **Start simple** — Don't create complex filters right away. Just use `sh/dx` and `sh/dx 20m` to see what you want.

2. **Use reject for noise** — If you're getting too much noise on a band, reject it:
   ```
   reject/spot freq 28000-29700
   ```

3. **Use accept for focus** — If you only care about one band:
   ```
   clear/spot all
   accept/spot freq 14000-14350
   ```

4. **Check your filters** — Always run `show/filter` after making changes to verify.

5. **Filters are per-user** — Each user has their own filters. Setting a filter as one user doesn't affect others.

6. **Filters persist** — Your filters are saved in your user profile and restored on next login.

---

## Advanced: Filter File Locations

DXSpider stores filter scripts in a directory tree:

```
/spider/filter/
├── spots/          # Spot filters
│   ├── default.pl  # Default for all users
│   ├── ZL2ABC.pl   # Filter for ZL2ABC
│   └── ...
├── ann/            # Announce filters
├── wwv/            # WWV filters
├── wcy/            # WCY filters
└── route/          # Route filters (sysop)
```

You normally don't need to touch these files directly — use the `accept`/`reject`/`clear` commands instead. But if you want to edit them manually, they are Perl scripts that return 0 (accept) or 1 (reject).
