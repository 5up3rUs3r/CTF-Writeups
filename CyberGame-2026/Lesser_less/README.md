# Lesser less (454 pts - Malware Analysis)

## Challenge Description

> A pager with more functionality than advertised.

## TL;DR

A trojanized ELF pager binary reading input files 2 bytes at a time, SHA256-hashing each pair against 40 stored hashes. Brute-forced all 65,536 two-byte combinations to reconstruct the hidden shell command, which contained the flag as a comment.

## Initial Analysis

```bash
file less_binary
strace ./less_binary phrase.txt 2>&1 | grep "read"
# Showed consistent 2-byte reads
```

Running `strings` on the binary revealed 40 SHA256 hashes (64-char hex strings each). The binary was reading an input file in 2-byte chunks, hashing each chunk, and comparing against these stored values.

## Solution

### Step 1: Extract the 40 SHA256 hashes

```bash
strings less_binary | grep -E "^[a-f0-9]{64}$"
```

### Step 2: Build a brute-force lookup table

With only 2 bytes per chunk (~95² = ~9,025 printable combinations), brute force is trivial:

```python
import hashlib, itertools, string

stored_hashes = ["HASH_0", "HASH_1", ...]  # 40 hashes from strings output

printable = string.printable
lookup = {}
for a, b in itertools.product(printable, repeat=2):
    pair = (a + b).encode()
    h = hashlib.sha256(pair).hexdigest()
    lookup[h] = a + b

command = ''.join(lookup[h] for h in stored_hashes)
print(command)
```

Output:

```
echo 'where is the flag?' > flag.txt # SK-CERT{l99k1n6_f0r_h1dd3n_func710n4l17y}
```

### Step 3: Write the phrase file and confirm

```python
with open("phrase.txt", "w") as f:
    f.write(command.rstrip())
# The binary passes the reconstructed command to system()
# Flag is embedded as a shell comment — visible without execution
```

## Flag

```
SK-CERT{l99k1n6_f0r_h1dd3n_func710n4l17y}
```

## Key Takeaways

- **2-byte SHA256 chunking** is effective obfuscation but trivially brute-forceable — only ~9,025 combinations exist for printable ASCII
- **Flag hidden as a shell comment** is a clever "hidden in plain sight" design — `system()` executes the command and the comment is transparent to the shell but contains the flag
- The name "lesser less" describes the binary perfectly: a pager that secretly executes commands encoded in the files you feed it

## Tools Used

- `strace` — read pattern analysis confirming 2-byte chunks
- `strings` — SHA256 hash extraction
- Python `hashlib` + `itertools` — brute-force lookup table
