# Hidden Order — Quantum (Hard, 300 pts, 25 solves) — SOLVED

**Author:** beafn28
**Flag:** `r00t{b8e61a26d8dae93117e2b271177b00c3}`

## Description

"Have fun recovering the flag." Framed as a quantum order-finding challenge — an RSA public key, an "encrypted seed," and flag parameters suggesting Shor's-algorithm-style post-processing was needed.

## The Twist

The quantum framing was **entirely decorative**. The RSA modulus `N` was only 38 bits — trivially factorable by brute force / Pollard's rho, no quantum order-finding required at all.

```python
N = 253233986461
# factors trivially:
p, q = 505961, 500501
assert p * q == N
```

With `p, q` known, standard RSA private-key recovery applies:

```python
phi = (p - 1) * (q - 1)
d = pow(e, -1, phi)
seed = pow(encrypted_seed, d, N)   # seed = 39484369, only 26 bits
```

## The Real Puzzle: KDF Byte-Length

The challenge metadata claimed `"seed_bits": 128`, which is misleading — it describes the *intended design space*, not the actual recovered value's size. The bug-hunt was in finding the exact key/nonce derivation:

```python
key   = sha3_256(seed.to_bytes(4, 'big'))          # 4 bytes = seed's true minimal size
nonce = sha256(b"hidden_order_challenge" + N.to_bytes(8, 'big'))[:8]

cipher = AES.new(key, AES.MODE_CTR, nonce=nonce)
flag = cipher.decrypt(ciphertext)
```

Found this by brute-forcing a grid of `seed_bytes` lengths (4/5/6/8/16), hash functions (SHA3-256/SHA256), `N` byte-lengths, and nonce-hash variants, filtering for `r00t{` in the output.

## Lesson

Don't over-trust a challenge's stated bit-length/parameter hints — verify against the actual recovered integer's minimal encoding. Also: **"quantum" framing in a challenge is not a guarantee a quantum algorithm is actually required** — always sanity-check the modulus size first before reaching for Shor's/QPE machinery. (This turned out to be a recurring pattern in this event — the sibling challenge "Gaussian Echo" used genuine QPE data, so the two shouldn't be assumed to follow the same trick.)
