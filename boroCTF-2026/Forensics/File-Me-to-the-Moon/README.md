# File Me to the Moon (Forensics)

## Challenge Description

> What's this file, really?

**File:** challenge file (misleading or absent extension)  
**Flag Format:** `boroCTF{...}`

## TL;DR

TODO — flag not recovered from session logs. The challenge required identifying the file's true type via magic bytes, then opening or parsing it correctly to extract the flag.

## Solution

### Step 1: Identify the true file type

```bash
file <challenge_file>
xxd <challenge_file> | head
```

The file extension was misleading. `file` (which reads magic bytes, not extensions) revealed the actual format. `xxd | head` showed the raw first bytes for manual confirmation.

Common magic byte signatures:

| Magic bytes | Format |
|-------------|--------|
| `PK` (`50 4B`) | ZIP archive |
| `%PDF` | PDF document |
| `\x7fELF` | ELF executable |
| `\x89PNG` | PNG image |
| `FF D8 FF` | JPEG image |
| `Rar!` (`52 61 72 21`) | RAR archive |

### Step 2: Parse as the correct type

Once the true format was identified from the magic bytes, the file was opened or parsed accordingly (renamed to the correct extension, extracted, or read with the appropriate tool) to reveal the flag.

## Flag

```
boroCTF{...}
```

> **Note:** Flag not captured in session logs.

## Key Takeaways

- **Magic bytes don't lie** — file extensions are metadata and can be changed to anything. The first bytes of the file content always identify its true format.
- **`file` is the fastest oracle** — it reads magic bytes automatically and reports the format; `xxd | head` gives you the raw bytes if you want to verify manually.
- **Rename and retry** — once the true format is known, simply renaming the file (e.g., `.jpg` → `.zip`) lets standard tools handle it.

## Tools Used

- `file` — magic byte identification
- `xxd` — raw hex inspection
