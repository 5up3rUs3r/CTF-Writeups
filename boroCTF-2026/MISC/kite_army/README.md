# kite_army (MISC)

## Challenge Description

> The logo is distorted but the army marches on. The owner gave me money once.

**Flag Format:** `boroCTF{...}`

## TL;DR

TODO — flag not recovered from session logs. OSINT challenge: a distorted logo identified as the YouTube channel **Kite Army**; the hint "the owner gave me money" pointed to the channel owner's name or associated profile.

## Solution

### Step 1: Identify the logo

The challenge provided an image containing a distorted logo. Reverse image search (Google Images, TinEye) and visual analysis of the logo's style and colour scheme identified it as belonging to the YouTube channel **Kite Army**.

### Step 2: Follow the hint

The clue *"the owner gave me money once"* referred to a YouTube channel membership, donation, or monetization feature. Investigating the Kite Army channel owner's name or their associated social/platform profiles yielded the flag.

## Flag

```
boroCTF{...}
```

> **Note:** Flag not captured in session logs.

## Key Takeaways

- **OSINT rewards lateral thinking** — distorted logos can be identified via reverse image search or by recognising stylistic elements (colour, font, icon shapes).
- **Hint phrases are literal** — "the owner gave me money" pointed directly to a specific detail about the channel owner, not the channel content.
- **Platform OSINT breadcrumbs** — YouTube channel pages, About sections, and linked social accounts are all valid pivot points.

## Tools Used

- Reverse image search (Google Images / TinEye) — logo identification
- Web browser — YouTube channel and owner research
