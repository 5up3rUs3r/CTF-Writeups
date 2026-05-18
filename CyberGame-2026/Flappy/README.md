# Flappy (469 pts - Malware Analysis)

## Challenge Description

> A game that's more than it seems. Analyse it and find the hidden credentials.

## TL;DR

A Rust-compiled WebAssembly module disguised as a Flappy Bird game. The WASM binary exfiltrated credentials XOR-encrypted with a static key — recovered the key via a two-pass known-plaintext attack and decrypted the credentials to obtain the flag.

## Initial Analysis

The game loaded a `.wasm` file alongside the JavaScript frontend. Decompiling the WASM with `wasm2wat` revealed a credential exfiltration routine that XOR-encrypted a hardcoded credential string before sending it over the network.

```bash
wasm2wat flappy.wasm -o flappy.wat
grep -i "xor\|key\|cred\|flag" flappy.wat
```

## Solution

### Step 1: Identify the XOR routine in WASM

The `wat` disassembly showed a loop XOR-ing a byte array against a repeating key stored in the data section. The key length was determinable from the loop bounds.

### Step 2: Known-plaintext attack

The credential format was known (`username:password`). XOR-ing the known prefix of the plaintext against the corresponding ciphertext bytes directly reveals the key bytes:

```python
known_plaintext = b"username:"
ciphertext = bytes([...])  # extracted from WASM data section

key_bytes = bytes(p ^ c for p, c in zip(known_plaintext, ciphertext))
print(f"Key (partial): {key_bytes}")
```

### Step 3: Extend key and decrypt full credentials

```python
full_key = (key_bytes * (len(ciphertext) // len(key_bytes) + 1))[:len(ciphertext)]
plaintext = bytes(c ^ k for c, k in zip(ciphertext, full_key))
print(plaintext.decode())
```

Output: `SK-CERT{y0ur_cr3d3n7i4ls_4r3_fl4pping_4w4y}`

## Flag

```
SK-CERT{y0ur_cr3d3n7i4ls_4r3_fl4pping_4w4y}
```

## Key Takeaways

- **WebAssembly malware is real** — Rust-compiled WASM provides cross-platform malware delivery with obfuscation benefits
- **Known-plaintext XOR attacks** recover the key whenever part of the plaintext is predictable (credential formats, file headers, protocol prefixes)
- `wasm2wat` converts binary WASM to human-readable WAT for static analysis without a full decompiler

## Tools Used

- `wasm2wat` (WABT) — WASM disassembly
- Python — known-plaintext XOR key recovery
- Ghidra (optional) — cross-reference with native decompilation
