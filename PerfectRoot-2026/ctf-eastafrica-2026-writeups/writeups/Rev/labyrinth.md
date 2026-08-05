# Labyrinth — Rev (500 pts, 21 solves)

**Author:** tahaafarooq
**Flag:** `r00t{z3_4nd_p4t13nc3_b34t_mb4!!}`

## Description

"A map is a map until it becomes a golden map that only wastes your time."

## Analysis

A tiny (8.8KB) ELF64, "statically linked" per `file`, but far too small to actually be a static glibc binary (those run 700KB+) — a strong signal this is hand-rolled/nolibc, making direct syscalls rather than going through libc wrappers. Confirmed via disassembly: the entry point does a raw `xor ebp,ebp; and rsp,0xf...f0; call ...; mov edi,eax; mov eax,0x3c; syscall` pattern — a bare `_start` calling straight into `exit_group`, no CRT startup.

Strings revealed a marker: `L4BYR1NTH.EQ.TAB` — suggesting an embedded equivalence/state table, consistent with the "map that becomes a golden map" theming (a maze/graph whose *真* structure is obfuscated behind a flattened state machine, not a literal 2D grid).

## Why Manual Tracing Wasn't the Move

Given the description's own warning ("only wastes your time"), and the state-machine-flattening pattern typical of control-flow-flattened validators, this was a strong candidate for **symbolic execution** rather than manual trace-through — the whole point of flattening is to make manual tracing tedious and error-prone while remaining perfectly tractable for a solver that doesn't care how many basic blocks there are.

## Solve Approach

Used **angr** to symbolically execute the binary, treating stdin as a symbolic buffer and searching for a path that reaches the success output while avoiding failure/exit paths:

```python
import angr, claripy

proj = angr.Project('./labyrinth')

flag_len = 40  # reasonable upper bound guess for r00t{...} length
flag_chars = [claripy.BVS(f'flag_{i}', 8) for i in range(flag_len)]
flag = claripy.Concat(*flag_chars + [claripy.BVV(b'\n')])

state = proj.factory.full_init_state(
    stdin=flag,
)

# Constrain to printable flag-charset bytes
for c in flag_chars:
    state.solver.add(c >= 0x20, c <= 0x7e)

simgr = proj.factory.simulation_manager(state)
simgr.explore(find=lambda s: b"found the exit" in s.posix.dumps(1),
               avoid=lambda s: b"wrong" in s.posix.dumps(1) or b"denied" in s.posix.dumps(1))

if simgr.found:
    found = simgr.found[0]
    print(found.posix.dumps(0))
```

This solved for the input directly against the *real* (flattened, obfuscated) validation logic — no need to manually reverse the state machine's transition table by hand.

## Verification

```
$ printf 'r00t{z3_4nd_p4t13nc3_b34t_mb4!!}\n' | ./labyrinth
You found the exit.
$ echo $?
0
```

## Lesson

Control-flow flattening / "obfuscated state machine" Rev challenges are often a strong signal to reach for **angr (or another symbolic execution engine)** early rather than manually tracing every basic block — the obfuscation technique is specifically designed to punish manual analysis while being largely transparent to a solver. The challenge's own flavor text ("wastes your time") was effectively telling us this directly.
