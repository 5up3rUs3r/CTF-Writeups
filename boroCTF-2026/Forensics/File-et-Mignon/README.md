# File-et Mignon (Forensics)

## Challenge Description

> A perfectly portioned file. But don't try to carve it all at once.

**File:** `filet_mignon.tar.gz` (344 bytes compressed)  
**Flag Format:** `boroCTF{...}`

## TL;DR

A 344-byte `tar.gz` containing a sparse tar entry that claimed ~10TB of size. Extracting normally would fill any disk. Decompressing the gzip stream directly in Python and reading the first 4096 bytes revealed the flag split across 9 sparse blocks in the tar stream.

## Initial Analysis

### Step 1: List the archive without extracting

```bash
tar -tzf filet_mignon.tar.gz
# sparse_flag.txt   (~10TB claimed size)
```

A single file with an impossibly large claimed size — a tar sparse file entry. Extracting would attempt to allocate ~10TB on disk.

### Step 2: Measure the actual compressed data

```bash
ls -la filet_mignon.tar.gz
# 344 bytes
```

344 bytes compressed. The real data is tiny; the 10TB is sparse padding that never materialises on disk in the compressed form.

## Solution

### Step 3: Read the gzip stream directly — no extraction

```python
import gzip

with gzip.open('filet_mignon.tar.gz', 'rb') as f:
    data = f.read(4096)   # read only first 4096 bytes of decompressed stream

print(data)
```

The decompressed output contained the tar stream headers and, within them, the flag split into **5-byte chunks** across **9 sparse blocks**.

### Step 4: Assemble the chunks in order

The chunks appeared sequentially in the decompressed stream. Reading them in order and concatenating produced the flag string.

**Correction during assembly:** an initial misread of `v0ld` was corrected to `v01d` after byte-level verification:

```bash
python3 -c "
import gzip
with gzip.open('filet_mignon.tar.gz', 'rb') as f:
    data = f.read(4096)
import sys; sys.stdout.buffer.write(data)
" | xxd | grep -A 2 "626f726f"
```

The `xxd` output confirmed `0x76 0x30 0x31 0x64` = `v01d`, not `v0ld`.

## Flag

```
boroCTF{y0u_c4rv3d_th3_v01d_l1k3_4_ch3f}
```

## Key Takeaways

- **Sparse files are disk traps** — tar sparse extensions allow a file to claim arbitrary size while storing almost no actual data. Never `tar -xzf` an untrusted archive without inspecting sizes first.
- **Read the stream, don't extract** — `gzip.open()` with a byte limit decompresses safely without triggering tar extraction. `read(4096)` is a safe ceiling that covers all real content.
- **Flag carved from sparse blocks** — data lives in the non-sparse regions of the tar stream. The entire useful payload fit inside the first 4096 bytes of the decompressed stream.
- **`xxd` for leet-speak verification** — `0` vs `o` in leet flags looks identical in terminal output; `xxd` gives ground-truth hex values.

## Tools Used

- `tar` (`-tzf`) — safe archive listing without extraction
- Python 3 (`gzip`) — bounded stream decompression
- `xxd` — byte-level flag chunk verification
