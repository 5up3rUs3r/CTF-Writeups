# Lore of the world - Bureaucracy (176 pts - OSINT)

## Challenge Description

> Apparently, this building is among the most hated, not because of the person, but because of what it stands for. A lot of people had (or rather tried) to fill in some kind of document, but unfortunately, due to a really messy bureaucracy, most of them failed. I need to find the document's name.

## TL;DR

Hermitcraft Season 10 OSINT — identified Grian's Permit Office from the screenshot and researched the specific form number hermits were required to submit.

## Initial Analysis

Key clues:
- "Most hated building" for what it represents = **Grian's Permit Office**, the most notorious bureaucratic mechanic of Season 10
- "Messy bureaucracy, most of them failed" = hermits struggled with deliberately confusing paperwork
- The screenshot showed a large industrial interior with chains, sea lanterns, and a waiting-room layout

## Solution

### Step 1: Identify the building

The Permit Office (Department of Hermit Permits) was run by Grian, GoodTimesWithScar, Cubfan135, and Skizzleman. Hermits were forced to submit permit applications for any builds in the Shopping District — and the forms were intentionally confusing.

### Step 2: Find the document name

From the Hermitcraft Wiki:
> The form required of all hermits was **Form MJYAAFK06** — a deliberately obscure alphanumeric code that made the process frustrating.

The form number became a recurring joke across many hermit episodes and is documented on the Hermitcraft Season 10 wiki page.

## Flag

```
SK-CERT{MJYAAFK06}
```

## Key Takeaways

- **Season-specific community lore** requires either watching episodes or using the Hermitcraft Wiki — there is no shortcut
- The Permit Office was one of Season 10's defining social mechanics, well-documented in community resources
- Flag format clue: the document number itself, not a description of it

## Tools Used

- Hermitcraft Wiki (hermitcraft.fandom.com) — form number research
- Google — "Hermitcraft Season 10 Permit Office form number"
