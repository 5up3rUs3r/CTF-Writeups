# Osint Sanity Check - Plain TXT (100 pts - OSINT)

## Challenge Description

> Check out DNS records for `sanity.cybergame.sk`

## TL;DR

Flag hidden in a DNS TXT record — retrieved with a single `dig` command.

## Solution

### Step 1: Query the TXT record

DNS TXT records are a classic CTF hiding spot. Run:

```bash
dig TXT sanity.cybergame.sk
```

Output:

```
sanity.cybergame.sk. 300 IN TXT "SK-CERT{7rivi4l_dns_ch4ll3ng3}"
```

## Flag

```
SK-CERT{7rivi4l_dns_ch4ll3ng3}
```

## Key Takeaways

- **DNS TXT records** are one of the first places to check in any OSINT or recon challenge when given a domain
- `dig TXT <domain>` or `nslookup -type=TXT <domain>` are the go-to commands
- The flag itself confirms the lesson: "trivial DNS challenge"

## Tools Used

- `dig` — DNS TXT record query
