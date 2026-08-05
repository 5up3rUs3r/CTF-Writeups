# Clockwork — Rev (400 pts, 10 solves)

**Flag:** `r00t{tw0_stage_0bfusc4t3d_VM__d3c0d3_0pc0d3s_th3n_1nv3rt_b0th_g34rs_DRp}`

## Description

A statically-linked "PerfectRoot Clockwork Licence Machine (mk.II)" binary reads a key on stdin (`key> `) and checks it against embedded validation logic.

## Analysis

Reversed with radare2 (`r2 -A clockwork`, `pdf @ main`). The binary:

1. Reads input, requires exactly **72 characters** (`cmp rax, 0x48`) — matching `r00t{` + N + `}` for a specific flag length.
2. Runs input through a **custom byte-oriented VM**: a switch-based dispatcher (37 cases) selecting per-character opcodes from an embedded table, driving a two-pass obfuscation pipeline.

Traced the VM's semantics completely — it is **not a general-purpose loop requiring brute force**, but a fixed, fully deterministic two-pass transform per character:

- **Pass 1** (builds `outbuf`): `acc = key[i]; acc += addTable[i]; acc ^= r11; acc = ROL(acc, rotW[i])` — with `r11` carrying the *previous output byte* as feedback (not some hidden state — just simple chaining).
- **Pass 2**: an S-box substitution (`sbox`, a full 256-entry permutation) → modular addition → rotation, using a separate `mulTable` of all-odd (hence invertible mod 256) multipliers.

Since both the S-box and multiplier table are **bijective on bytes**, the entire pipeline is invertible in closed form — no brute force needed.

## Solve Approach

1. Extracted all embedded tables (`addTable`, `rotW`, `sbox`, `mulTable`) from the binary's data sections.
2. Verified the S-box is a full permutation (256 unique outputs) and every `mulTable` entry is odd (hence has a modular inverse mod 256).
3. Wrote a Python inverter that reverses Pass 2 then Pass 1 per character, working backward from the embedded target-comparison bytes.
4. Ran the inverter to recover the full 72-character key directly — no guessing.

## Verification

```
$ echo 'r00t{tw0_stage_0bfusc4t3d_VM__d3c0d3_0pc0d3s_th3n_1nv3rt_b0th_g34rs_DRp}' | ./clockwork
PerfectRoot Clockwork Licence Machine (mk.II)
key> The clockwork aligns. Correct!
```

## Lesson

Not every VM-based Rev challenge needs an emulator/brute-force harness — tracing opcode semantics by hand first can reveal the whole thing is invertible, which is far faster than building tooling.
