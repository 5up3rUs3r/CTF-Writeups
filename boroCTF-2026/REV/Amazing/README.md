# Amazing (REV)

## Challenge Description

> Can you find your way out of this maze?

**File:** `challenge.py` (Python maze game, 100×100 grid)  
**Flag Format:** `boroCTF{...}`

## TL;DR

A Python maze game with a hidden LCG stream cipher (`rsa_encrypt`) that decrypts a hardcoded byte payload every turn using the player's position as the key. Brute-forcing all 10,000 grid positions found a valid marshal code object at `(91, 68)`. Inspecting `co_consts` without executing the bytecode revealed a base64-encoded flag.

## Initial Analysis

### Step 1: Read the source

`challenge.py` contained:
- A 100×100 maze, player starts at `(50, 50)`, moves via WASD
- A `hope()` function called every turn:

```python
mod = (player_pos[0] ^ (player_pos[1] + player_pos[1])) * player_pos[0]
# decrypts hardcoded byte sequence with rsa_encrypt() using mod as seed
# if result is valid marshal bytecode, loads and executes it
```

### Step 2: Understand the cipher

`rsa_encrypt()` — despite the name — is a Linear Congruential Generator (LCG) stream cipher:

```python
state = seed
for byte in data:
    state = (1103515245 * state + 12345) & 0xFFFFFFFF
    keystream_byte = (state >> 16) & 0xFF
    output.append(byte ^ keystream_byte)
```

XOR is self-inverse, so encryption and decryption are the same operation.

## Solution

### Step 3: Brute-force all 10,000 positions

```python
import marshal, types

# encrypted_payload loaded from challenge.py source

for r in range(100):
    for c in range(100):
        mod = (r ^ (c + c)) * r
        decrypted = rsa_encrypt(encrypted_payload, mod)

        # safety: only attempt unmarshal on valid code object magic bytes
        if decrypted[0] not in (0x63, 0xe3):
            continue

        try:
            obj = marshal.loads(bytes(decrypted))
            if isinstance(obj, types.CodeType):
                print(f"Valid code object at ({r}, {c}), mod={mod}")
        except Exception:
            continue
```

**First attempt failure:** Calling `fn()` directly on every candidate caused an OOM kill — garbage keys produce runaway malformed bytecode. The `decrypted[0] in {0x63, 0xe3}` guard (valid marshal code object type tags) filtered out all invalid positions safely.

**Result:** Valid code object found at `(91, 68)`, `mod = 19201`

### Step 4: Inspect co_consts without executing

Running the decoded bytecode caused a segfault (Python version mismatch). Inspecting the code object's constants instead:

```python
obj = marshal.loads(decrypted)
print(obj.co_consts)
# → (None, 'Ym9yb0NURntlczRAcGVfd0E1XzFuZXYhdGFibGV9', 1, 2, 3)
```

### Step 5: Base64 decode the constant

```bash
echo "Ym9yb0NURntlczRAcGVfd0E1XzFuZXYhdGFibGV9" | base64 -d
```

Byte-level verification with `xxd`:

```
62 6f 72 6f 43 54 46 7b 65 73 34 40 70 65 5f 77  boroCTF{es4@pe_w
41 35 5f 31 6e 65 76 21 74 61 62 6c 65 7d        A5_1nev!table}
```

## Flag

```
boroCTF{es4@pe_wA5_1nev!table}
```

## Key Takeaways

- **Misleading function names** — `rsa_encrypt` is an LCG XOR stream cipher, not RSA. Always read the implementation.
- **`marshal.loads()` safety** — unmarshal on arbitrary bytes can execute malicious bytecode or crash. Gate with magic byte checks (`0x63`/`0xe3`) before deserializing.
- **`co_consts` extraction** — inspecting a code object's constant pool without executing it is a safe path to flag extraction when the bytecode would crash.
- **LCG as stream cipher** — constants `1103515245` and `12345` are the standard glibc `rand()` LCG parameters, a common CTF cipher ingredient.

## Tools Used

- Python 3 — brute-force loop, LCG stream cipher reimplementation, `marshal` inspection
- `base64` — final flag decoding
- `xxd` — byte-level flag verification
