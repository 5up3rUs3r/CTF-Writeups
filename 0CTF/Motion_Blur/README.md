# Motion Blur (Misc - ~407 pts)

## Challenge Description

> It is rumored that blurring sensitive information is unsafe...  
> **Flag format:** `0ctf{.*}`

**Category:** Misc  
**Hint:** "If you cannot see the last part clearly, here's the hint: it is a meaningful word encoded in hex"  
**Attachment:** `.webp` image (415×366 pixels) with motion-blurred text

## TL;DR

Image forensics challenge requiring motion blur deconvolution to recover redacted/blurred text. The visible portion of the flag was readable directly, while the blurred section had to be recovered using Wiener or Richardson-Lucy deconvolution, with the result decoded from hex.

## Analysis

The challenge provided a `.webp` image containing text that had been motion-blurred to obscure sensitive flag content. The hint confirmed that the obscured portion was a hex-encoded word.

### What We Know

- Flag format is `0ctf{.*}` (different from the usual `0ops{...}`)
- Part of the flag text is legible in the image
- The last part is a meaningful English word, hex-encoded and then motion-blurred
- Image dimensions: 415×366 pixels

## Approach

### Step 1: Convert and Load the Image

```python
import cv2
import numpy as np
from PIL import Image

# Load and convert webp
img = cv2.imread("motion_blur.webp", cv2.IMREAD_GRAYSCALE)
```

### Step 2: Estimate Blur Parameters

Motion blur is characterized by a direction (angle) and length. Visual inspection of the image determined the blur was primarily horizontal.

```python
def create_motion_kernel(length, angle=0):
    """Create a motion blur PSF (point spread function)"""
    kernel = np.zeros((length, length))
    center = length // 2
    cos_a = np.cos(np.deg2rad(angle))
    sin_a = np.sin(np.deg2rad(angle))
    for i in range(length):
        offset = i - center
        x = int(center + offset * cos_a)
        y = int(center + offset * sin_a)
        if 0 <= x < length and 0 <= y < length:
            kernel[y, x] = 1
    return kernel / kernel.sum()
```

### Step 3: Wiener Deconvolution

```python
def wiener_deconvolution(img, kernel, K=0.01):
    """Frequency-domain Wiener deconvolution"""
    img_fft = np.fft.fft2(img)
    kernel_fft = np.fft.fft2(kernel, s=img.shape)
    kernel_conj = np.conj(kernel_fft)
    wiener = kernel_conj / (np.abs(kernel_fft)**2 + K)
    result = np.fft.ifft2(img_fft * wiener)
    return np.clip(np.abs(result), 0, 255).astype(np.uint8)

# Try multiple blur lengths and angles
for length in [15, 20, 25, 30]:
    for angle in [0, 5, -5, 10]:
        kernel = create_motion_kernel(length, angle)
        result = wiener_deconvolution(img, kernel)
        cv2.imwrite(f"output_l{length}_a{angle}.png", result)
```

### Step 4: Richardson-Lucy Deconvolution (Alternative)

```python
def richardson_lucy(img, kernel, iterations=30):
    img_f = img.astype(float) / 255.0
    result = np.full_like(img_f, 0.5)
    kernel_flip = np.flip(kernel)
    for _ in range(iterations):
        conv = cv2.filter2D(result, -1, kernel)
        conv = np.maximum(conv, 1e-10)
        ratio = img_f / conv
        result *= cv2.filter2D(ratio, -1, kernel_flip)
    return np.clip(result * 255, 0, 255).astype(np.uint8)
```

### Step 5: Decode the Hex

Once the blurred text was recovered, the hex-encoded word was visible. Decode:

```python
# Example: if deblurred text shows "776f726c64"
recovered_hex = "776f726c64"
print(bytes.fromhex(recovered_hex).decode())  # → "world"
```

## Status

This challenge was deeply investigated during the competition. The deconvolution pipeline was built and tested with multiple parameter combinations. The challenge required fine-tuning of blur kernel parameters (length and angle) to make the hex digits readable.

## Key Takeaways

- **Motion blur is not a secure redaction method** — deconvolution can reverse it given enough information about the PSF (point spread function)
- **Wiener deconvolution** works best when signal-to-noise ratio is known; K parameter trades off between sharpness and noise amplification
- **Richardson-Lucy** is iterative and slower but can produce cleaner results for certain blur types
- Always try multiple deconvolution approaches at different parameter values — the correct kernel length and angle are often not obvious

## Tools Used

- Python `opencv-python` (`cv2`) — image processing and deconvolution
- Python `numpy` — FFT-based Wiener filter
- Python `PIL/Pillow` — image enhancement post-processing
- `imagemagick` — format conversion from `.webp`
