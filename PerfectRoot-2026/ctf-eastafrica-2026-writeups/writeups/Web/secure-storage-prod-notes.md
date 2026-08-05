# Secure Storage Prod — Web (Easy, 100 pts, 9 solves) — NOT SOLVED BY US (teammate solved it)

**Author:** f0rk3b0mb

## Description

"The production environment is live. Handle with care." A Flask app with a file-storage dashboard (Private/Public file tabs), at `labs-intervarsity.ctfzone.com:30042`.

## What We Found Before Handing Off

- A suspicious HTML comment in the dashboard's CSS/top-bar area: `<!-- ?username= -->` — a strong leftover-developer hint pointing at an unauthenticated or under-checked `?username=` query parameter somewhere in the app.
- The dashboard's `filterFiles()` and `showTab()` JS functions were referenced in the HTML but **not defined inline** — meaning there's a separate `/static/js/...` file containing the real AJAX logic for listing/fetching files, which we hadn't located yet.
- Working hypothesis at hand-off: an endpoint like `/dashboard?username=<other_user>` or an API call (`/api/files?username=...`) doesn't verify the requesting session matches the target `username` — an IDOR via query parameter, directly hinted at by the CSS comment (same vulnerability *class* as "Open Door," different delivery mechanism — query param instead of path segment).

## Status

A teammate solved this independently before our own directory-fuzzing (`ffuf` against `/static/js/`) located the missing JS file. **No confirmed flag or exact exploit request captured on our end** — if you have access to the teammate who solved it, get the exact request/payload for a complete writeup; the `?username=` IDOR hypothesis above is a strong starting point for reproducing it independently if needed.
