# File File Crocodile (Forensics)

## Challenge Description

> Never smile at a crocodile... especially a polyglot one.

**File:** `chall.png` (polyglot PNG/ZIP)  
**Flag Format:** `boroCTF{...}`

## TL;DR

A PNG file with an embedded ZIP archive. Three ZIP local file header magic bytes (`PK`) were corrupted to `FC` at offsets `0x00`, `0x8b`, and `0xd9`. Patching all three back to `PK` with Python restored the valid ZIP structure. Extracting with password `croc` yielded the flag.

## Initial Analysis

### Step 1: Detect the embedded archive

```bash
binwalk chall.png
```

`binwalk` reported a ZIP archive embedded within the PNG, confirming a polyglot file structure.

### Step 2: Inspect the corrupted signatures

```bash
xxd chall.png | head -30
```

Three locations showed `FC 4B` where `PK` (`50 4B`) was expected — the ZIP local file header and central directory signatures had been corrupted by replacing `P` (`0x50`) with `F` (`0x46`... wait, `FC` = `0x46 0x43`... actually `FC` as hex = `0xFC`).

Corrupted offsets within the file: `0x00`, `0x8b`, `0xd9`

## Solution

### Step 3: Patch the magic bytes

```python
data = bytearray(open('chall.png', 'rb').read())
for off in [0x00, 0x8b, 0xd9]:
    data[off]     = 0x50  # 'P'
    data[off + 1] = 0x4b  # 'K'
open('fixed.zip', 'wb').write(data)
```

### Step 4: Extract with the password

```bash
unzip -P croc fixed.zip
```

Password `croc` — hinted by the challenge name "crocodile" — successfully extracted the flag file.

## Flag

```
boroCTF{n3v3r_sm1l3_4t_4_p0lygl0t_cr0c0d1l3}
```

## Key Takeaways

- **`binwalk` spots embedded archives** — always run it on forensics files that don't open normally. Polyglots (files valid in two formats simultaneously) are a frequent CTF pattern.
- **ZIP magic bytes = `PK` (`0x50 0x4B`)** — any corruption of these two bytes breaks all standard ZIP tools. A Python `bytearray` patch restores them in seconds.
- **Password hints in challenge names** — "crocodile" → `croc`. When a ZIP is password-protected, try words from the challenge title and description before reaching for a wordlist.
- **Polyglot forensics mindset** — a file named `.png` that `binwalk` reports as containing a ZIP is both a PNG and a ZIP. Treat it as the format that matters for the challenge.

## Tools Used

- `binwalk` — embedded archive detection
- `xxd` — hex dump for magic byte inspection
- Python 3 (`bytearray`) — magic byte patching
- `unzip` — archive extraction with password
