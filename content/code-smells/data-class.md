---
title: Data Class Code Smell

date: 2026-03-09

description: The Data Class code smell describes a class that holds data but contains no meaningful behavior, acting only as a passive data container.

weight: 90
---

A Data Class is a class that holds data — fields or properties — but contains no meaningful behavior of its own. It exists only to carry values from one part of the code to another, while all the logic that operates on those values lives elsewhere. Data classes are characterized by long lists of getters and setters, no encapsulation, and no operations that enforce business rules or invariants.

The smell does not apply to every class that holds data. Simple value objects, DTOs used at system boundaries, or records used for transferring data between layers can be legitimate. The smell arises when a class that should have behavior — because it represents a real domain concept — has had that behavior stripped out and placed in other classes, leaving behind a passive data container. This pattern is closely related to the [Anemic Domain Model](/domain-driven-design/anemic-model/) antipattern.

## Problems with Data Classes

### Behavior Scattered Across the Codebase

When a class has no behavior, the logic that should belong to it is distributed across service classes, managers, or helpers. A `Customer` that is only data means that business rules like "can this customer place an order" and "what discount does this customer qualify for" end up spread across many other classes, making them harder to find, test, and maintain.

### No Encapsulation

A data class cannot enforce invariants on the data it holds. Any code anywhere in the application can set any field to any value. A `Product` with public setters on `Price` and `Stock` cannot prevent price from being set to a negative value or stock from going below zero unless every caller is disciplined — a fragile arrangement.

### Violation of Object-Oriented Design

Object-oriented design is founded on the idea that objects combine data and behavior. A class that does only one of those is, in a meaningful sense, not really an object — it is a record or struct pretending to be a class. The design loses the primary advantage that objects provide: the ability to hide complexity behind a well-defined interface.

### Attracts [Feature Envy](./feature-envy)

Data classes predictably attract [Feature Envy](./feature-envy): other classes that are constantly reaching into the data class to read or modify its fields. This is a sign that the logic manipulating the data belongs on the data class itself.

## Example

Consider a class that represents an order but holds no behavior:

```csharp
public class Order
{
    public int Id { get; set; }
    public List<OrderLine> Lines { get; set; }
    public decimal Discount { get; set; }
    public string Status { get; set; }
}
```

All rules about how the order status transitions, how discounts are calculated, and how line items are validated exist in an `OrderService` that manipulates the `Order` directly. The `Order` class itself is just a bag of data.

After refactoring, the class takes ownership of its logic:

```csharp
public class Order
{
    private readonly List<OrderLine> _lines = new();
    public IReadOnlyList<OrderLine> Lines => _lines;

    public string Status { get; private set; } = "Pending";
    public decimal Discount { get; private set; }

    public void AddLine(OrderLine line)
    {
        ArgumentNullException.ThrowIfNull(line);
        _lines.Add(line);
    }

    public decimal Total() => Lines.Sum(l => l.Subtotal()) * (1 - Discount);

    public void Submit()
    {
        if (!Lines.Any()) throw new InvalidOperationException("Cannot submit an empty order.");
        Status = "Submitted";
    }
}
```

The class now enforces its own rules and exposes behavior rather than raw state.

## When a Data Class Is Acceptable

Not all data holders are code smells:

- **DTOs (Data Transfer Objects)** at application boundaries (API request/response models, database query results) are intentionally passive. They exist to move data across a boundary and should not contain business logic.
- **Value Objects** are small and often data-only, but they carry domain meaning and typically include validation and equality behavior.
- **Records** used for immutable snapshots or configuration values.

The distinction is intent and context. If a class represents a rich domain concept and all its behavior lives elsewhere, that is the smell. If a class is explicitly a data-transfer vessel, it is not.

## Addressing Data Classes

The primary refactoring is **Move Method**: identify logic in external classes that operates primarily on data from the data class, and move it onto the class itself. Make properties that should not be set externally use `private set` or be set only through methods that enforce rules. Replace raw field assignments with methods that have meaningful names.

For large data classes, this refactoring typically happens incrementally. Start by encapsulating the most critical invariants, then migrate logic piece by piece as the class gains a stable interface.

## References

- [Refactoring: Improving the Design of Existing Code](https://martinfowler.com/books/refactoring.html) by Martin Fowler
- [Anemic Domain Model](/domain-driven-design/anemic-model/)
- [Encapsulation](/principles/encapsulation/)
- [Single Responsibility Principle](/principles/single-responsibility-principle/)
