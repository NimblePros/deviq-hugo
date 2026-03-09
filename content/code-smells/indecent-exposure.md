---
title: Indecent Exposure Code Smell

date: 2026-03-09

description: Indecent Exposure is a code smell where a class reveals internal implementation details that should be hidden, breaking encapsulation and increasing coupling to its internals.

---

Indecent Exposure is a code smell where a class reveals more of its internal implementation than it should — through public or internal fields, public setters on properties that should be controlled, or methods that exist only to support a specific caller rather than represent a genuine part of the class's interface. The class is showing what should be hidden.

Indecent Exposure is fundamentally a violation of [encapsulation](/principles/encapsulation/). Encapsulation means hiding the internal workings of a class behind a stable public interface. When a class exposes its internals, callers gain the ability to manipulate implementation details directly — and become dependent on them.

## Problems Caused by Indecent Exposure

### Broken Encapsulation

Once an internal detail is public, it becomes part of the class's contract. Callers start to depend on it. Changing or removing it later breaks those callers. The promise of encapsulation — that a class can change its internals freely — is forfeit.

### Unenforceable Invariants

A class with public mutable state cannot guarantee that its data is consistent. Any caller can put the object into an invalid state. An `Order` with a public `Status` setter cannot prevent code from setting `Status = "Shipped"` before any items are added.

### Increased Coupling

Every caller that directly accesses internal state is tightly coupled to the class's current implementation. A change as small as renaming a field or switching from a `List<T>` to a different collection type forces updates across any code that directly touched the internal.

### Fragile Codebase

When internal state is visible and writable, bugs caused by unintended mutation are hard to trace. The code that writes an invalid value may be far from the code that encounters the resulting error.

## Example

A class that exposes more than it should:

```csharp
public class ShoppingCart
{
    public List<CartItem> Items = new();  // public field, fully mutable
    public decimal InternalDiscount;      // implementation detail, exposed
    public string _sessionId;             // private-by-convention but public

    public void ApplyDiscount(decimal amount)
    {
        InternalDiscount = amount;
    }
}
```

Any caller can add or remove items directly, set the discount to any value, or read and modify the session ID. Nothing is protected.

After applying encapsulation:

```csharp
public class ShoppingCart
{
    private readonly List<CartItem> _items = new();
    private decimal _discount;
    private readonly string _sessionId;

    public IReadOnlyList<CartItem> Items => _items;

    public ShoppingCart(string sessionId)
    {
        _sessionId = sessionId;
    }

    public void AddItem(CartItem item)
    {
        ArgumentNullException.ThrowIfNull(item);
        _items.Add(item);
    }

    public void ApplyDiscount(decimal amount)
    {
        if (amount < 0 || amount > 1)
            throw new ArgumentOutOfRangeException(nameof(amount), "Discount must be between 0 and 1.");
        _discount = amount;
    }

    public decimal Total() => _items.Sum(i => i.Price) * (1 - _discount);
}
```

Internal state is now controlled. Callers interact through a defined interface. The class can enforce invariants — the discount is validated before being stored.

## Identifying Indecent Exposure

Watch for:

- **Public fields** — any `public` field is exposing internal state directly.
- **Public setters on properties that should only be set by the class** — `public string Status { get; set; }` on an entity that manages its own lifecycle.
- **Methods added solely to support one specific caller** — methods that reveal internal mechanics rather than express genuine behavior.
- **`internal` members that are frequently accessed from outside the class** — `internal` is a weaker form of the same problem.
- **Collections returned as mutable references** — returning a `List<T>` instead of `IReadOnlyList<T>` allows callers to mutate the list directly.

## Refactoring

- **Encapsulate Field** — replace public fields with properties and control access through methods.
- **Remove Setting Method** — eliminate public setters that callers should not use; use constructor parameters or specific state-transition methods instead.
- **Return read-only views of collections** — expose collections as `IReadOnlyList<T>`, `IReadOnlyCollection<T>`, or `IEnumerable<T>` rather than mutable types.
- **Introduce Method** — replace direct field access by callers with a method on the class that performs the needed operation, keeping the data private.
