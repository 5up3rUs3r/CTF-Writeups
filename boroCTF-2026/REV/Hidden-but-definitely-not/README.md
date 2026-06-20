# Hidden but definitely not (REV)

## Challenge Description

> The password is hidden but definitely not findable. Maybe.

**File:** `password_protected` (ELF 64-bit LSB pie executable, stripped)  
**Flag Format:** `boroCTF{...}`

## TL;DR

Stripped ELF that builds a password byte-by-byte on the stack and compares it with `strcmp`. `ltrace` exposed the plaintext password at runtime. On correct input, the binary XORs a hardcoded byte array with key `0x7` and prints the flag via `putchar`.

## Initial Analysis

### Step 1: File recon

```bash
ls -la
# password_protected — ELF 64-bit
file password_protected
# ELF 64-bit LSB pie executable, x86-64, stripped
strings password_protected | grep boroCTF
# (no output — flag not in plaintext)
```

`strings` came up empty for the flag, ruling out a trivial grep.

### Step 2: Load in radare2

```bash
r2 -A password_protected
```

Running `izz` (all strings) returned no flag but surfaced interesting fragments:
- `Rate5Stars` and `BecauseGreatChallenge` in `.text`
- Three rodata strings:
  - `"Give me the password (youll never find it it's just tooooo hard)"`
  - `"wow you really got me this time. if only i used better obfuscation techniques."`
  - `"My disappointment is immeasurable."`

The second string hints that correct input triggers output; the third signals wrong input.

### Step 3: Disassemble main

```
afl          # lists functions — main at 0x1229
pdf @ main   # disassemble main
```

The disassembly showed the password being constructed byte-by-byte onto the stack, followed by a `strcmp` call comparing the user's input against the assembled string.

## Solution

### Step 4: Extract the password with ltrace

```bash
ltrace ./password_protected
# (enter blank input at prompt)
# strcmp("", "Rate5StarsBecauseGreatChallenge") = -82
```

`ltrace` intercepted the `strcmp` call and revealed the full password in plaintext:

**Password:** `Rate5StarsBecauseGreatChallenge`

### Step 5: Understand the flag decryption

Reviewing the disassembly: on a correct password match, `main` enters a `putchar` loop that XORs each byte of a hardcoded byte array with key `0x7` and prints the results.

Hardcoded encrypted bytes:
```
0x65 0x68 0x75 0x68 0x44 0x53 0x41 0x7c 0x4e 0x58 0x4f 0x3f 0x58
0x4a 0x47 0x30 0x6e 0x69 0x60 0x58 0x54 0x73 0x55 0x36 0x69 0x60
0x32 0x58 0x64 0x4f 0x66 0x6b 0x74 0x7a
```

### Step 6: Decode the flag — two methods

**Method 1: Run the binary with the correct password**

```bash
echo "Rate5StarsBecauseGreatChallenge" | ./password_protected
```

**Method 2: Python XOR decode**

```python
enc = [
    0x65,0x68,0x75,0x68,0x44,0x53,0x41,0x7c,0x4e,0x58,0x4f,0x3f,0x58,
    0x4a,0x47,0x30,0x6e,0x69,0x60,0x58,0x54,0x73,0x55,0x36,0x69,0x60,
    0x32,0x58,0x64,0x4f,0x66,0x6b,0x74,0x7a
]
print(''.join(chr(b ^ 7) for b in enc))
```

Both produce the flag.

## Flag

```
boroCTF{I_H8_M@7ing_StR1ng5_cHals}
```

## Key Takeaways

- **`ltrace` is a stripped binary's weakness** — even without symbols, `ltrace` intercepts library calls like `strcmp` at runtime, exposing arguments in plaintext.
- **Byte-by-byte stack construction** — a common anti-`strings` technique. `strings` sees nothing; the dynamic tracer sees everything.
- **Simple XOR with a single-byte key** — key `0x7` is trivially recoverable from the ciphertext array in the disassembly.

## Tools Used

- `file`, `strings` — initial triage
- `r2` (radare2) — static analysis, `izz` string dump, `pdf @ main` disassembly
- `ltrace` — dynamic library call tracing (exposed `strcmp` argument)
- `python3` — XOR decryption verification
