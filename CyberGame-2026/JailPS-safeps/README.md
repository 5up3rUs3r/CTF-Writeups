# JailPS - safeps (100 pts - Offensive Security)

## Challenge Description

> A restricted PowerShell environment. Escape it and read the flag.

## TL;DR

PowerShell constrained language mode bypass by clearing the `__PSLockDownPolicy` environment variable, allowing a child process to spawn with full language mode.

## Initial Analysis

Connecting dropped into a restricted PowerShell session:

```powershell
$ExecutionContext.SessionState.LanguageMode
# Output: ConstrainedLanguage
```

Script blocks, `Add-Type`, and many cmdlets were blocked. However, the restriction was enforced via the `__PSLockDownPolicy` environment variable rather than at the OS level.

## Solution

### Step 1: Identify the enforcement mechanism

PowerShell checks `$env:__PSLockDownPolicy` at session start to determine language mode. If it's cleared in the current session, child processes don't inherit the policy.

### Step 2: Clear the policy and spawn unrestricted child

```powershell
$env:__PSLockDownPolicy = ""
powershell -noprofile -command "Get-Content flag.txt"
```

The child `powershell.exe` starts in `FullLanguage` mode, reads the flag, and prints it.

## Flag

```
SK-CERT{1_l0v3_p0w45h3LLz_h0P3_u2}
```

## Key Takeaways

- **`__PSLockDownPolicy`** is the environment variable controlling PS language mode — clearing it breaks the restriction for child processes
- Spawning a child `powershell.exe` is the simplest escape when the policy isn't enforced at the OS/AppLocker level
- Always check `$ExecutionContext.SessionState.LanguageMode` first to understand what's restricted

## Tools Used

- PowerShell — native environment variable manipulation
