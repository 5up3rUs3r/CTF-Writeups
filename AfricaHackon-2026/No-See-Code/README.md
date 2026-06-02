# No See Code (150 pts - Forensics/Steganography)

## Challenge Description

> What you see is not always what you get.

**File:** `no-see-code.zip` (password protected)  
**Difficulty:** Easy

## TL;DR

Password-protected zip cracked with `john` (password: `secret123`). The extracted file displayed a decoy flag. The real flag was hidden inside the decoy text using zero-width Unicode characters (U+200B, U+200C, U+200D) as an invisible binary steganography encoding.

## Initial Analysis

### Step 1: Crack the zip password

```bash
zip2john no-see-code.zip > hash.txt
john hash.txt --wordlist=/usr/share/wordlists/rockyou.txt
```

Password cracked: **`secret123`**

### Step 2: Extract and inspect

```bash
unzip -P secret123 no-see-code.zip
cat not_fl4g.txt
```

The file visibly displayed:

```
r00t{naah_not_the_flag}
```

The name of the file (`not_fl4g.txt`) and the challenge name ("No See Code") were both strong hints that there was more to this than met the eye.

## Solution

### Step 3: Detect hidden characters

Inspecting the file in a hex editor or with Python revealed zero-width Unicode characters interspersed invisibly between the visible characters:

- **U+200B** (Zero Width Space) → binary `1`
- **U+200C** (Zero Width Non-Joiner) → binary `0`
- **U+200D** (Zero Width Joiner) → byte separator

These characters are completely invisible in standard text editors and terminals, making them ideal for hiding data inside seemingly normal text.

### Step 4: Decode with Python

```python
text = open("not_fl4g.txt", encoding="utf-8").read()

ZWS  = "​"   # 1
ZWNJ = "‌"   # 0
ZWJ  = "‍"   # separator

# Extract only the zero-width characters
hidden = [c for c in text if c in (ZWS, ZWNJ, ZWJ)]

# Split into bytes at each ZWJ separator
byte_groups = "".join(
    "1" if c == ZWS else ("0" if c == ZWNJ else "|")
    for c in hidden
).split("|")

# Convert each 7-bit group to ASCII
flag = "".join(chr(int(b, 2)) for b in byte_groups if len(b) == 7)
print(flag)
```

Output: `r00t{H1dd3n_1n_Pl41n_S1ght}`

## Flag

```
r00t{H1dd3n_1n_Pl41n_S1ght}
```

## Key Takeaways

- **Zero-width Unicode steganography** — U+200B, U+200C, U+200D are invisible in rendered text but detectable via hex editor or Python string inspection. A classic technique for hiding data in plain sight.
- **Decoy flags are a genre** — a file named `not_fl4g.txt` containing a plausible-looking flag is an immediate red flag to inspect the raw bytes.
- **Always check beyond what's visible** — `xxd`, `hexdump`, or Python's `repr()` on a string will expose hidden characters that terminals swallow silently.
- **Encoding scheme here:** 200B=1, 200C=0, 200D=separator, 7-bit ASCII groups.

## Tools Used

- `zip2john` + `john` — zip password cracking
- `rockyou.txt` — wordlist
- Python — zero-width character extraction and binary decoding
- hex editor — initial hidden character detection
