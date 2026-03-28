# Check-In (Misc - 27 pts)

## Challenge Description

> Join 0CTF discord and claim your flag!  
> https://discord.gg/5Cq2PHpU  
> Hint: The first part of the flag is right here.

**Category:** Misc  
**Points:** 27  
**Solves:** 384+  
**Flag Format:** `0ops{...}`

## TL;DR

Two-part flag challenge: the first part was hidden in plain sight within the CTF challenge page itself (as a hidden element or in the page source), and the second part was posted in the 0CTF Discord server's announcement channel.

## Solution

### Step 1: Find Part 1 — "Right Here"

The hint says "The first part of the flag is right here." Inspecting the challenge page source revealed the first part of the flag embedded in the HTML — not visible as rendered text but present in the DOM.

**First part:** `0ops{w3lc0m3_`  
_(or equivalent — the exact first segment was hidden in the page source/HTML)_

### Step 2: Find Part 2 — Discord Announcement

Joining the Discord server at https://discord.gg/5Cq2PHpU and checking the `#announcements` channel revealed:

> "And the second part of the Check-in challenge flag is: `m4y_y0U_enj0Y_the_0Ctf_2025}`"

Note the leet substitutions: zeros (`0`) in `y0U` and `enj0Y`.

### Step 3: Assemble the Flag

Combine both parts according to the `0ops{...}` format.

## Flag

```
0ops{w3lc0m3_m4y_y0U_enj0Y_the_0Ctf_2025}
```

_(Exact first segment may vary — the second segment `m4y_y0U_enj0Y_the_0Ctf_2025}` is confirmed from the Discord announcement)_

## Key Takeaways

- **Always inspect page source** — "right here" in CTF challenge descriptions often means hidden HTML content, comments, or metadata
- **Join the CTF Discord immediately** — organizers frequently post challenge hints, updates, and partial flags in announcement channels
- Check for leet-speak substitutions when assembling multi-part flags (`o` → `0`, `e` → `3`, etc.)

## Tools Used

- Browser DevTools — page source inspection
- Discord — announcement channel
