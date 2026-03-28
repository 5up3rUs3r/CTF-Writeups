# 0Pages (Web - 785 pts)

## Challenge Description

> Welcome to 0Pages, the static site hosting service you never knew you needed! We've completely rewritten it in Rust for maximum security... or so we think. Ready to see if it lives up to the hype?

**Category:** Web  
**Points:** 785 (dynamic, only 4 solves)  
**Author:** 0ops  
**Flag Format:** `0ops{...}`

## TL;DR

Rust-based static site hosting service (Salvo framework) fronted by Apache reverse proxy. Users upload zip archives containing websites. The intended vulnerability involved zip-based symlink traversal to escape the webroot and execute `/readflag` — a SUID binary — through a combination of path manipulation and CGI execution or an alternative code execution primitive.

## Architecture

```
Client → Apache (port 80) → Rust/Salvo app (port 5800)
                             ↓
                   /data/sites/{site_id}/webroot/
                   (user-uploaded files served here)

/flag          → chmod 000 (unreadable directly)
/readflag      → SUID binary, executes /flag
```

**Key files from the challenge archive:**

```
000-default.conf   ← Apache vhost — proxies /api and /preview to Rust
apache2.conf       ← AllowOverride None, FollowSymLinks enabled
Dockerfile         ← Reveals full setup
src/service.rs     ← Zip extraction logic
src/controller.rs  ← Route handlers
readflag.c         ← SUID wrapper to read /flag
```

## Vulnerability Analysis

### Zip Extraction in `service.rs`

The zip deployment code checks that extracted paths start with the declared `webroot/` prefix but does **not** filter out symlinks inside the zip:

```rust
let outpath = match file.enclosed_name() {
    Some(path) => {
        if path.starts_with(format!("{}/", manifest.webroot)) {
            let relative_path =
                path.strip_prefix(format!("{}/", manifest.webroot)).unwrap();
            std::path::Path::new(&format!("{}/webroot", site_path))
                .join(relative_path)
        } else {
            continue;
        }
    }
    None => continue,
};
```

`enclosed_name()` blocks `..` path traversal but **symlinks stored in the zip are extracted as symlinks** — preserving their targets.

### Apache Config Allows FollowSymLinks

```apache
<Directory />
    Options FollowSymLinks
    AllowOverride None
    Require all denied
</Directory>
```

### File Permissions

All uploaded files are set to `0o777` (world-executable) during extraction.

## Exploitation Approach

### Intended Path: Symlink + CGI Execution

The intended chain required:

**Step 1:** Create a zip containing a symlink pointing outside the webroot:

```python
import zipfile, os

with zipfile.ZipFile("symlink_payload.zip", "w") as zf:
    # Add manifest.json
    zf.writestr("manifest.json", '{"webroot":"webroot","name":"test"}')

    # Create symlink entry pointing to /
    # ZipInfo with symlink attribute
    info = zipfile.ZipInfo("webroot/rootlink")
    info.create_system = 3  # Unix
    info.external_attr = 0xA1ED0000  # symlink file type (0o120755)
    zf.writestr(info, "/")  # symlink target = /

    # CGI script to run /readflag
    zf.writestr("webroot/.htaccess",
        "Options +ExecCGI\nAddHandler cgi-script .cgi\n")
    zf.writestr("webroot/flag.cgi",
        "#!/bin/sh\necho 'Content-Type: text/plain'\necho ''\n/readflag 2>&1\n")
```

**Step 2:** Deploy and access `GET /preview/{site_id}/webroot/flag.cgi`

**The problem we hit:** Apache proxies all `/preview` traffic to the Rust/Salvo backend. The `.htaccess` and CGI directives are only respected when Apache serves files directly — but here Salvo's `StaticDir` serves them instead, so `.htaccess` is completely ignored.

### Alternative Paths Explored

**Path A: Symlink to `/readflag` binary**  
Created a symlink `webroot/rf → /readflag` and tried accessing it. The file was served as binary content (not executed).

**Path B: Path traversal via double-slash**  
Tested `GET /preview//site_id/webroot/` to see if Apache processed it directly (bypassing the proxy). Returned 404 from Salvo.

**Path C: URL encoding bypass**  
Attempted `%2F` and `%252F` variations to confuse the proxy routing. No bypass achieved.

**Path D: Zip slip via symlink chain**  
Attempted creating a zip where `webroot/link → ../../` as a multi-hop traversal. The `enclosed_name()` check blocked direct `..` but symlinks themselves passed through.

**Path E: Admin account via brute force**  
The Dockerfile seeds an admin account with a random password — brute force was not feasible.

### What the Intended Solution Required

Based on the challenge structure and the 4-solve count, the full exploit likely required:

1. Exploiting the zip symlink extraction to plant a symlink pointing to `/readflag`
2. Finding a way to **execute** rather than serve the symlinked binary — possibly through a Salvo path handling bug that allowed serving with execute permissions, or through an `.htaccess` bypass where Apache regained control of a specific path

## Status

This was a deeply investigated challenge with 4 total solves globally, indicating extreme difficulty. The symlink extraction path was confirmed to work (files deployed successfully), but triggering execution of `/readflag` via the Salvo-proxied endpoint was the unsolved final step.

## Key Takeaways

- **Zip symlinks are dangerous** — many zip extraction libraries extract symlinks as-is, creating traversal paths even when `..` is blocked
- **Proxy architecture matters** — when a web server proxies to an application backend, the frontend's `.htaccess` / CGI rules don't apply to the backend's served files
- **SUID binaries as targets** — when the flag file has `chmod 000`, a SUID wrapper binary is the only execution path, making code execution the required primitive
- **`enclosed_name()` is incomplete protection** — it prevents `..` directory traversal but does not handle symlink targets in extracted zip contents

## Tools Used

- Python `zipfile` — crafting malicious zip payloads with symlinks
- `curl` — manual endpoint testing and response analysis
- Docker — local reproduction of the challenge environment
- Python `requests` — automated exploit scripting
