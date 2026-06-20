# kitty kitty meow meow (Forensics)

## Challenge Description

> meow meow meow meow

**File:** JPEG image  
**Flag Format:** `boroCTF{...}`

## TL;DR

TODO — flag not recovered from session logs. The flag was embedded as a plaintext string in the JPEG file, found immediately with `strings | grep boroCTF`.

## Solution

### Step 1: Run strings and grep for the flag

```bash
strings <challenge_file>.jpg | grep boroCTF
```

The flag was embedded in the JPEG as a plaintext string and appeared directly in the `strings` output.

## Flag

```
boroCTF{...}
```

> **Note:** Flag not captured in session logs. The process above produced the flag directly.

## Key Takeaways

- **`strings` + `grep` is always the first step** for image forensics — plaintext flags embedded in file metadata or comment sections are common at lower difficulty tiers.
- If `strings` comes up empty, escalate to `exiftool` for EXIF metadata and `steghide`/`zsteg` for steganographic content.

## Tools Used

- `strings` — raw string extraction from binary file
- `grep` — flag pattern filtering
