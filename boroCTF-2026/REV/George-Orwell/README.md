# George Orwell (REV)

## Challenge Description

> Big Brother is always watching. Perhaps too literally.

**File:** `big_brother` (PE32 executable for MS Windows, 913920 bytes)  
**Flag Format:** `boroCTF{...}`

## TL;DR

A compiled AutoHotkey (AHK) executable functioning as a keylogger. The AHK source script was recoverable directly via `strings`, revealing a hotstring trigger that assembled the flag character-by-character using `Chr()` calls.

## Initial Analysis

### Step 1: File recon

```bash
ls -la
# big_brother  913920 bytes
file big_brother
# PE32 executable (GUI) Intel 80386, for MS Windows
strings big_brother | grep -iE "key|hook|log|SetWindows"
```

Key strings found:
- `SetWindowsHookExW` — Windows API for installing a global keyboard hook
- `GetAsyncKeyState` — keyboard state polling API
- `AutoHotkey` — embedded string confirming this is a compiled AHK script

### Step 2: Spot the hotstring trigger

```bash
strings big_brother | grep -A 50 "iloveboroctf"
```

Found at the end of output:

```
:*:iloveboroctf::
```

This is an AutoHotkey hotstring — typing `iloveboroctf` anywhere triggers the replacement block.

## Solution

### Step 3: Recover the full AHK source from strings output

```ahk
:*:iloveboroctf::
secret := Chr(98) . Chr(111) . Chr(114) . Chr(111) . Chr(67) . Chr(84) . Chr(70) . Chr(123)
secret := secret . Chr(65) . Chr(72) . Chr(75) . Chr(95) . Chr(49) . Chr(115) . Chr(95)
secret := secret . Chr(108) . Chr(73) . Chr(115) . Chr(43) . Chr(101) . Chr(110) . Chr(105)
secret := secret . Chr(52) . Chr(103) . Chr(125)
MsgBox, 64, System Notification, Access Granted!`n`nFlag: %secret%
```

### Step 4: Decode the Chr() values

```python
chars = [
    98,111,114,111,67,84,70,123,
    65,72,75,95,49,115,95,
    108,73,115,43,101,110,105,
    52,103,125
]
print(''.join(chr(c) for c in chars))
```

Output: `boroCTF{AHK_1s_lIs+eni4g}`

## Flag

```
boroCTF{AHK_1s_lIs+eni4g}
```

## Key Takeaways

- **Compiled AHK scripts preserve source** — AutoHotkey compiles by bundling the interpreter with the source. The script text survives in the PE binary and is recoverable with `strings`.
- **Keylogger API fingerprints** — `SetWindowsHookExW` + `GetAsyncKeyState` in the import strings is an immediate keylogger indicator before any deeper analysis.
- **`Chr()` obfuscation** — assembling strings from ASCII ordinals is trivially reversed once the source is recovered; the only challenge is knowing to look for it.

## Tools Used

- `file` — PE format identification
- `strings` — AHK source recovery and `Chr()` extraction
- `python3` — ordinal-to-character decoding
