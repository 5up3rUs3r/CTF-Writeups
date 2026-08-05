# Hydra — Rev (500 pts, 14 solves) — NOT SOLVED

**Author:** tahaafarooq

## Description

"Cut off one head, two more shall take its place! Hail Hydra!" A small (14.9KB), statically-linked, stripped ELF with custom section names (`hydratext`, `hycode`, `hytab`, `hytgt` instead of standard `.text`/`.data`), each holding self-decrypting blobs behind magic markers (`HYDRA.TABLES.V1!`, `HYDRA.INNERCODE!`, `HYDRA.TARGET.ENC`).

## What We Proved

- **Cipher fully identified:** the binary's self-decryption uses **XORSHIFT64\*** (state update `x^=x>>12; x^=x<<25; x^=x>>27`, output `= state × 0x2545F4914F6CDD1D`), seeded with the golden-ratio constant `0x9E3779B97F4A7C15` for the `hytab` (lookup table) section. Reimplemented in pure Python and verified **byte-for-byte identical** to the binary's own runtime-decrypted memory (dumped live via GDB).
- **Anti-debug fully defeated:** a function reads `/proc/self/status`, checks the digit immediately after `TracerPid:`. If it's `'0'` (untraced), returns a clean constant `0x6A09E667F3BCC908` (a SHA-256 IV word); otherwise XORs it with `0x3C6EF372FE94F82B` to poison downstream key material. Confirmed by disassembly and dynamically bypassed (`set $rax = 0x6A09E667F3BCC908` at the return point).
- **Verification structure mapped:** the program prompts `[hydra] head count:`, reads a line, and checks `custom_hash(input) == fixed_32_byte_target`. The target is decrypted from the `hytgt` section using a seed built from `anti_debug_const XOR FNV1a(input) XOR VM_output(input)`.
- **Confirmed the target side of the comparison is a fixed constant**, independent of input (`b96833fb7e737ceeb29430a952489be5a10fd82cef54a873787c5194ffc1e5bd` — verified identical across three different test inputs). This proves the check is genuinely `custom_hash(flag) == <this fixed target>`, not some circular self-referential trick.
- **Confirmed the check has full avalanche** (changing one input byte changes the entire 32-byte hash output) via direct testing — ruling out any block-independent brute-force shortcut.
- **The "VM" is a custom bytecode interpreter**, not a simple hash: it dispatches ~12 different "programs" across 48 rounds, each program decrypted on-the-fly from the `hycode` section via the same XORSHIFT64* cipher with a per-round seed, executing opcodes for ADD/SUB/XOR/AND/OR/ROL/NOT/BSWAP/MUL/LOAD/STORE (partially mapped from the jump-table dispatcher at `0x401673`), folding results into a running hash via what looks like an FNV1a-style multiply-XOR accumulator (`0xcbf29ce484222325` FNV offset basis and `0x100000001b3` FNV prime constants both appear directly in the disassembly).

## Where We Got Stuck

Finding the **preimage** of the fixed 32-byte target under this custom 48-round VM-driven hash. This requires either:
1. A **complete Python reimplementation** of the VM ISA (every opcode's exact semantics, the full 48-round program-selection schedule, and the FNV-style folding step) to build an offline solver, or
2. A **Unicorn Engine**-based black-box oracle that just runs the binary's own logic natively and searches for the correct input without needing to understand every internal detail.

Neither was completed in the time available — this is a genuinely deep, deliberately one-way construction (hence the highest point value and lowest confirmed structural information leakage of any challenge attempted this event).

## Ideas for Next Attempt

- Prioritize a **Unicorn Engine harness** over further manual VM tracing — treating the binary as an oracle (feed candidate input, read the 32-byte "input-side" hash output at the comparison point via emulated execution) sidesteps needing to fully understand all 12 VM "programs," and would let a genetic/gradient search or a meet-in-the-middle approach make progress instead of pure brute force.
- The 48-round structure and multiple "programs" strongly suggest **each round only depends on a small slice of prior state** — worth checking for a differential/round-reduction shortcut once a working emulator exists.
- Given a full anti-debug bypass and byte-exact cipher reimplementation were both completed, the *engineering* foundation is fully in place — what's missing is purely the VM-ISA emulator, which is a bounded, well-scoped remaining task.

## Important Note — Conflicting Findings Across Sessions

This challenge was independently attempted in **at least three separate work sessions** (parallel team members and/or repeated attempts), and the technical characterizations **do not agree** with each other:

| Session | Architecture | Cipher identified | Other findings |
|---|---|---|---|
| This writeup (session 2) | x86-64, statically-linked, stripped | XORSHIFT64* | Anti-debug via `/proc/self/status`, FNV1a-folded 48-round VM hash, byte-exact GDB verification |
| "CTF challenges" session | (implied x86-64 given `hytgt`/`hycode`/`hytab` section names match) | splitmix64-style | `code_hash = 0x8045716a64e3cd24`, `vm_hash = 0x818d935f6c4550d2`; exhausted all 6 anti-debug branch outcomes, none gave a printable flag; concluded either an undiscovered code path exists or the solve mechanism differs from what was analyzed |
| "Capture the flag competition strategy" session | **aarch64** | **BLAKE2b-IV-seeded**, described as a "signal-fault-driven" self-modifying VM | An `angr` symbolic-execution attempt failed on SIMD lifting errors in VEX IR; concluded full emulation needs live dynamic tracing on real hardware, not static/symbolic analysis |

**This is a real discrepancy, not just three framings of the same finding** — the architecture claim alone (x86-64 vs. aarch64) can't both be right for the same binary. Possible explanations, none confirmed:
- Different team members downloaded genuinely **different per-team/per-attempt challenge instances** (some CTF platforms serve unique binaries per team) — the shared "Hydra"/"heads" theme and section-naming convention would still match even if underlying implementation details (cipher choice, target architecture) differ.
- One or more of the three analyses contains an error (e.g., misidentifying the cipher family from partial constant matches — XORSHIFT64* and splitmix64 do share superficial similarity in that both are non-cryptographic 64-bit PRNGs used as keystream generators).

**Before starting a fresh attempt, first confirm which binary you actually have** (check `file <binary>` for architecture, and diff section layouts/hashes against the above) rather than assuming any single one of these three write-ups describes your copy.
