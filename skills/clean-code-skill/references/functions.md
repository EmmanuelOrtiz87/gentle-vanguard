## Functions

**Rules:**

- **One level of abstraction per function**: A function should mix high-level logic (e.g., "fetch
  data") with mid-level logic (e.g., "parse CSV line") or low-level (e.g., "trim whitespace") —
  never all three.
- **3-4 parameters max**: More than 4 suggests the function does too much. Bundle related params
  into objects.
- **No side effects**: Prefer pure functions. If a function must mutate state, make it obvious (name
  it `setX()`, `updateY()`).
- **DRY but not at cost of clarity**: Extract duplication into shared helpers, but don't create
  overly abstracted indirection for code that appears only twice.

```javascript
// Bad: Mixed abstraction levels
function processOrder(order) {
  const tax = order.total * 0.08;
  order.totalWithTax = order.total + tax;
  fs.writeFileSync(`orders/${order.id}.json`, JSON.stringify(order));
  sendEmailNotification(order.userEmail, 'Order processed');
  return order.totalWithTax;
}

// Good: Clear single responsibility
function calculateTotalWithTax(total, taxRate) {
  return total + total * taxRate;
}
```
