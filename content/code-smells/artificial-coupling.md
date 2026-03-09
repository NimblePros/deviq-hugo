---
title: Artificial Coupling Code Smell

date: 2026-03-09

description: Artificial Coupling is a code smell where unrelated concepts are coupled together through shared state, a common base class, or co-location, when no real relationship exists between them.

---

Artificial Coupling is a code smell where two or more unrelated concepts are forced into a relationship they do not naturally have. The coupling is artificial — not derived from the problem domain, but from a convenience decision or structural shortcut. Common forms include placing unrelated methods in the same class, deriving from a base class to gain access to a few shared utilities, or using shared mutable state to pass data between unrelated operations.

The result is that changing one concept risks breaking another, even though they have nothing logically in common.

## Problems Caused by Artificial Coupling

### Unintended Dependencies

When unrelated concepts share a class, a change to one may require touching (and potentially breaking) the other. A developer modifying shipping logic should not have to worry about breaking payment formatting code in the same class.

### Violation of the Single Responsibility Principle

A class that serves unrelated purposes violates the [Single Responsibility Principle](/principles/single-responsibility-principle/). It has multiple reasons to change and serves multiple masters. This makes the class harder to understand, name, and maintain.

### Inflated Classes and Modules

Artificial coupling tends to produce large classes or modules that accumulate more and more unrelated functionality over time. New methods are added because "that's where utilities go," not because they belong there. This is a precursor to [Big Ball of Mud](/antipatterns/big-ball-of-mud/) designs.

### Reuse Obstacles

Reusing one of the artificially coupled concepts requires taking the other along for the ride — as a dependency, a base class, or a shared module. If concept A is only needed in one context but is coupled to concept B, referencing A in a new project brings B along unnecessarily.

## Example

A utility class that groups unrelated helpers:

```csharp
public static class Utilities
{
    // String formatting unrelated to dates
    public static string FormatCurrency(decimal amount) => amount.ToString("C");
    public static string TruncateDescription(string text, int maxLength) =>
        text.Length <= maxLength ? text : text[..maxLength] + "...";

    // Date logic unrelated to currency
    public static bool IsBusinessDay(DateTime date) =>
        date.DayOfWeek != DayOfWeek.Saturday && date.DayOfWeek != DayOfWeek.Sunday;
    public static DateTime NextBusinessDay(DateTime date)
    {
        var next = date.AddDays(1);
        while (!IsBusinessDay(next)) next = next.AddDays(1);
        return next;
    }

    // Email validation unrelated to both
    public static bool IsValidEmail(string email) => email.Contains('@');
}
```

`FormatCurrency`, `IsBusinessDay`, and `IsValidEmail` have no relationship to each other. They are coupled only because they were convenient to put in the same class. A change to email validation has no business touching currency formatting.

After separating by concern:

```csharp
public static class MoneyFormatter
{
    public static string FormatCurrency(decimal amount) => amount.ToString("C");
    public static string TruncateDescription(string text, int maxLength) =>
        text.Length <= maxLength ? text : text[..maxLength] + "...";
}

public static class BusinessCalendar
{
    public static bool IsBusinessDay(DateTime date) =>
        date.DayOfWeek != DayOfWeek.Saturday && date.DayOfWeek != DayOfWeek.Sunday;
    public static DateTime NextBusinessDay(DateTime date)
    {
        var next = date.AddDays(1);
        while (!IsBusinessDay(next)) next = next.AddDays(1);
        return next;
    }
}

public static class EmailValidator
{
    public static bool IsValidEmail(string email) => email.Contains('@');
}
```

Each class now has a clear, singular focus. Changes to one do not affect the others.

## Identifying Artificial Coupling

Watch for:

- A class named `Utilities`, `Helpers`, `CommonUtils`, or similar catch-all names.
- A base class whose only purpose is to share utility methods rather than represent a genuine abstraction.
- Shared static state used as a communication channel between unrelated operations.
- Modules or namespaces that accumulate methods from multiple unrelated domains.
- Inheritance used to gain access to methods that could have been injected or composed.

## Refactoring

- **Extract Class** — separate unrelated methods or fields into classes organized by their actual domain or purpose.
- **Replace Inheritance with Composition** — if a class derives from a base solely to reuse unrelated utilities, inject those utilities instead.
- **Move Method / Move Field** — relocate each member to the class that genuinely owns the concept it represents.
