# BeepCode (100 pts - Audio/Forensics)

## Challenge Description

> Something is hidden in this audio file. Can you hear it?

**File:** `out.wav` (66 seconds, 44100Hz, mono, 16-bit PCM)  
**Difficulty:** Easy

## TL;DR

The flag was rendered as readable text directly in the audio spectrogram at ~6kHz. Standard audio decoding approaches (DTMF, Morse) produced nothing — the technique was visual steganography in the frequency-time domain.

## Initial Analysis

### Step 1: Try obvious audio encoding formats

```bash
# DTMF decoding
multimon-ng -t wav -a DTMF out.wav
# → no output

# Morse code decoding
multimon-ng -t wav -a MORSE_CW out.wav
# → no output
```

Neither DTMF nor Morse decoding produced anything, ruling out the two most common audio steganography methods. The audio itself sounded like tones of varying frequency — not speech, not music.

## Solution

### Step 2: Generate a spectrogram

```bash
sox out.wav -n spectrogram -o spectrogram.png
```

Opening `spectrogram.png` revealed the flag written as plain text in the frequency-time domain, concentrated around the **6kHz frequency band**. The audio waveform was crafted so that specific frequencies are activated at specific times, causing the flag characters to appear as legible text in the spectrogram image.

This is a well-known CTF technique: synthesizing audio where the frequency content spells out text, exploiting the fact that spectrograms map frequency vs. time visually.

## Flag

```
r00t{f33ling_w4vy}
```

## Key Takeaways

- **Spectrograms reveal what ears can't hear** — when audio doesn't decode with DTMF, Morse, or steganography tools, always generate a spectrogram first.
- **`sox` is the fastest path** — `sox file.wav -n spectrogram -o out.png` is a one-liner that visualizes the full frequency-time content.
- Alternatively: Audacity → View → Spectrogram, or any online spectrogram tool, will show the same result.
- **The flag doesn't have to be hidden** — here it was literally drawn in frequencies. The "steganography" is just knowing to look at the right representation.

## Tools Used

- `multimon-ng` — DTMF and Morse decoding attempts
- `sox` — spectrogram generation
- Image viewer — reading the flag from `spectrogram.png`
