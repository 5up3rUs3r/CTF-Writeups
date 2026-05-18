# Lore of the world - The beginnings (100 pts - OSINT)

## Challenge Description

> I found some remnants of a (now archived), but recent world in the Mythical Block Game. Apparently, some odd moustachioed man finished building this approximately half a year ago. Many people considered this his best build yet. But I don't care for this build, I care for what began it all, in the same exact world. What's the name of the starter base of this handsome fella?

## TL;DR

Hermitcraft Season 10 OSINT — identified MumboJumbo from the "moustachioed man" clue, then found the name of his Season 10 starter base from the Hermitcraft Wiki.

## Initial Analysis

Key clues:
- "Mythical Block Game" = **Minecraft**
- "Archived, but recent world" = **Hermitcraft Season 10** (ended September 2025, then archived publicly)
- "Moustachioed man" = **MumboJumbo (Oli)**, Hermitcraft's most recognisable moustache-bearer
- "His best build yet" = MumboJumbo's Season 10 mega-base on **Magic Mountain**
- The question asks for the **starter base** — the temporary base built at the very start of the season

## Solution

### Step 1: Identify the server

The provided screenshot showed a cyberpunk city on floating terrain with a Pac-Man pixel art building and a "GEM" sign — hallmarks of Hermitcraft Season 10's Magic Mountain district.

### Step 2: Identify the hermit

MumboJumbo is famous in the Hermitcraft community for his moustache. His Season 10 mega-base on Magic Mountain was widely praised as among his finest work.

### Step 3: Find the starter base name

From the Hermitcraft Wiki (hermitcraft.fandom.com):
> MumboJumbo's Season 10 starter base was called **"The Mothball"** — a unique hanging structure built into the side of Magic Mountain with no entrance door. The only way in was to die and respawn inside.

## Flag

```
SK-CERT{Mothball}
```

## Key Takeaways

- **"Mythical Block Game"** = Minecraft — always decode themed challenge descriptions literally
- The **Hermitcraft Wiki** (hermitcraft.fandom.com) is the definitive reference for build names, player lore, and season history
- "Starter base" is Hermitcraft terminology for the first temporary base built at the start of a season, before the permanent mega-base

## Tools Used

- Hermitcraft Wiki (hermitcraft.fandom.com) — build name research
- Google Image Search — screenshot landmark identification
