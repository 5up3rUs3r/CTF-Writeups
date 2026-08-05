# Slipstream — Crypto (Medium, 200 pts, 10 solves) — NOT SOLVED

**Author:** DR programmer

## Description

"PerfectRoot seals every competition ticket with an in-house 'transport cipher.' They swear it is a one-time pad — *'the key never repeats, so it can never be broken.'* Every ticket starts with the same public preamble, though. The eel is fast, but it always leaves the same trail behind it."

Files: `preamble.txt` (512 bytes, known public plaintext), `ticket.json` (`{"block_size": 32, "ciphertext_hex": "..."}`, 608 bytes of ciphertext).

## What We Proved (High Confidence — Mathematically Verified)

The "OTP" is not actually random — it's a **32-byte-block Linear Congruential Generator**: `state_{i+1} = A·state_i + B (mod M)`, where each 32-byte ciphertext block XORs against one LCG output block treated as a 256-bit big-endian integer.

**Recovery:**
1. XOR the first 512 ciphertext bytes against the known preamble → 16 known keystream blocks (`s[0..15]`).
2. Recover the unknown modulus `M` via the standard technique for unknown-modulus LCGs: compute `t[i] = s[i+1]-s[i]`, then `M = gcd` over `t[i+2]·t[i] - t[i+1]²` for many `i`.
3. Solve for `A = t[1]·t[0]⁻¹ mod M` and `B = s[1] - A·s[0] mod M`.

**Verification (very strong):** these exact `A, B, M` satisfy the recurrence for **all 15** known transitions exactly — and, critically, **re-deriving `A, B` independently from the late block triple (13,14,15) instead of the early triple (0,1,2) gives bit-for-bit identical results.** This rules out coincidence.

**Extrapolation:** computing 3 more LCG states beyond `s[15]` and XORing against the remaining 96 ciphertext bytes (the "sealed" portion) produces **69 bytes of non-trivial content followed by exactly 27 clean `0x00` bytes**. The probability of 27 consecutive zero bytes appearing from a wrong keystream is ~(1/256)²⁷ — this is essentially proof the extrapolation is correct.

```
Recovered secret (69 meaningful bytes):
d76fc919856fa375aededb16462b7301fbdac224cc6d378a9e88848ea0f2ca5b5fd58a97b210bff
45aa1a2572027bae9fe42d80d5e1c6aa28748005a95504b274ad7984376
```

## Where We Got Stuck

**The final byte-interpretation step.** None of the following produced a readable flag from those 69 bytes:
- Hex-wrapping at various lengths (16, 20, 32, 69 bytes) as `r00t{<hex>}`
- Base64/Base32/Base58 at various lengths
- Single-byte and multi-byte repeating XOR (dictionary attack + full crib-drag)
- Modular add/subtract crib-drag
- Bit-rotation, nibble-swap, byte-reversal
- AES (ECB/CBC/CTR) using `A`, `B`, `M`, or their hashes as key material
- zlib/gzip/bz2/lzma decompression attempts
- CRC32/MD5/SHA1/SHA256 checksum-tail relationships
- Hash-chain/HMAC keystream constructions
- Backward LCG extrapolation (also ruled out — produces no zero-padding tell, confirming forward extrapolation is the right direction)
- 32-bit (rather than 32-byte) LCG reinterpretation of `block_size` — verifiably wrong (fails the recurrence check outright)
- Swapped preamble/secret layout (preamble at end instead of start) — verifiably wrong

An independent second AI analysis, run separately, converged on the **exact same wall** — the same 69-byte recovered plaintext, the same set of ruled-out decodings. This is strong evidence the cryptographic recovery is complete and correct, and the missing piece is either a hint/errata we didn't have access to, or a decoding convention specific to this challenge that isn't derivable from the two files alone.

## Ideas for Next Attempt

- Check the platform/Discord for a hint or errata specifically on this challenge (10 solves on a 200-pointer with this much resistance to a fully-broken keystream suggests something not in the two files alone).
- If any other artifact exists for this challenge (a `gen.py`, `Dockerfile`, `README`) that wasn't in the original zip, that likely specifies the exact serialization/encoding used for the sealed payload.
