# Wiretap — Forensics (400 pts, 11 solves)

**Author:** DR programmer
**Flag:** `r00t{thr33_pr0t0c0ls_1_pcap__dns_KEY_plus_icmp_IV_plus_http_AES_z1p_x0r}`

## Description

"We tapped an analyst's uplink for sixty seconds. In that window they pulled down a payload — and something *else* went out the back door. One capture, two conversations. Reassemble the truth."

The description's "**two** conversations" is the key hint — there's a second, easy-to-miss data flow hiding in the same pcap.

## Analysis — Three Covert/Encoded Channels

The single `capture.pcap` weaves together three protocols, each carrying a piece of the puzzle:

1. **DNS queries** — a sequence of subdomain labels encoding 16 bytes of data, ordered by an index prefix in each label (not by packet arrival order, which was scrambled). Extracted and reassembled → **AES key**.
2. **ICMP echo packets** — 16 packets (to the real target) plus 2 decoy packets (to the gateway, containing a boring `abcdefgh` payload). Each real packet's single-byte payload, ordered by ICMP sequence number → **AES IV**.
3. **HTTP** — the actual payload transfer, containing **two separate TCP streams**, not one. Stream 0 carries a 48-byte AES-CBC ciphertext blob. Stream 1 (the easy-to-miss "back door" traffic) carries a *second*, related ciphertext.

## Key & IV Recovery

```python
key = hashlib.sha256(dns_bytes).digest()   # 32 bytes, AES-256
iv  = icmp_bytes                            # 16 bytes, raw ICMP payload sequence
```

We confirmed the key was correct via a strong statistical argument **independent of the IV**: in AES-CBC, only the *first* decrypted block depends on the IV — blocks 2+ are fully determined by ciphertext and key alone. Decrypting stream 0's later blocks under `sha256(dns_bytes)` produced **valid PKCS7 padding** (13 bytes of `0x0D`) — a coincidence with odds around 1-in-256¹³ for a wrong key.

## The Real Trick — Stream 1 and the DEFLATE "Stored Block"

Stream 0 alone never fully decoded to readable text (the IV-dependent first block resisted many candidate IVs). The breakthrough was **stream 1**: decrypting it with the *same* key but the ICMP bytes as IV produced output starting with `78 da` — a valid **zlib header** — and critically, a DEFLATE **"stored" (uncompressed) block** whose `NLEN` field was the exact bitwise complement of its `LEN` field (`LEN=0x0048`, `NLEN=0xFFB7`), which is a hard structural requirement of the stored-block format and effectively impossible to satisfy by chance.

Reassembling the *complete* stored-block payload (72 bytes) from stream 1, verifying it against the trailing **Adler-32 checksum** (matched exactly, confirming a fully valid zlib stream), then applying one final XOR layer against the DNS key bytes (matching this event's recurring "one more XOR pass" pattern) produced clean, readable flag text.

## Solve Pipeline Summary

```
DNS labels (index-ordered)     → 16 bytes  → SHA-256 → AES key
ICMP payloads (seq-ordered)    → 16 bytes  → AES IV
HTTP TCP stream 0               → 48-byte AES-CBC ciphertext (decoy/partial)
HTTP TCP stream 1 (hidden!)     → AES-CBC ciphertext → zlib "stored block" (72 bytes, Adler32-verified) → XOR with DNS key bytes → FLAG
```

## Lesson

The flag literally spells out the solve path (`thr33_pr0t0c0ls...dns_KEY_plus_icmp_IV_plus_http_AES_z1p_x0r`) — always check `tcp.stream` indices explicitly in Wireshark/tshark rather than assuming "the HTTP conversation" is a single stream. A second hidden stream is a common CTF forensics trick. Also: a DEFLATE stored-block's `NLEN == ~LEN` invariant is a great structural check for validating a key/IV guess even when direct decompression fails due to truncated captures.
