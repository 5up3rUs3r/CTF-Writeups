# Thin Ice — Crypto (Easy, 100 pts)

**Author:** c0deg33k
**Flag:** `r00t{mult1pr1m3_r3duct10n_unl0cks_w13n3r}`

## Description

FastCrypt sells HSM appliances claiming hardware-accelerated RSA decryption. A whistleblower leaked the key generation source (`keygen.py`), a public key (`public.pem`), a device config (`device.cfg`), and an intercepted ciphertext (`encrypted.b64`).

## The Vulnerability

The leaked `keygen.py` reveals "Split-Key RSA": a **3-prime RSA modulus** `N = p * q * r`, where:

- `p` — a 128-bit "system prime" shared across a whole production batch, and **exposed** in `device.cfg` as `hw_device_id`.
- `q, r` — fresh 256-bit "session primes," kept secret inside the HSM.
- The private exponent `d` is deliberately bounded: `d < 2^120` — a "hardware key-well register limit." This is the real bug: it's a **small private exponent**, textbook Wiener-attack territory, except we don't even need Wiener since `p` is already leaked.

Since `d < 2^120 < p - 1`, we can recover `d` directly:

```
d = e⁻¹ mod (p - 1)
```

This works because `d`'s true value modulo the full `φ(N) = (p-1)(q-1)(r-1)` reduces to itself modulo any factor of `φ(N)` that's larger than `d` — and `p-1` clears that bar.

## Solve Script

```python
from Crypto.PublicKey import RSA
from Crypto.Util.number import long_to_bytes
import base64

key = RSA.importKey(open('public.pem').read())
N, e = key.n, key.e

p = 0x910e4130380ead292217fc70bd714929  # leaked via device.cfg hw_device_id

ct_int = int.from_bytes(base64.b64decode(open('encrypted.b64').read()), 'big')

d = pow(e, -1, p - 1)
pt_bytes = long_to_bytes(pow(ct_int, d, N))

start = pt_bytes.find(b'r00t{')
end = pt_bytes.find(b'}', start)
print(pt_bytes[start:end+1])
```

## Notes

- First attempt hit a platform-side bug: the challenge's underlying keys/ciphertext were regenerating between attachment downloads, so a mathematically-correct first solve (`r00t{sp11t_k3y_w13n3r_h4rdw4r3_l3ak}`) was rejected as invalid. Re-downloading the attachment fresh and re-running the exact same technique against the new keys produced the accepted flag above.
- Lesson: if the crypto is airtight (round-trip verified, no ambiguity in the math) but the platform rejects it, suspect stale/regenerated challenge data before doubting your own work.
