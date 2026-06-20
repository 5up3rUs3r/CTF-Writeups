# Next Challenge (PWN)

## Challenge Description

> nc means Next Challenge... that MAN has more answers

**Server:** `nc thww9zyp6ygt.boroctf.com 19350`  
**No binary attachment**  
**Flag Format:** `boroCTF{...}`

## TL;DR

A `netcat` service running a VULNBOT menu. Selecting `flag` and confirming `y` to the follow-up prompt yields the flag. The challenge title hint was a pun: `nc` = netcat, and `man nc` (the netcat manual page) is where the "answers" live.

## Solution

### Step 1: Connect to the service

```bash
nc thww9zyp6ygt.boroctf.com 19350
```

The service presented a VULNBOT menu with two commands: `cheese` and `flag`.

### Step 2: Request the flag

```
> flag
Are you SURE you don't want to see what the Cheese option does? (y/n)
> y
FINE. I guess if you insist. boroCTF{0nLinE_C@ts*}
```

The service asked for confirmation; replying `y` yielded the flag immediately.

## Flag

```
boroCTF{0nLinE_C@ts*}
```

## Key Takeaways

- **Warm-up challenges reward patience** — no binary analysis needed; connect, read the menu, and follow the prompts all the way through.
- **Hint parsing** — "nc means Next Challenge... that MAN has more answers" = `man nc` → netcat manual; the entire challenge was about knowing how and when to use `nc`.

## Tools Used

- `nc` (netcat) — service interaction
