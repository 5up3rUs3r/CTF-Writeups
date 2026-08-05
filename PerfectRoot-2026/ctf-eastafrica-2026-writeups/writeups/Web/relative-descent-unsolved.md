# Relative Descent — Web (Medium, 200 pts, 8 solves) — NOT SOLVED

## Description

"A relative descent, a silent pen, and a story rewritten from within." (Path traversal + SSTI wordplay.)

A Spring Boot + Thymeleaf CSV-upload/payment-report application (`labs-intervarsity.ctfzone.com:30005`) with a `/pmt/api/v1/file` upload endpoint (`file`, `dateTime`, `endDate`, `name` fields) and a `/reports/<filename>` report-serving path.

## What We Proved

- **Confirmed real path traversal vulnerability**, not just a theoretical one: uploading a file with the multipart `filename` field set to a traversal payload (`../../../../etc/passwd`) causes the backend record's `status` to flip from the normal `INITIATED` to **`FAILED`** — proof the server actually attempted a filesystem operation at the traversed path (as opposed to normal uploads, which just sit at `INITIATED` indefinitely with no automatic processing observed).
- **`reportLink` in the JSON response is built directly from the uploaded filename**, confirming the traversal payload propagates into the report-serving path construction.
- SpEL/Thymeleaf SSTI probes in the `name`/`uploaderName` field (`__${T(java.lang.Runtime).getRuntime().exec("id")}__::.x`) were **accepted and stored** without server-side sanitization, but we never found a code path where `uploaderName` gets rendered through a Thymeleaf template unescaped (no working report-generation trigger was found — see below), so we couldn't confirm actual SSTI execution.
- No `/pmt/api/v1/file/{id}/process`-style trigger endpoint, Spring Batch job launcher, or scheduled-processing mechanism was found despite extensive endpoint probing (`OPTIONS` discovery, common REST path guessing, Spring Actuator/Swagger endpoint checks — all closed/404).

## Where We Got Stuck

**Getting past Tomcat's built-in dot-dot (`..`) URL normalization/rejection** when directly requesting the traversed report path via GET. Tried and failed:
- Literal `../` in the URL (`--path-as-is` to prevent curl-side normalization) — Tomcat itself returns `400 Bad Request`.
- Single URL-encoding (`%2e%2e%2f`) — same 400 rejection.
- Double URL-encoding (`%252e%252e%252f`) — passes Tomcat's filter (gets to the Spring routing layer, returns `404 Not Found` with the literal single-encoded string shown in the error JSON, meaning it wasn't decoded a second time inside the handler either).
- Semicolon path-parameter injection (`..;/`) — `400`.
- Backslash variants (`..%5c`) — `400`.
- "Quad-dot" bypass (`....//`) — reaches Spring routing (`404`, not `400`), but doesn't resolve to a real file either.

The traversal clearly *executes* server-side (proven by the `FAILED` status change during upload processing), but we never found the matching GET-path encoding that lets us actually *read back* the result through the public-facing report endpoint.

## Alternate Angle Tried in a Parallel Session — Write-Based SSTI

A separate work session on a different lab instance spin-up (same challenge, different ephemeral port — `:30017` instead of `:30005`; lab instances get fresh ports per deploy) pursued the **write** side of the same traversal bug rather than trying to read back an existing file:

- Confirmed the page's HTML includes a suspicious duplicated `<link rel="stylesheet">` with a comment: `<!-- Fallback if Thymeleaf processing fails -->` — strong evidence the app uses an **external, file-based Thymeleaf template resolver** with a classpath fallback, meaning template files likely live on disk and could potentially be overwritten via the same traversal-controlled filename that flips upload `status` to `FAILED`/`INITIATED`.
- Plan (session ended before completion): use the traversal write to overwrite `/static/css/style.css` with a known marker string, then `GET /css/style.css` to confirm the write landed and roughly locate the app's working directory — a **verifiable write oracle** distinct from the read-based approach in the rest of this writeup.
- Follow-up plan: once the working directory is located, target Spring Boot's conventional template paths (`templates/files.html`, `src/main/resources/templates/files.html`, etc.) for an **overwrite → SpEL/SSTI RCE** chain — directly matching the challenge's "a story rewritten from within" hint (rewriting the actual template that renders the page, not just reading a static file).

This is a genuinely different and possibly more promising direction than the GET-side traversal-encoding bypass documented above — worth prioritizing on a fresh attempt, since it doesn't depend on defeating Tomcat's URL-level dot-dot filtering at all (the write happens via the multipart `filename` field, which isn't subject to the same URL-path normalization).

## Ideas for Next Attempt

- **Prioritize the write-based approach above** over further URL-encoding bypass attempts on the GET side — it sidesteps Tomcat's dot-dot filtering entirely.
- The vulnerable operation might be a **write**, not a read — during "processing," the app may try to *write* a generated report to a path derived from the traversal-controlled filename, meaning the interesting artifact might be creatable/overwritable rather than readable via a simple GET.
- Investigate whether Spring's own static-resource handler for `/reports/**` (a `ResourceHttpRequestHandler`, if that's what's serving it) has different traversal-bypass characteristics than raw Tomcat — Spring resource handlers have had their own historical CVEs (e.g., CVE-2021-22096-adjacent classes of bypass) distinct from Tomcat's own URL normalization.
- Try triggering the traversal via the **`sync_url`/case-sync-style proxy pattern** seen in the sibling "Chain of Custody" challenge from the same event, in case there's a similarly undocumented internal endpoint here too.
