# Telemetry (473 pts - Forensics)

## Challenge Description

> A suspicious drone flew over a wheat field. Investigate the telemetry data.

## TL;DR

MAVLink 2.0 drone telemetry forensics — a fake flag honeytoken distracted from the real flag encoded geographically in the GPS flight path. Parsed 477 GLOBAL_POSITION_INT packets, filtered the decoy cluster by median longitude, and visualised the remaining 474 waypoints to reveal letters drawn in the field.

## Initial Analysis

```bash
strings telemetry.data | grep "SK-CERT\|flag"
# Returns: flag{telemetry_payloads_are_a_trap}
```

This was an intentional **honeytoken** — planted in a `STATUSTEXT` message field to waste time. The challenge description's hint about "circles in the wheat" signalled that the flag was physically drawn by the drone's flight path, not stored as text.

## Solution

### Step 1: Understand MAVLink 2.0 packet structure

MAVLink 2.0 packets start with magic byte `0xfd`. The relevant message is **Message ID 33: `GLOBAL_POSITION_INT`**, which contains:
- `lat`: latitude × 10^7 (int32)
- `lon`: longitude × 10^7 (int32)

### Step 2: Parse GPS coordinates from raw binary

```python
import struct

data = open("telemetry.data", "rb").read()
coords = []
i = 0
while i < len(data) - 12:
    if data[i] == 0xfd:  # MAVLink 2.0 magic byte
        payload_len = data[i+1]
        msg_id = struct.unpack_from('<I', data, i+7)[0] & 0xFFFFFF
        if msg_id == 33 and payload_len >= 18:  # GLOBAL_POSITION_INT
            payload = data[i+10:i+10+payload_len]
            lat = struct.unpack_from('<i', payload, 0)[0] / 1e7
            lon = struct.unpack_from('<i', payload, 4)[0] / 1e7
            coords.append((lat, lon))
        i += 10 + payload_len + 2
    else:
        i += 1

coords = list(set(coords))  # deduplicate — 477 unique points
print(f"Extracted {len(coords)} unique GPS coordinates")
```

### Step 3: Separate decoy from flag cluster

Calculating the median longitude splits the 477 points into two clusters — 3 decoy points and 474 flag points:

```python
import statistics
mid_lon = statistics.median(lon for _, lon in coords)
flag_coords = [(lat, lon) for lat, lon in coords if lon <= mid_lon]
print(f"Flag cluster: {len(flag_coords)} points")  # 474
```

### Step 4: Visualise the flight path

```python
import matplotlib.pyplot as plt

lats = [lat for lat, lon in flag_coords]
lons = [lon for lat, lon in flag_coords]

plt.figure(figsize=(16, 8))
plt.scatter(lons, lats, s=2, c='black')
plt.axis('equal')
plt.title("Drone GPS Flag Path")
plt.savefig("flag_path.png", dpi=150, bbox_inches='tight')
plt.show()
```

The 474 waypoints trace legible leet-speak characters spelling the flag.

## Flag

```
SK-CERT{MY_QU4D_W45_H1J4CK3D}
```

## Key Takeaways

- **Honeytokens** are standard anti-forensics — always treat the first obvious "answer" in a binary file with suspicion
- **Geospatial steganography** (hiding data in physical flight paths) is a real drone forensics concern
- **Aspect ratio matters** — `plt.axis('equal')` is essential to prevent coordinate distortion that makes characters unreadable
- MAVLink 2.0 magic byte `0xfd` and Message ID 33 (`GLOBAL_POSITION_INT`) are the key parsing targets

## Tools Used

- Python `struct` — MAVLink binary parsing
- `matplotlib` — GPS path visualisation
- `statistics` — median-based cluster separation
