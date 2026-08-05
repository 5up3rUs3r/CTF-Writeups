# Ghost Shift — Forensics (Medium, 200 pts, 12 solves) — NOT SOLVED

**Author:** LordSudo

## Description

"`ord-api-03.prod.internal` was flagged by an anomaly alert shortly before midnight. On-call responders captured live triage output and a small set of process memory snapshots before the host was isolated for imaging. Your job: work out what actually happened, and pull back whatever the intruder was in the middle of staging."

Evidence: a vim swap file, `ps`/`ss`/`lsof` snapshots, and two process **core dumps** (`proc_backdoor.core`, `proc_tmux_server.core`).

## What We Proved

- **Identified the backdoor process** via `lsof`: PID 1682 masquerades in `ps` as `sshd: monitor`, but its actual binary is a deleted `.sshd-helper` with a deleted `.rootkit.so` mapped into memory, holding an active connection to `10.66.13.37:4444` (classic C2 port).
- **Recovered a shredded staged secret from the tmux core dump's scrollback buffer.** The full attacker session, reconstructed from `tmux` `send-keys` command logs preserved in memory:
  ```
  whoami
  id
  mkdir -p /tmp/.cache && echo cf2ba250b26ac121d89e7a7c4be63cc6 > /tmp/.cache/.k2
  cat /tmp/.cache/.k2
  history -c
  shred -u /tmp/.cache/.k2
  ```
  The attacker staged an MD5-length value, then immediately tried to destroy the evidence (`shred` + `history -c`) — but tmux's own in-memory scrollback survives process-core capture regardless, letting us recover it anyway.
- **Located an embedded, encrypted "C2 config" blob** inside `proc_backdoor.core`, marked by a plaintext header `C2CFG>>>MCR` followed by 69 bytes of high-entropy data, then length fields and unrelated ELF/libc symbol data (`read\0write\0` strings are just adjacent unrelated library symbols, not part of the blob).
- **Confirmed the vim swap file's "old" API key is an explicit decoy**: the recovered `.orders-api.conf.swp` content is annotated `# old_api_key: ... (ROTATED 2025-11-02 -- DO NOT USE, superseded)`.

## Where We Got Stuck

**Decoding the 69-byte C2 config blob.** Extensive XOR analysis against the staged `.k2` value (both as raw 16 bytes from hex, and as the literal 32-character ASCII string) never produced clean, readable plaintext:
- Single-byte XOR brute force (all 256 keys) — best printability score only ~48% (essentially random-chance baseline).
- Repeating multi-byte XOR with the ASCII `.k2` string at all 32 rotation offsets — one offset (`rot=0`, i.e. the key as-is) gave 68/69 fully-printable bytes, but the content itself was scrambled gibberish, not a coherent config string (ruled out as the correct key).
- RC4 with both the raw-16-byte and ASCII-32-byte forms of `.k2` as key — pure noise output.
- Crib-dragging for expected config content (`{`, `host`, `10.66.13.37`, `http`, `beacon`, `sleep`) at the blob's start — no clean, plausible key emerged.
- The `REQUEST_TRACE_ID` environment variable value (`4d21c5c2f2bb72af`, also present in the core) tried as an alternate XOR key, both raw-hex and ASCII forms — no improvement.
- Autocorrelation analysis of the blob did show a near-repeat at a ~32-byte offset (bytes 1–3 match between offset 0 and offset 32), suggesting *some* periodic structure, but never converged on a clean full decode.

Also attempted (and ruled out as **not** the answer) directly submitting the recovered staged value in various flag-wrap formats (`r00t{cf2ba250b26ac121d89e7a7c4be63cc6}`, uppercase, combined with the C2 IP/backdoor path) — all rejected.

## Ideas for Next Attempt

- The blob's plaintext may not be XOR-encoded against the `.k2` value at all — worth trying it as an **AES key** (raw 16 bytes) instead, in ECB/CTR mode, even though the blob length (69 bytes) isn't block-aligned for ECB/CBC (would need to identify the correct sub-range).
- Re-examine whether there's a **second staged value** (`.k1`?) implied by the `.k2` naming convention, that never got written/captured in this particular memory snapshot but might be inferable from context.
- The near-32-byte periodicity in the blob is a real, reproducible structural signal — worth a dedicated Kasiski-style key-length analysis rather than assuming the key is exactly the `.k2` value.
