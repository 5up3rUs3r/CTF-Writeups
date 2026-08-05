# Locksmith — Rev (Hard, 300 pts, 9 solves)

**Author:** DR programmer
**Recovered key:** `R00tK1l1M4nj4r02`
**Flag:** `r00t{8_r0und_CBC_subst1tut10n_n3tw0rk__inv3rt_ev3ry_g34r_t0_keygen}`

## Description

"Sixteen characters, and only the summit key opens it." The description explicitly warns that *patching the comparison check won't help* — the binary only reveals the sealed flag when fed the **actual correct key**, not merely a key that passes validation. This rules out patch-and-skip approaches and forces a genuine keygen.

## Analysis

Static analysis in radare2, dumping the relevant data tables (`table1`, `target`, `rotA`/`rotB` rotation-amount tables, and two S-boxes) from `0x402080` onward:

```
p8 768 @ 0x402080
```

The validation logic runs the candidate 16-byte key through an **8-round CBC-style substitution/rotation network**:

- Each round applies an S-box substitution (two separate S-boxes used across rounds), then a byte rotation by a per-round amount from `rotA`/`rotB`.
- Each round chains into the next similar to CBC block chaining (each round's output feeds as part of the input transform for the next).
- The final round's output is compared against a fixed 16-byte `target`.

Both S-boxes were confirmed to be **valid bijections** (full 256-entry permutations, invertible), and the rotation amounts are fixed, known constants — meaning the entire 8-round chain is invertible in closed form, exactly like Clockwork.

## Solve Approach

1. Extracted `table1`, `target`, `rotA`, `rotB`, and both S-boxes directly from the binary's data section.
2. Verified both S-boxes are bijections by checking all 256 output values are unique.
3. Built the inverse S-boxes and wrote a Python function that runs the 8-round chain **backward**: starting from `target`, undo the final round's rotation then inverse-S-box, then repeat for each earlier round.
4. Recovered the raw key: `R00tK1l1M4nj4r02`.
5. With the real key confirmed, the binary's own logic unseals the embedded flag (since the check requires the *actual* key, not just a passing one) — recovering `r00t{8_r0und_CBC_subst1tut10n_n3tw0rk__inv3rt_ev3ry_g34r_t0_keygen}` directly from the inversion process.

## Verification

```
$ echo 'R00tK1l1M4nj4r02' | ./locksmith
PerfectRoot License Daemon v2.7
Enter license key: License valid. Unsealing... r00t{8_r0und_CBC_subst1tut10n_n3tw0rk__inv3rt_ev3ry_g34r_t0_keygen}
```

## Lesson

When a challenge explicitly warns that patching the check is a dead end, that's a strong signal the actual key material is needed for a *second* purpose (here, unsealing embedded data) — confirming the intended path is genuine inversion/keygen, not a bypass.
