# Survey (Misc)

## Challenge Description

> Fill out the post-competition survey to receive your flag!

**Category:** Misc  
**Flag Format:** `0ops{...}`

## TL;DR

Post-competition survey challenge. The flag was returned as a hex-encoded string in the survey response, requiring a simple hex decode to retrieve it.

## Solution

### Step 1: Complete the Survey

Navigate to the survey link provided on the CTF platform and fill out the post-competition feedback form.

### Step 2: Decode the Flag

The survey response returned a hex string:

```
306f70737b2465335f7930555f61545f7468335f304354465f32303236217d
```

### Step 3: Hex Decode

```bash
echo "306f70737b2465335f7930555f61545f7468335f304354465f32303236217d" | xxd -r -p
```

Or in Python:

```python
bytes.fromhex("306f70737b2465335f7930555f61545f7468335f304354465f32303236217d").decode()
```

## Flag

```
0ops{$e3_y0U_aT_th3_0CTF_2026!}
```

_"See you at the 0CTF 2026!"_

## Key Takeaways

- Survey challenges are always free points — complete these first in any CTF
- The hex encoding of the flag was a small additional step typical of 0CTF's playful style

## Tools Used

- `xxd` — hex decoding
- Python `bytes.fromhex()`
