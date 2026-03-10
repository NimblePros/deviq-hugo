---
title: Inappropriate Intimacy Code Smell

date: 2026-03-09

description: Inappropriate Intimacy is a code smell where two classes know too much about each other's internal implementation details, creating excessive coupling and mutual dependency.

weight: 170
---

Inappropriate Intimacy is a code smell where two classes are excessively familiar with each other's internals. One (or both) classes digs into the private fields, internal methods, or implementation details of the other. They are inappropriately intimate: rather than respecting each other's public interfaces, they reach past those boundaries to touch internal state directly.

The smell is named after the social analogy: healthy relationships have appropriate boundaries. When two classes are intimately entangled rather than interacting through clean interfaces, changes to one tend to ripple unexpectedly into the other.

## Problems Caused by Inappropriate Intimacy

### High Coupling

When class A knows the internal structure of class B, A is tightly coupled to B's implementation. Any refactoring of B's internals — renaming a field, changing a data structure, reorganizing private methods — is likely to break A. The classes cannot evolve independently.

### Violation of Encapsulation

Exposing private implementation details defeats the purpose of [encapsulation](/principles/encapsulation/). Encapsulation allows a class to change its implementation without affecting its clients. Inappropriate Intimacy breaks this guarantee.

### Bidirectional Dependencies

When both classes depend on each other's internals, the codebase gains a bidirectional dependency. Bidirectional dependencies are harder to reason about, harder to test in isolation, and harder to decompose for reuse. A change anywhere can affect both sides.

### Difficult Testing

Testing either class in isolation requires setting up (or mocking) the internal state of the other. This leads to brittle tests that break when implementation details change, not when behavior changes.

## Example

Two classes that are too familiar with each other:

```csharp
public class Order
{
    internal List<OrderLine> _lines = new();
    internal string _status = "Pending";

    public void AddLine(OrderLine line) => _lines.Add(line);
}

public class OrderExporter
{
    public string Export(Order order)
    {
        // Directly manipulates order's internal state
        order._status = "Exported";

        return string.Join("\n", order._lines
            .Select(l => $"{l.ProductId},{l.Quantity},{l.UnitPrice}"));
    }
}
```

`OrderExporter` sets `Order`'s internal `_status` field directly and reads the internal `_lines` list. It knows too much about `Order`'s implementation. If `Order` changes its internal representation, `OrderExporter` breaks.

After establishing proper boundaries:

```csharp
public class Order
{
    private readonly List<OrderLine> _lines = new();
    public IReadOnlyList<OrderLine> Lines => _lines;
    public string Status { get; private set; } = "Pending";

    public void AddLine(OrderLine line) => _lines.Add(line);
    public void MarkExported() => Status = "Exported";
}

public class OrderExporter
{
    public string Export(Order order)
    {
        order.MarkExported();

        return string.Join("\n", order.Lines
            .Select(l => $"{l.ProductId},{l.Quantity},{l.UnitPrice}"));
    }
}
```

`Order` controls its own state through a method. `OrderExporter` interacts with `Order` through its public interface only.

## Identifying Inappropriate Intimacy

Watch for:

- Access to `internal` or `protected` members from outside a class's natural hierarchy.
- Long chains of property access navigating into deeply nested private state.
- Classes that need to be modified any time the other is refactored.
- Circular dependencies between two classes — each importing or referencing the other.
- Test classes that rely heavily on reflection to access private state.

## Relationship to Other Smells

Inappropriate Intimacy is closely related to [Message Chains](./message-chains) and [Law of Demeter Violations](./law-of-demeter-violations) — all involve accessing more of another object's internals than is healthy. The distinction is that Inappropriate Intimacy typically involves mutual or deeply nested access to private state, while Message Chains describe navigating through many objects in sequence.

## Refactoring

- **Move Method / Move Field** — if one class consistently needs data from another, that data (and its behavior) may belong in the first class.
- **Extract Class** — shared behavior or state between two tightly coupled classes can sometimes be moved to a third class that both depend on.
- **Hide Delegate** — instead of exposing internal objects, add a method on the owning class that performs the operation.
- **Change Bidirectional Association to Unidirectional** — where possible, break the cycle so only one class depends on the other.
