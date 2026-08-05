# Beacon — The Uhuru Torch — Misc (400 pts, ~10 solves) — NOT SOLVED

## Description

Themed around the 1961 Uhuru Torch carried to Kilimanjaro's summit. Files: `guardian.py` (reference decoder, provided), `mwenge.png`, `cecafa_2002.csv`, `ram.bin`.

## What We Found

`guardian.py` is a **fully-specified reference pipeline** — the decode/unseal logic is given openly, but four key-derivation inputs are deliberately left blank as placeholders:

```python
BLOB = '...'  # sealed torch: ROT47 -> reverse -> base64 -> AES-CBC -> zlib -> XOR
FLAG_SHA3 = "19f410ef1319a2a8299aac9b20ba9b79103baba16ab1b5dc4ed5e8b65e5c6f3b"  # constant-time digest check
_hint = "e00g{gur_gbepu_jnf_yvg_va_1961}"   # ROT13 decoy — explicitly NOT the answer

def _derive_key():
    frag  = b"________"   # 8 bytes hidden in mwenge.png
    frag2 = b"________"   # 8 more bytes hidden in mwenge.png
    cap   = b"?????"      # from mwenge.png
    tally = b"??"         # from cecafa_2002.csv
    aes_key = sha256(frag + b"|" + frag2 + b"|" + cap + b"|" + tally).digest()[:32]
    iv      = sha256(tally).digest()[:16]
    return aes_key, iv, frag
```

The full unseal pipeline (given): `ROT47 → reverse → base64-decode → AES-CBC-decrypt → zlib-inflate → XOR(frag)`.

## Decoy Flag (Confirmed Decoy — Not the Real Flag)

The "easy" ghost strings scattered across the files (PNG metadata "Capacity: 60000", "Attendance: 13000", "Benjamin Mkapa" stadium reference, CSV per-match figures) decode via the obvious path to:

```
r00t{B3nj4m1n_Mkap4_Stad1um_2002_CECAFA}
```

The script's own docstring warns *"Many strings here will look like the answer. The torch does not reward the hasty."* — this decoy is exactly that trap, confirmed wrong on submission.

## Where We Got Stuck — PNG Steganography

Established the PNG's baseline pixel-value formula holds for the vast majority of pixels:
```
R = 2x, G = 3y, B = (x+y) mod 256
```
...except for **53 deliberately anomalous pixels**, clustered in exactly 4 rows (`y = 50, 51, 100, 101`), each using small `±1` deviations in specific channels from the baseline formula.

**The blocker:** 53 anomalies can encode at most ~53 bits (~6-7 bytes) in the simplest "presence/direction of deviation = 1 bit" reading — far short of the 168 bits (21 bytes total: `frag`+`frag2`+`cap`) the key derivation needs. Reading rows 100–101's blue-channel `±1` direction as a bitstream gave a tantalizing partial fragment (`"fiQ"`) that wasn't clearly meaningful, suggesting either:
1. A different bit-grouping/ordering convention than tried, or
2. The anomaly channel encodes something smaller/different than the full field set, with the remaining fields coming from elsewhere.

## Ideas for Next Attempt

- Try treating each anomalous pixel's **magnitude** of deviation (not just direction) as encoding more than 1 bit per pixel.
- Re-examine whether `ram.bin`'s visible "ghost" strings (`TXOR_KEY=MWENGE`, etc.) are a red herring pointing at a **different, correct** XOR seed for the *real* steganographic payload, rather than being pure noise.
- Consider that the CSV's `tally` (2 bytes) might come from a specific aggregate (sum of goals = 21 was one candidate tried) rather than a printed value.
- Worth checking for a hint/errata channel — this challenge had a notably low solve count for its point value, suggesting genuine difficulty rather than a missed "obvious" trick.
