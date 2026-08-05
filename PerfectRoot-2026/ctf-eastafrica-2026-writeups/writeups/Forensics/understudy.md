# UnderStudy — Forensics (Medium, 150 pts)

**Flag:** `r00t{HTTP/rendercache-internal.corvid.local_administrator_090217}`

## Description

`CORVID STUDIOS`' post-production pipeline went down for six hours. IT's initial read was "flaky render server." Then someone noticed a workstation's Security log was suspiciously empty. Six exported Windows Event Logs (`.evtx`) were provided across a DC, two workstations, and a render server (some with Sysmon).

Submission format: `r00t{compromised_credential_impacted_account_true_start_time}`
- `compromised_credential` — copied exactly as it appears in the evidence
- `impacted_account` — lowercase
- `true_start_time` — `HHMMSS`, 24-hour

## Tooling

`.evtx` files parsed with `python-evtx` (`pip3 install python-evtx --break-system-packages`), converted to XML per record for grepping/timeline reconstruction.

## Building the Timeline

Combining Sysmon (process creation, network connections) and Security logs (logons, Kerberos tickets, log clearing, scheduled tasks) across all six hosts, filtering decoy noise (routine `wren.ashworth` interactive logons, an admin's routine cleanup of disabled legacy service accounts):

| Time (UTC) | Event | Host |
|---|---|---|
| **09:02:17** | Malicious macro in `CallSheet_ProductionSchedule_v3.docm` spawns encoded PowerShell (Sysmon process-creation, parent=WINWORD.EXE) | WKS-WREN07 |
| 09:02:18 | C2 callback to `203.0.113.44:8080` | WKS-WREN07 |
| 09:22–09:36 | AD recon: `dsquery user`, `dsquery group`, `setspn -Q */*` (SPN enumeration) | WKS-WREN07 |
| **13:05:17** | Kerberoasting: TGS request for `HTTP/rendercache-internal.corvid.local` using **weak RC4** encryption (`TicketEncryptionType 0x17`) — every other ticket in the log uses AES256 (`0x12`) | WKS-WREN07 |
| 15:13:15–17 | Lateral movement: `svc_rendercache` local logon (LogonType 9, "runas /netonly" pattern — typical right after an offline password crack) → WinRM network logon (LogonType 3) | WREN07 → SRV-RENDER02 |
| **18:06:17** | **DCSync**: `svc_rendercache` requests `DS-Replication-Get-Changes`/`-All` extended rights directly on the `Administrator` object | SRV-RENDER02 → DC01 |
| 18:26:17 | Security log cleared (Event ID **1102**) by `svc_rendercache` | WKS-WREN07 |
| 18:29:17 | Malicious scheduled task `\RenderCacheSync` created (hidden PowerShell download-cradle) for persistence | WKS-WREN07 |

## Reasoning Through the Flag Fields

- **`compromised_credential`** — the description asks for the credential *exactly as it appears in the evidence*, which is a strong signal it's a literal string from the logs rather than a derived value. The Kerberoastable SPN, requested with deliberately weak RC4 encryption (the actual signature of a Kerberoasting attack, since RC4 tickets are crackable offline), is that literal string: `HTTP/rendercache-internal.corvid.local`.
- **`impacted_account`** — the *ultimate* target of the attack chain wasn't `svc_rendercache` (which was just the pivot/stepping-stone account compromised via Kerberoasting) — it was `administrator`, the account whose password hash was exfiltrated via the DCSync request.
- **`true_start_time`** — IT's "flaky render server" theory pointed to the later render-service disruption, but the *actual* start of the incident was the initial phishing macro execution at `09:02:17`, hours before any render-service symptoms appeared.

## Lesson

- Don't take the first "obvious" timestamp (the symptom IT initially reported) as the incident start — trace back to the actual initial-access event in the earliest available telemetry (here, Sysmon process creation).
- Distinguish the *compromised credential* (what got cracked) from the *impacted account* (what the attacker ultimately reached) — Kerberoasting chains often pivot through a lower-privilege service account before reaching the real target via a technique like DCSync.
- `TicketEncryptionType` mismatches (one RC4 ticket among a sea of AES256 ones) are a reliable, low-noise Kerberoasting indicator in Windows Security logs (Event ID 4769).
