# Gaussian Echo — Quantum (Hard, 300 pts) — NOT SOLVED

**Author:** beafn28

## Description

`qpe_log.json` contains a two-round Quantum Phase Estimation attestation log: `n_ancilla=20` qubits, ~1000 measurement shots per round with ~15% decoherence (random outlier shots), and an AES-encrypted flag.

**Hints (released mid-event):**
> The session key is derived from the Gaussian integer components of the recovered value hashed with SHA3-256, encoded as 4-byte big-endian integers in ascending order. The cipher operates in CTR mode.
> The nonce, like the key, comes from the Gaussian pair. Nothing is guessed. Look deeper and you shall find what you seek.

## What We Proved

- Round 0 (`unitary_power=1`): measurement mode = **524309** (850/1000 shots), matching the ~15% decoherence rate described.
- Round 1 (`unitary_power=4096`): measurement mode = **86016** (850/1000 shots).
- **Exact consistency check:** `(4096 × 524309) mod 2^20 = 86016` — matches round 1's mode *exactly*, with zero rounding error, confirming `524309` is the single precisely-recovered phase value ("the recovered value" the hint refers to).
- **The Gaussian-integer breakthrough:** `524309 = 55² + 722²` — a **unique** sum-of-two-squares decomposition (verified: no other `(a,b)` pair with `a≤b` satisfies `a²+b²=524309`). This is almost certainly the "Gaussian integer components" `(a, b) = (55, 722)` the hint describes.
- **Key derivation (per hint, implemented exactly):**
  ```python
  key = hashlib.sha3_256(a.to_bytes(4,'big') + b.to_bytes(4,'big')).digest()
  # a=55, b=722, ascending order as specified
  ```
- Confirmed `checksum` field in the JSON is simply `SHA1(device_id)` — a device-attestation hash, not key material (ruled out as a distraction).

## Where We Got Stuck

**The nonce.** Despite the hint stating it "comes from the Gaussian pair" and "nothing is guessed," an extensive systematic search over nonce constructions never produced a plaintext containing `r00t{`:

- `SHA3-256(a‖b)` truncated to 8/16 bytes, various slice positions
- Raw `a‖b` bytes (pre-hash encoding) directly as nonce/CTR initial value, various byte-widths (2/4/8-byte ints)
- Reversed order (`b‖a`), descending order
- Hash of the pair as ASCII/decimal strings instead of raw bytes
- Norm (`a²+b²`), product (`a×b`), difference (`b−a`) as nonce material
- A second hash layer on top of the key itself ("look deeper" interpreted as hash-of-hash)
- SHA-256/SHA3-512/MD5 variants of the same pair encoding
- Full 16-byte CTR `initial_value` variants (not just 8-byte `nonce`) at multiple slice offsets
- Python `random`-module seeding from the mode/pair values

## Ideas for Next Attempt

- "Look deeper" may refer to a **different mathematical property** of the Gaussian integer `55+722i` we haven't tried — e.g., its **argument/phase** (angle), its position in a specific ordering of Gaussian primes, or a **second Gaussian pair** derivable from `mode2` (86016) via a non-sum-of-squares route (confirmed 86016 has no sum-of-two-squares decomposition itself, since `86016 = 2^12 × 21` and `21 = 3×7` both primes ≡3 mod 4 to odd powers — but there may be a *different* decomposition method the challenge intends, e.g., treating the *pair* `(524309, 86016)` as encoding a Gaussian integer via a different construction entirely, such as GCD in `Z[i]`).
- Worth trying the nonce as derived from the **imaginary/real part individually multiplied by a different exponent** related to `unitary_power=4096=2^12`.
- If a hint escalation/Discord clarification exists beyond the two given hints, check there — a 300-point Hard challenge resisting this much systematic search after two confirmed-correct building blocks (key derivation method, Gaussian pair) suggests one specific remaining trick, not a wrong overall approach.
