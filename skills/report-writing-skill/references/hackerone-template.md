## HACKERONE REPORT TEMPLATE

```markdown
## Summary

[One paragraph: what the bug is, where it is, what an attacker can do. Be specific. Include:
endpoint, method, parameter, data exposed, required access level.]

Example: "The `/api/users/{user_id}/orders` endpoint does not verify that the authenticated user
owns the requested user_id. An attacker can enumerate any user's order history, including PII
(email, address, phone) and purchase history, by incrementing the user_id parameter. No privileges
beyond a standard free account are required."

## Vulnerability Details

**Vulnerability Type:** IDOR / Broken Object Level Authorization **CVSS 3.1 Score:** 6.5 (Medium) —
AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:N/A:N **Affected Endpoint:** GET /api/users/{user_id}/orders

## Steps to Reproduce

**Environment:**

- Attacker account: attacker@test.com, user_id = 123
- Victim account: victim@test.com, user_id = 456
- Target: https://target.com

**Steps:**

1. Log in as attacker@test.com, obtain Bearer token

2. Send the following request:
```

GET /api/users/456/orders HTTP/1.1 Host: target.com Authorization: Bearer ATTACKER_TOKEN_HERE

````

3. Observe response:

```json
{
  "orders": [
    {"id": 789, "items": [...], "email": "victim@test.com", "address": "123 Main St..."}
  ]
}
````

The response contains victim's full order history and PII despite being requested by a different
user.

## Impact

An authenticated attacker can enumerate all user orders by iterating user_id values. This exposes:
full name, email, shipping address, purchase history, and payment method (last 4). With ~100K users,
this represents a mass PII breach affecting all registered users. Exploitation requires only a free
account and takes minutes with a simple loop.

## Recommended Fix

Add server-side ownership verification:

```python
if order.user_id != current_user.id:
    raise Forbidden()
```

## Supporting Materials

[Screenshot showing attacker's session returning victim's order data] [Video walkthrough if
available]

```

```
