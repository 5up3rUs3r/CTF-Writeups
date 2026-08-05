# East Africa Intervarsity CTF 2026 — Qualification Round Writeups

**Team:** Crypt1c_L0rds (soph0s, Ghost_Ops, 5up3rU53r, Vena, Torii)
**Final result:** Position 13 · 8,460 team points · 3,210 personal points
**Flag format:** `r00t{...}`

This repo documents the challenges worked during the qualification round. The full official challenge roster (38 challenges) is listed below with an honest status for each:

- **📗 Documented** — full writeup in this repo, technique + working flag
- **📙 Partial notes** — some investigation captured, no full flag/writeup
- **📕 Team solved, undocumented** — the team got this one (per the platform), but it wasn't worked in any session traceable to this Claude account, so there's no writeup here. **If you or a teammate has the details, please add a writeup** — these are real gaps, not "unsolved."
- **📓 Open / not solved** — genuinely unsolved by anyone on the team as of writing; writeup documents verified partial progress and dead ends for a future attempt.

## Full Roster

### Crypto

| Challenge | Points | Solves | Status |
|---|---|---|---|
| Trusted Courier | 100 | 21 | 📕 Team solved, undocumented |
| Shared Grounds | 100 | 29 | 📕 Team solved, undocumented |
| Blind Spot | 100 | 29 | 📕 Team solved, undocumented |
| [Thin Ice](Crypto/thin-ice.md) | 100 | 28 | 📗 Documented |
| Related Party | 200 | 27 | 📕 Team solved, undocumented |
| [Slipstream](Crypto/slipstream-unsolved.md) | 200 | 10 | 📓 Open |
| Salvation | 200 | 25 | 📕 Team solved, undocumented |
| Trinity | 200 | 27 | 📕 Team solved, undocumented |
| Signing Off | 200 | 14 | 📕 Team solved, undocumented |
| Copenhagen | 300 | 25 | 📕 Team solved, undocumented |
| Glitch in the Vault | 300 | 25 | 📕 Team solved, undocumented |
| [Phantom Nonce](Crypto/phantom-nonce.md) | 450 | 24 | 📗 Documented |
| Last Line of Defense | 500 | 19 | 📕 Team solved, undocumented |
| Static Noise | 500 | 21 | 📕 Team solved, undocumented |

### Forensics

| Challenge | Points | Solves | Status |
|---|---|---|---|
| [UnderStudy](Forensics/understudy.md) | 150 | 18 | 📗 Documented |
| [Ghost Shift](Forensics/ghost-shift-unsolved.md) | 200 | 12 | 📓 Open |
| [Wiretap](Forensics/wiretap.md) | 400 | 16 | 📗 Documented |

### Misc

| Challenge | Points | Solves | Status |
|---|---|---|---|
| Welcome | 10 | 28 | 📕 Team solved, undocumented (see [note](Misc/welcome.md)) |
| [Beacon — *The Uhuru Torch*](Misc/beacon.md) | 400 | 21 | 📙 Partial notes (decoy flag found; team solved it, real solve not captured here) |

### Pwn

| Challenge | Points | Solves | Status |
|---|---|---|---|
| Death Note | 100 | 18 | 📕 Team solved, undocumented |
| [Safe Gets](Pwn/safe-gets.md) | 100 | 17 | 📗 Documented |
| [Warden](Pwn/warden.md) | 200 | 27 | 📗 Documented |

### Quantum

| Challenge | Points | Solves | Status |
|---|---|---|---|
| [Gaussian Echo](Quantum/gaussian-echo-unsolved.md) | 300 | 9 | 📓 Open |
| [Hidden Order](Quantum/hidden-order.md) | 300 | 25 | 📗 Documented |

### Rev

