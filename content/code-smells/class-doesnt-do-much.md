---
title: Class Doesn't Do Much Code Smell

date: 2026-03-08

description: The Class Doesn't Do Much code smell, also called a Lazy Class, describes a class that exists in the codebase but contributes so little behavior or responsibility that it does not justify its own existence.

---

The Class Doesn't Do Much code smell — also known as a **Lazy Class** — describes a class that exists in the codebase but contributes so little behavior or responsibility that it does not justify its own existence. These classes often hold a single field, wrap a single method call, or contain only trivial pass-through logic. They add indirection without adding value, and they fragment the design without clarifying it.

Lazy classes often appear when a planned abstraction never fully materialized, when a refactoring extracted a class that turned out to need very little of its own behavior, or when a class gradually had its responsibilities moved elsewhere and was never removed.

## Problems Caused by Classes That Don't Do Much

### Unnecessary Indirection

Every class in a codebase represents a concept that a developer must understand. A class with little purpose adds a navigation step — a reader follows references to `AddressFormatter` only to find a single method that calls `string.Format`. That indirection costs time without providing clarity.

### Fragmented Responsibility

When behavior is spread across too many small classes, it can be difficult to find related logic. A class that does nearly nothing may indicate that its one method or field belongs on a neighbor class where it would be seen in context.

### Maintenance Overhead

Every class is a unit that must be kept up to date — imports, namespaces, test coverage, and documentation all apply. Classes that do little amplify this overhead without a proportional benefit.

### Test Noise

A lazy class typically requires its own test file, test setup, and mocks. Writing tests for pass-through wrappers creates test noise — tests that are difficult to name, provide little confidence, and must be maintained as the code evolves.

## Example

Consider a class used only to wrap a single string operation:

```csharp
public class FullNameFormatter
{
    public string Format(string firstName, string lastName)
    {
        return $"{lastName}, {firstName}";
    }
}
```

If this class is instantiated in one place and is never expected to grow, it adds little value. The calling code would be clearer with the logic inlined or moved to the class that already owns the name data:

```csharp
public class Customer
{
    public string FirstName { get; set; }
    public string LastName { get; set; }

    public string FullName => $"{LastName}, {FirstName}";
}
```

The property lives where the data lives. The separate formatter class is no longer needed.

## When a Small Class Is Justified

Not every small class is a code smell. Some classes are small and should stay that way:

- **Value objects** that encapsulate a concept (like `Money`, `EmailAddress`, or `DateRange`) are intentionally small but carry domain meaning and validation.
- **Marker interfaces** that exist for type-system purposes.
- **Classes that are expected to grow** as a feature is developed.
- **Adapter or bridge classes** that provide a stable seam between components, even if their current implementation is thin.

The distinction is whether the class represents a genuine concept worth naming and whether it carries behaviors or invariants that justify its existence.

## Identifying Lazy Classes

Look for classes that:

- Have only one or two methods, neither of which contains meaningful logic.
- Contain a single field that is immediately passed through to a collaborator.
- Exist purely to delegate every call to another class without transforming or enriching the data.
- Are only instantiated in one place and could be replaced by a direct call.

Code coverage reports and dependency graphs can help surface classes that are touched infrequently or that have very few callers. Peer code review is often the most effective way to catch these during development.

## Addressing Lazy Classes

The primary refactoring technique is **Inline Class**: move the lazy class's fields and methods to the class that uses it most, then delete the lazy class. If the lazy class is used by multiple callers, consider whether its logic belongs on one of the data classes it operates on, which would be an **Move Method** refactoring.

If the lazy class exists because a planned abstraction was never built out, evaluate whether that abstraction is still needed. If not, remove it. If it will be needed, document the intent clearly so that future work completes the picture rather than discovering a mysteriously empty class.

## References

- [Refactoring: Improving the Design of Existing Code](https://martinfowler.com/books/refactoring.html) by Martin Fowler
- [Single Responsibility Principle](/principles/single-responsibility-principle/)
- [Don't Repeat Yourself](/principles/dont-repeat-yourself/)
