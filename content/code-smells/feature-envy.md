---
title: Feature Envy Code Smell

date: 2026-03-09

description: Feature Envy is a code smell where a method in one class is more interested in the data or behavior of another class than in its own, suggesting the method belongs in the other class.

---

Feature Envy is a code smell where a method seems more interested in another class than in the class it belongs to. The method constantly reaches into another object to access its data, call its helpers, or perform calculations that are really about that other object's domain. The name is apt: the method envies the features of a neighbor.

Feature Envy is closely associated with [Data Classes](./data-class) — a passive data class that attracts envious methods from other classes is a common combination. When logic that should live on an object is displaced to a service or manager, both smells appear at once.

## Problems Caused by Feature Envy

### Misplaced Responsibility

A method that operates primarily on data from another class belongs in that class. Keeping it elsewhere misplaces the responsibility, making the codebase harder to navigate and reason about. Finding "what does this type do?" requires searching multiple classes.

### Tight Coupling

An envious method creates a dependency from its home class to the target class. The more a method reaches into another class, the tighter that coupling becomes. Changes to the target class's internals risk breaking the envious method, increasing fragility.

### Violation of the Single Responsibility Principle

When a class contains methods that primarily concern another class's data, the host class is taking on responsibilities that don't belong to it. This inflates the class and gives it unrelated reasons to change, violating the [Single Responsibility Principle](/principles/single-responsibility-principle/).

### Reduced Cohesion

A class with high [cohesion](/terms/cohesion/) has methods that all relate to the same concept. A method that spends most of its time working with another class's data lowers the cohesion of its host.

## Example

An `InvoicePrinter` class that is envious of `Invoice`:

```csharp
public class Invoice
{
    public List<InvoiceLine> Lines { get; set; }
    public decimal TaxRate { get; set; }
    public string CustomerName { get; set; }
}

public class InvoicePrinter
{
    public string Format(Invoice invoice)
    {
        decimal subtotal = invoice.Lines.Sum(l => l.Quantity * l.UnitPrice);
        decimal tax = subtotal * invoice.TaxRate;
        decimal total = subtotal + tax;

        return $"Invoice for {invoice.CustomerName}\n"
             + $"Subtotal: {subtotal:C}\n"
             + $"Tax: {tax:C}\n"
             + $"Total: {total:C}";
    }
}
```

`Format` is not really about printing — it is about calculating the invoice's financial totals. That logic belongs on `Invoice`.

After moving the behavior to where the data lives:

```csharp
public class Invoice
{
    public IReadOnlyList<InvoiceLine> Lines { get; }
    public decimal TaxRate { get; }
    public string CustomerName { get; }

    public decimal Subtotal() => Lines.Sum(l => l.Quantity * l.UnitPrice);
    public decimal Tax() => Subtotal() * TaxRate;
    public decimal Total() => Subtotal() + Tax();
}

public class InvoicePrinter
{
    public string Format(Invoice invoice)
    {
        return $"Invoice for {invoice.CustomerName}\n"
             + $"Subtotal: {invoice.Subtotal():C}\n"
             + $"Tax: {invoice.Tax():C}\n"
             + $"Total: {invoice.Total():C}";
    }
}
```

`InvoicePrinter` now only handles formatting. `Invoice` owns its own calculations. Each class does what it should.

## Identifying Feature Envy

Look for methods that:

- Access many properties or methods of a single object they receive as a parameter.
- Contain logic that could be described as "calculating something about X" where X is another class.
- Would read more naturally as a method on the class they're envious of.

A useful heuristic: if renaming the method to `SomethingAboutX()` makes it feel like a method on `X`, it probably belongs on `X`.

## Refactoring

- **Move Method** — relocate the envious method to the class it cares about.
- **Extract Method then Move Method** — if only part of a long method is envious, extract that part first, then move it.
- **Move Field** — if data has followed the method to the wrong class, consider whether the field also belongs in the target class.

Occasionally Feature Envy is appropriate — for example, in a [Strategy](/design-patterns/strategy-pattern/) or [Visitor](/design-patterns/visitor-pattern/) that intentionally operates on data from another class. Context matters.
