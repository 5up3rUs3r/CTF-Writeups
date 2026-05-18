# SPAN sniff (100 pts - Forensics)

## Challenge Description

> We received a PCAP capture from a corporate network device after a suspected incident. Help us investigate what happened.

## TL;DR

The PCAP was flooded with post-quantum SSH traffic as a red herring. The flag was encoded in the **HTTP version field** of each request — HTTP/1.0 = bit `0`, HTTP/1.1 = bit `1`. Extracting and decoding the bit stream revealed the flag.

## Initial Analysis

Running a protocol overview immediately surfaced a large volume of SSH sessions with unusual client banners:

```bash
tshark -r network.pcap -q -z io,phs
tshark -r network.pcap -Y "ssh" -T fields -e ssh.protocol
# SSH-2.0-conker_20260128 — non-standard client
```

The SSH traffic was encrypted and post-quantum key exchange was visible in the banners — clearly a designed distraction. Shifting focus to the HTTP traffic revealed the actual covert channel.

## Solution

### Step 1: Extract HTTP version fields

```bash
tshark -r network.pcap -Y "http.request" \
  -T fields -e http.request.version 2>/dev/null \
  | awk '{print ($1 == "HTTP/1.0") ? "0" : "1"}' \
  | tr -d '\n' > bits.txt
```

### Step 2: Convert bit stream to ASCII

```python
bits = open("bits.txt").read().strip()
chars = [bits[i:i+8] for i in range(0, len(bits), 8)]
flag = ''.join(chr(int(c, 2)) for c in chars if len(c) == 8)
print(flag)
```

Output: `SK-CERT{h1DD3n_1n_pl41n7eX7_n37Fl0w}`

## Flag

```
SK-CERT{h1DD3n_1n_pl41n7eX7_n37Fl0w}
```

## Key Takeaways

- **HTTP version as a covert channel** — HTTP/1.0 vs HTTP/1.1 encodes one bit per request, invisible to standard traffic analysis
- **Red herrings are deliberate** — the post-quantum SSH client `conker` was designed to waste time; when obvious suspicious traffic leads nowhere, look for quieter side channels in protocol metadata
- The flag itself confirms the technique: "hidden in plaintext netflow"

## Tools Used

- `tshark` — HTTP version field extraction
- Python — bit stream to ASCII conversion
- `awk` — version-to-bit mapping