| Challenge | Points | Solves | Status |
|---|---|---|---|
| [Locksmith](Rev/locksmith.md) | 300 | 22 | 📗 Documented |
| [Vault Keeper](Rev/vault-keeper.md) | 300 | 23 | 📗 Documented |
| [Clockwork](Rev/clockwork.md) | 400 | 24 | 📗 Documented |
| Ghost Writer | 500 | 18 | 📕 Team solved, undocumented |
| VMPrison | 500 | 16 | 📕 Team solved, undocumented |
| [Hydra](Rev/hydra-unsolved.md) | 500 | 14 | 📓 Open |
| Hookline | 500 | 18 | 📕 Team solved, undocumented |
| [Labyrinth](Rev/labyrinth.md) | 500 | 21 | 📗 Documented |

### Web

| Challenge | Points | Solves | Status |
|---|---|---|---|
| [Open Door](Web/open-door.md) | 100 | 24 | 📗 Documented |
| [Secure Storage Prod](Web/secure-storage-prod-notes.md) | 100 | 17 | 📙 Partial notes (team solved it, our own approach unfinished) |
| Trust Fall | 150 | 22 | 📕 Team solved, undocumented |
| Secure Storage UAT | 200 | 17 | 📕 Team solved, undocumented |
| [Relative Descent](Web/relative-descent-unsolved.md) | 200 | 8 | 📓 Open |
| [Chain of Custody](Web/chain-of-custody-unsolved.md) | 200 | 9 | 📓 Open |

## Summary

- **12 fully documented** with working flags and complete technique writeups (Thin Ice, Phantom Nonce, UnderStudy, Wiretap, Safe Gets, Warden, Hidden Order, Locksmith, Vault Keeper, Clockwork, Labyrinth, Open Door)
- **2 with partial notes** (Beacon, Secure Storage Prod) — team solved, our own investigation didn't reach the flag
- **6 documented as genuinely open** (Slipstream, Ghost Shift, Gaussian Echo, Hydra, Relative Descent, Chain of Custody) — verified partial progress captured for a future attempt
- **18 team-solved but completely undocumented here** (including "Welcome," see its [note](Misc/welcome.md)) — these need a teammate's input to write up; nothing in this Claude account's history covers them

## A Note on Methodology — Multiple Parallel Sessions

This event was worked across **several separate chat sessions** (and, per the team's usual practice, multiple AI tools run in parallel), not one continuous thread. This repo consolidates findings from every session traceable to this Claude account. Two things worth knowing if you're extending this repo:

1. **Some challenges were attempted more than once, independently, with different results.** Most notably, **Hydra** has three separate technical analyses across three sessions that disagree on core facts (target architecture, cipher family) — see the note at the bottom of [`Rev/hydra-unsolved.md`](Rev/hydra-unsolved.md) before trusting any single one of them at face value.
2. **The 📕 "team solved, undocumented" challenges are real gaps, not oversights.** They were solved by the team (per the official roster you provided) via other tools/accounts/teammates not visible in this Claude account's history. If you want a complete writeup repo, those 17 need input from whoever actually solved them.

## Key Lessons for Next Time

1. **Tooling gaps cost us on the "last mile."** Several challenges (Hydra, Gaussian Echo, Ghost Shift) were fully understood conceptually but stalled on a final brute-force/decode step that a proper scripting harness (Unicorn Engine for VM emulation, a systematic XOR crib-drag tool) would have closed faster.
2. **Platform bugs happen — don't burn time doubting solid math.** Thin Ice and Wiretap both had a period where our cryptanalysis was provably correct but the flag was rejected due to a platform-side data regeneration bug. Recognize the "the math is airtight but it's rejected" signal and consider checking with organizers/Discord early.
3. **`r00t{32-hex-char}` was a recurring flag shape** in this event — worth testing early on any successfully-decrypted-but-unformatted secret.
4. **When multiple independent verifications agree** (e.g., LCG parameters re-derived from early vs. late block triples giving bit-identical results), that's strong confirmation the *cryptography* is right — remaining failures are almost always in the *interpretation/encoding* layer, not the math.
5. **Control-flow-flattened/obfuscated state machines (Labyrinth) are a strong signal to reach for angr early**, rather than manually tracing every basic block — that's exactly the analysis cost the obfuscation is designed to impose.
