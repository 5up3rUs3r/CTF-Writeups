# Crypto Sanity Check - x^y encryption (100 pts - Cryptography)

## Challenge Description

> I was given a ciphertext and an encryptor. Find a way to decrypt the ciphertext.

## TL;DR

XOR encryption with the repeating key `cybergame`. Since XOR is its own inverse, applying the same key to the ciphertext directly recovers the plaintext.

## Initial Analysis

The challenge name `x^y` is the XOR operator. The encryptor XORed each plaintext byte against the corresponding byte of `cybergame` repeated to match the plaintext length.

## Solution

### Step 1: Recognise XOR symmetry

XOR satisfies: `plaintext XOR key = ciphertext`, therefore `ciphertext XOR key = plaintext`. No separate decryption step is needed — encryption and decryption are the same operation.

### Step 2: Apply the key

```python
def xor_crypt(data_hex, key):
    data = bytes.fromhex(data_hex)
    key_bytes = (key.encode() * (len(data) // len(key) + 1))[:len(data)]
    return bytes(a ^ b for a, b in zip(data, key_bytes))

print(xor_crypt(CIPHERTEXT_HEX, "cybergame").decode())
```

On **CyberChef**: **From Hex → XOR** (key: `cybergame`, UTF-8).

The key `cybergame` was the natural first guess given the competition name.

## Flag

```
SK-CERT{34sy_70_r3v3rs3_wh3n_y0u_h4v3_7h3_k3y}
```

## Key Takeaways

- **XOR with a known key is trivially reversible** — the same function encrypts and decrypts
- Competition/platform names are always worth trying as XOR keys in CTFs
- The flag summarises the lesson: "easy to reverse when you have the key"

## Tools Used

- Python — XOR decryption
- CyberChef — verification
