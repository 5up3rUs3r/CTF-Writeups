# Perfectly Destructive File (REV)

## Challenge Description

> This financial report seems perfectly normal. Nothing to see here.

**File:** `financial_report` (no extension)  
**Flag Format:** `boroCTF{...}`

## TL;DR

A PDF with FlateDecode-compressed streams. A decoy clickable button triggered an `app.alert` troll message. The real flag was a base64-encoded string inside a JavaScript variable buried in a separate compressed stream.

## Initial Analysis

### Step 1: Identify the file

```bash
file financial_report
# financial_report: PDF document, version 1.5
```

`cat` showed only compressed FlateDecode streams — unreadable without decompression.

### Step 2: Decompress all PDF streams

```python
import zlib, re

with open('financial_report', 'rb') as f:
    data = f.read()

streams = re.findall(b'stream\r?\n(.*?)\r?\nendstream', data, re.DOTALL)
for i, s in enumerate(streams):
    try:
        dec = zlib.decompress(s)
        print(f'--- Stream {i} ---')
        print(dec.decode('utf-8', errors='replace'))
    except Exception as e:
        print(f'Stream {i} failed: {e}')
```

## Solution

### Step 3: Analyse the decompressed content

Stream 0 decompressed to reveal the full PDF object structure.

**Decoy button widget:**

```
/MK << /CA (Click me for free flag!) >>
```

Button action:

```javascript
app.alert({cMsg:"Ya, I'm not making it that easy.", nIcon:3})
```

**Hidden JavaScript object in the same stream:**

```javascript
var encoded = "Ym9yb0NURnswbjFfRiFsZV9JNV9AMTFfaXRfdEFrZSR9";
```

### Step 4: Decode the flag

```bash
echo "Ym9yb0NURnswbjFfRiFsZV9JNV9AMTFfaXRfdEFrZSR9" | base64 -d
```

Output: `boroCTF{0n1_F!le_I5_@11_it_tAke$}`

## Flag

```
boroCTF{0n1_F!le_I5_@11_it_tAke$}
```

## Key Takeaways

- **PDFs are containers** — FlateDecode streams compress the real content. `file` confirms the format but `cat` is useless; always decompress.
- **Decoy interactions** — the "Click me for free flag!" button was intentional misdirection. Real payloads hide in non-interactive objects.
- **`zlib.decompress` covers most PDF streams** — PDF FlateDecode is raw zlib deflate; a short Python loop decompresses all streams in seconds.
- **Base64 in JS variables** — a common PDF/Office challenge pattern: flag stored as a base64 string in embedded JavaScript that never executes visually.

## Tools Used

- `file` — format identification
- Python 3 (`zlib`, `re`) — FlateDecode stream decompression
- `base64` — flag decoding
