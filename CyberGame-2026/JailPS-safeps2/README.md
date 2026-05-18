# JailPS - safeps2 (116 pts - Offensive Security)

## Challenge Description

> The previous escape was patched. Find another way out.

## TL;DR

Advanced PowerShell jailbreak — the `__PSLockDownPolicy` trick was patched, but the argument filter only blocked ASCII space (0x20) while leaving tab (0x09) unfiltered, enabling bypass via tab-separated arguments.

## Initial Analysis

The environment variable approach from safeps no longer worked. The jail had a custom argument filter that scanned for literal space characters between PowerShell arguments. However, the filter used a simple string comparison against `" "` (0x20) only.

## Solution

### Step 1: Identify the whitespace gap

PowerShell accepts tab characters (`\t`, 0x09) as valid argument separators, identical to spaces in argument parsing. The filter only checked for ASCII space.

### Step 2: Substitute tabs for spaces

Using backtick-t as the tab escape in the PowerShell session:

```powershell
powershell`t-noprofile`t-command`t"Get-Content flag.txt"
```

Or sending raw tab bytes via the connection:

```python
payload = "powershell\t-noprofile\t-command\t\"Get-Content flag.txt\"\n"
```

## Flag

```
SK-CERT{pow3R5H3LL_d03n7_C4r3_b0u7_5p4c3zzz}
```

The flag itself encodes the lesson: "PowerShell doesn't care about spacezzz" — confirming the tab bypass was intended.

## Key Takeaways

- **Whitespace filter bypass** — blocklists checking only `0x20` miss tab (`0x09`), non-breaking space (`0xA0`), and other Unicode whitespace
- PowerShell treats all whitespace variants as valid argument separators
- The safeps → safeps2 progression shows how incomplete patches introduce new attack surfaces

## Tools Used

- PowerShell — tab character injection
- Python `socket` — raw payload delivery
