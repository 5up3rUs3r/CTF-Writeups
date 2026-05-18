# Crypto Sanity Check - Layers of encoding (100 pts - Cryptography)

## Challenge Description

> Decode the ciphertext through its layers to find the flag.

## TL;DR

Three-layer encoding: decimal ASCII → hex string → base64 → plaintext flag.

## Initial Analysis

The ciphertext was a sequence of decimal numbers — not immediately recognisable as a standard encoding, but the "layers" hint signalled a chain of transformations.

## Solution

### Step 1: Decimal → ASCII → hex string

Each decimal number maps to its ASCII character, producing a hex string:

```python
decimals = [INPUT_SEQUENCE]
hex_str = ''.join(chr(d) for d in decimals)
```

### Step 2: Hex → raw bytes

```python
raw = bytes.fromhex(hex_str)
```

### Step 3: Base64 → flag

```python
import base64
flag = base64.b64decode(raw + b'==').decode()
print(flag)
```

On **CyberChef**: chain **From Decimal → From Hex → From Base64**.

## Flag

```
SK-CERT{l4y3r3d_lik3_4n_0ni0n}
```

## Key Takeaways

- **Multi-layer encoding** (dec → hex → base64) is a signature sanity check pattern — always work from the outside in
- CyberChef's "Magic" wand auto-detects encoding layers when you're unsure of the order
- The flag confirms the technique: layered like an onion

## Tools Used

- Python `base64`, `bytes.fromhex()` — layer decoding
- CyberChef — visual chain verification
