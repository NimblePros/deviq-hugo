---
title: Temporary Field Code Smell

date: 2026-03-08

description: The Temporary Field code smell occurs when an object has instance fields that are only set and used in certain circumstances, leaving them uninitialized or meaningless the rest of the time.

---

The Temporary Field code smell occurs when a class has instance fields that are only populated and meaningful in some circumstances — typically within a single method or a specific execution path — and are otherwise null, zero, or irrelevant. The field exists on the class not because it represents a stable property of the object, but because it was added as a convenient way to pass data between methods without changing signatures.

This is a violation of the implicit contract of a class: users of the class expect all fields to represent meaningful state of the object at all times. When some fields are "sometimes relevant," the class becomes harder to reason about, and the risk of using a field in a context where it hasn't been set — producing null reference errors or silent incorrect results — increases.

## How It Arises

Temporary fields often appear when a long algorithm is refactored by extracting methods without extracting a class. The original method had local variables; once split into multiple methods, those locals become fields so the extracted methods can access them. The fields now sit on the class even though they only matter during one operation.

They also appear when a class accumulates special-case logic over time: a field added for one particular use case, but that has no meaning in the general case.

## Problems Caused by Temporary Fields

### Confusing Class Interface

A field that is only valid in certain circumstances forces readers to understand a complex set of preconditions. "When is `_tempResult` null? Is it safe to read here? Does it need to be set before calling this method?" These questions add cognitive overhead to every interaction with the class.

### Null Reference Risk

Fields that are only set in some paths are prime candidates for `NullReferenceException` and similar errors. Code that reads the field in an unexpected context will silently get null or a default value, possibly producing incorrect behavior that is hard to trace.

### Hidden Coupling Between Methods

When methods communicate through fields instead of parameters, their execution order becomes an implicit dependency. Method B only works correctly if Method A was called first. This hidden coupling is a form of the [Bump Road](/code-smells/bump-road/) smell — the class is harder to use correctly than it looks.

### Misleading State

An object whose fields do not all reflect its current meaningful state at any given time violates the principle of [Tell, Don't Ask](https://martinfowler.com/bliki/TellDontAsk.html). The object cannot be trusted to be in a coherent state.

## Example

```csharp
public class ReportGenerator
{
    private List<Order> _orders;       // set in Generate(), null otherwise
    private decimal _total;            // computed in Calculate(), zero otherwise
    private string _formattedResult;   // set in Format(), null otherwise

    public string Generate(List<Order> orders)
    {
        _orders = orders;
        Calculate();
        Format();
        return _formattedResult;
    }

    private void Calculate()
    {
        _total = _orders.Sum(o => o.Total);
    }

    private void Format()
    {
        _formattedResult = $"Total: {_total:C}";
    }
}
```

`_orders`, `_total`, and `_formattedResult` are all temporary fields — they only exist to thread state through a single call to `Generate`. Outside that call, they are meaningless. The fix is either to pass them as parameters or to extract a dedicated computation object:

```csharp
public class ReportGenerator
{
    public string Generate(List<Order> orders)
    {
        var total = CalculateTotal(orders);
        return FormatResult(total);
    }

    private decimal CalculateTotal(List<Order> orders)
        => orders.Sum(o => o.Total);

    private string FormatResult(decimal total)
        => $"Total: {total:C}";
}
```

No fields are needed at all — the data flows through method parameters and return values, making the execution flow explicit.

## Refactoring

- **Replace Temp with Query / Pass as Parameters**: Instead of storing intermediate results in fields, pass them as method parameters or return them from helper methods.
- **Extract Class**: If the temporary fields and the methods that use them form a coherent unit, extract them into a dedicated class (sometimes called a *method object* or *parameter object*) that is instantiated when the operation is needed and discarded afterward.
- **Introduce Parameter Object**: If multiple temporary fields are always set and used together, group them into a value object or record that is passed explicitly.
- **Replace Method with Method Object**: Convert the long method and its supporting fields into a separate class where all the fields become proper instance fields of a short-lived object.

## References

- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Bump Road](/code-smells/bump-road/)
- [Long Method](/code-smells/long-method/)
- [Refactoring](/practices/refactoring/)
