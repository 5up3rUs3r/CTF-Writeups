# s1xty_f0ur_b3auty (MISC)

## Challenge Description

> 64 pieces make a beautiful whole.

**File:** ZIP archive containing 64 chunk files  
**Flag Format:** `boroCTF{...}`

## TL;DR

TODO — flag not recovered from session logs. The ZIP contained 64 files with base64-encoded filenames that decoded to ordering indices. Each file's content was a single character padded with `"40"` separators. Stripping the padding, assembling chunks in order, and base64-decoding the result yielded the flag.

## Solution

### Step 1: Extract and inspect the ZIP

```bash
unzip challenge.zip -d extracted/
ls extracted/
```

64 files with base64-looking filenames and short contents.

### Step 2: Decode filenames to get ordering

The filenames were base64-encoded integers (1–64) indicating assembly order:

```python
import base64, os

files = os.listdir('extracted/')
ordered = sorted(files, key=lambda f: int(base64.b64decode(f).decode()))
```

### Step 3: Strip the "40" padding from each file's content

Each file contained a single character surrounded by `"40"` padding (decimal `40` = ASCII `@`):

```python
assembled = ''
for fname in ordered:
    content = open(f'extracted/{fname}').read()
    char = content.replace('40', '')
    assembled += char
```

### Step 4: Base64-decode the assembled string

```python
import base64
flag = base64.b64decode(assembled).decode()
print(flag)
```

## Flag

```
boroCTF{...}
```

> **Note:** Flag not captured in session logs.

## Key Takeaways

- **Filenames carry metadata** — base64-encoded ordering indices in filenames is a multi-layer puzzle: decode filename → get index → sort → strip content separators → decode payload.
- **`"40"` padding = decimal ASCII `@`** — padding with decimal ASCII values is mild obfuscation; once the pattern is spotted the stripping step is trivial.
- **Layer enumeration** — when a challenge has a number in the name ("64"), that number usually maps directly to a structural element (here: 64 files, each holding one chunk).

## Tools Used

- `unzip` — initial extraction
- Python 3 (`base64`, `os`) — filename decoding, chunk ordering, padding removal, final base64 decode
