# Chain of Custody — Web (Medium, 200 pts, 9 solves) — NOT SOLVED

**Author:** LordSudo

## Description

"ForensiTrack is Silverline Forensics Lab's internal chain-of-custody portal... The lab recently onboarded a new trainee analyst and something in that onboarding process wasn't locked down the way it should have been. Your objective: Get in the lab's restricted evidence locker."

## What We Proved

Found and fully read an accidentally-shipped debug file (`/static/debug/api-notes.md`, referenced in a leftover comment in the production JS bundle — `app.bundle.js` explicitly says "this build slipped through with comments intact") that documents the entire intended vulnerability chain:

1. **Auth bypass via debug header:** `POST /api/cases/<id>/sync` accepts an `X-Debug-Role` header that overrides the role check for that single request — intended only for QA, "never should have reached the onboarding build."
2. **Unrestricted SSRF:** the same endpoint does a raw `requests.request(method, sync_url, ...)` server-side with **no allowlist on the target host**, and returns the response verbatim — meant for "pushing case updates to partner-lab mirrors," but usable to reach internal-only services.
3. **A named internal target:** `http://evidence-service:5001`, with `POST /upload` (multipart) and `POST /process` (`{"filename": ...}` — regenerates metadata via `exiftool`, a classic RCE vector via CVE-2021-22204/DjVu-polyglot-style attacks).
4. **A documented weak PRNG for `/track` case tokens:** `random.seed(created_ts // 60)`, `random.getrandbits(48)`, with `case_id % 7` extra draws burned to decorrelate same-minute cases.

We **independently validated point 4's algorithm is exactly correct** by brute-forcing the creation timestamp for the three known public cases (1001–1003) purely offline (no network calls) and finding exact token matches — proving our reimplementation of the token PRNG is bit-perfect, not just plausible.

## Where We Got Stuck

**We never obtained a single valid login credential**, which is the prerequisite for using bypass #1 (the debug header only overrides the *role* check — it still requires a validly-HMAC-signed JWT to pass authentication first; confirmed by testing a garbage bearer token, which is rejected identically to no token at all).

Attempts that failed:
- Common/guessed trainee credentials (`trainee`/`trainee`, `newhire`/`newhire`, etc.) — all `401`.
- JWT secret brute-force against ~30 common weak secrets (`secret`, `forensitrack`, `changeme`, etc.) — none forged a valid signature.
- SQL/NoSQL injection payloads on the login endpoint (`' OR '1'='1`, MongoDB `$ne` operators) — no bypass; the `$ne` payload just crashed with a 500 (likely a naive string-comparison backend, not actually NoSQL).
- Username enumeration via response-time/status differences — no signal detected across ~23 candidate usernames.
- Predicting a **hidden onboarding-related case token** using the validated PRNG, anchored on a timestamp hint from the `/status` changelog page ("~2026-08-02 11:15 UTC — onboarding ticket opened") — an extensive multi-threaded brute force across a wide case-ID range (1–60, 1000–1050) and a ±45-minute window around that timestamp found no match.

## Ideas for Next Attempt

- The onboarding case token search may need a **much wider time window** or an entirely different case-ID numbering scheme (e.g., non-numeric onboarding-ticket IDs that don't fit the public `/track` case_id pattern at all).
- Re-examine whether there's a **self-registration or invite endpoint** not yet discovered (all `/api/auth/register`, `/api/auth/signup`, `/api/auth/onboard` variants returned `404` — but the true path may use different, unguessed naming).
- Consider that the "onboarding process wasn't locked down" framing might point to a **predictable initial/temp password pattern** tied to a specific, guessable username format (e.g., firstname.lastname derived from a name visible elsewhere on the site) rather than the token-PRNG angle.
