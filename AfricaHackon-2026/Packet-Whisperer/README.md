# Packet Whisperer (100 pts - Network Forensics)

## Challenge Description

> Can you figure out what's going on in this capture?

**File:** `chall.pcap` (1279 packets, ~98KB, 963-second capture)  
**Difficulty:** Easy

## TL;DR

DNS exfiltration challenge — an attacker tunneled a zip archive through DNS queries as base64-encoded subdomains. The zip contained `flag.txt`. Extracting and decoding the base64 payload revealed the flag.

## Initial Analysis

### Step 1: Protocol overview

```bash
tshark -r chall.pcap -q -z io,phs
```

Output showed two protocols of interest: TCP traffic and DNS (26 UDP packets). The small number of DNS packets relative to the capture size immediately looked suspicious.

### Step 2: String dump

```bash
strings chall.pcap
```

This surfaced base64-looking chunks and a recurring username: `hackerman`. The base64 fragments and the destination domain `hackerman.com` pointed directly to DNS-based data exfiltration.

## Solution

### Step 3: Extract DNS query names

```bash
tshark -r chall.pcap -Y dns -T fields -e dns.qry.name
```

The DNS queries revealed a sequence of base64-encoded subdomains being sent to `hackerman.com`. Each subdomain was a chunk of a base64-encoded zip file — the attacker was tunneling data out via DNS queries.

```
cjAwdHsxdHNfNGx3NHk1X0ROU19yMWdodH0K.hackerman.com
...
```

### Step 4: Decode the flag

The final base64 chunk decoded directly to the flag:

```bash
echo 'cjAwdHsxdHNfNGx3NHk1X0ROU19yMWdodH0K' | base64 -d
```

The full zip (reconstructed by concatenating all DNS query chunks) contained two files: `flag.txt` and `notes.txt`. The flag was in `flag.txt`.

## Flag

```
r00t{1ts_4lw4y5_DNS_r1ght}
```

## Key Takeaways

- **DNS exfiltration** — DNS is often under-monitored, making it a classic covert channel for data theft. Attackers encode data as subdomains and send queries to an attacker-controlled resolver.
- **`strings` is fast triage** — dumping raw strings from a pcap quickly surfaces usernames, domains, and encoded payloads before doing deeper protocol analysis.
- **Base64 in subdomains** — any DNS queries with long, high-entropy subdomain labels are a red flag for tunneling.
- **Defense:** Monitor for unusually long DNS query names, high DNS query rates to a single domain, and non-existent TLD lookups.

## Tools Used

- `tshark` — protocol statistics and DNS field extraction
- `strings` — raw string triage
- `base64` — payload decoding
