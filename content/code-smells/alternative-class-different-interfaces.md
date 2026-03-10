---
title: Alternative Class with Different Interfaces Code Smell

date: 2026-03-08

description: The Alternative Class with Different Interfaces code smell occurs when two or more classes do the same thing but expose different method names or signatures, preventing them from being used interchangeably.

weight: 10
---

The Alternative Class with Different Interfaces code smell occurs when two or more classes perform the same or very similar roles but expose their functionality through different method names, parameter orders, or signatures. Because their interfaces differ, calling code cannot treat them interchangeably — even though conceptually they are alternatives for the same purpose.

This smell is common when two developers independently implement similar functionality without awareness of each other's work, or when a class is duplicated and adapted rather than extracted behind a shared interface. It is closely related to the [Oddball Solution](/code-smells/oddball-solution/) smell and the [Inconsistency](/code-smells/inconsistency/) smell — all three represent the absence of a unified vocabulary or contract for a concept that deserves one.

## Problems Caused by Alternative Classes with Different Interfaces

### Prevents Substitutability

The fundamental benefit of polymorphism in object-oriented design is the ability to substitute one implementation for another. When two classes do the same thing but have different interfaces, that substitutability is lost. Code that uses `EmailNotifier` cannot be switched to use `SmsNotifier` without rewriting the calling code, even if both are conceptually "notifiers."

### Hides Duplication

When implementations differ at the interface level, it is easy to miss that they are duplicates. Static analysis tools looking for duplicate code will not flag two classes as similar if their method signatures differ. The duplication may go unaddressed for a long time, accumulating two diverging implementations of the same concept.

### Forces Parallel Changes

If both classes need the same bug fix or enhancement — for example, both need to handle a new retry policy — the change must be made in two places with no compile-time enforcement that both were updated. This is [Shotgun Surgery](/code-smells/shotgun-surgery/) caused by the absence of a shared interface.

### Complicates Testing

Without a shared interface, tests for one class cannot be re-run against the other. Testing both requires duplicating test logic, and any gaps in coverage of one class are not automatically surfaced when the other is tested.

## Example

Two notification classes serving the same purpose but with different method names:

```csharp
public class EmailNotifier
{
    public void SendEmail(string recipient, string subject, string body) { ... }
}

public class SmsNotifier
{
    public void Dispatch(string phoneNumber, string message) { ... }
}
```

Code that uses `EmailNotifier` cannot be switched to `SmsNotifier` without changes, even though both send notifications. Introducing a shared interface resolves the smell:

```csharp
public interface INotifier
{
    void Notify(string recipient, string message);
}

public class EmailNotifier : INotifier
{
    public void Notify(string recipient, string message) { ... }
}

public class SmsNotifier : INotifier
{
    public void Notify(string recipient, string message) { ... }
}
```

Calling code depends on `INotifier` and is unaware of which implementation it receives. Adding a `PushNotifier` or `SlackNotifier` requires no changes to callers.

## Distinguishing from Legitimate Variation

Not every pair of dissimilar classes is this smell. The smell applies specifically when two classes are *alternatives for the same role* — they can be sensibly substituted for one another — but their interfaces prevent that substitution. If two classes genuinely represent different concepts that happen to share some superficial similarity, forcing them into a shared interface would be premature abstraction.

The key question is: **"Would a caller ever want to choose between these two classes for the same purpose?"** If yes, a shared interface is warranted.

## Refactoring

- **Extract Interface / Introduce Supertype**: Identify the common operations and define an interface (or abstract base class) that both classes can implement.
- **Rename Method**: If the classes differ only in method name, rename one (or both) to match the agreed-upon interface.
- **Move Method / Add Parameter**: If signatures differ due to parameter differences, align them by reworking one implementation to match the abstraction.
- **[Adapter Pattern](/design-patterns/adapter-design-pattern/)**: When one class cannot be changed (e.g., a third-party library), wrap it in an Adapter that exposes the shared interface.

## References

- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Oddball Solution](/code-smells/oddball-solution/)
- [Inconsistency](/code-smells/inconsistency/)
- [Shotgun Surgery](/code-smells/shotgun-surgery/)
- [Adapter Pattern](/design-patterns/adapter-design-pattern/)
- [Explicit Dependencies Principle](/principles/explicit-dependencies-principle/)
