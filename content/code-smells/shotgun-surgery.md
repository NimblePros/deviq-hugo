---
title: Shotgun Surgery Code Smell

date: 2026-03-08

description: Shotgun Surgery is a code smell where making a single logical change requires modifying many different classes or files simultaneously, spreading a single concern across the codebase in a fragile and error-prone way.

---

Shotgun Surgery is a code smell where a single logical change — fixing a business rule, updating a data format, changing a configuration value — forces you to make small edits scattered across many different classes or files at the same time. The name evokes the buckshot pattern: one trigger pull, holes everywhere.

Shotgun Surgery is the inverse of [Divergent Change](./divergent-change): where Divergent Change means one class changes for many reasons, Shotgun Surgery means one reason to change affects many classes. Both indicate a poor distribution of responsibility, but in **opposite directions**.

## Problems Caused by Shotgun Surgery

### High Risk of Missed Edits

Because the change is spread across the codebase, it is easy to overlook one location. A missed update introduces an inconsistency — and often a subtle bug that is hard to trace back to its cause.

### Violation of the Single Responsibility Principle

A single concept that lives in many places is not properly encapsulated. The [Single Responsibility Principle](/principles/single-responsibility-principle/) calls for gathering things that change together into the same place. Shotgun Surgery is a symptom that this principle is being violated.

### Violation of DRY

The same knowledge or rule is encoded in multiple locations. This violates the [Don't Repeat Yourself (DRY)](/principles/dont-repeat-yourself/) principle and means every future change to that rule requires the same scattered update.

### Difficult Code Reviews

Pull requests that touch many files for a single logical change are harder to review, harder to understand, and more likely to hide mistakes in the noise. It's also much more likely that what the review misses is a location where the change should have *also* been made, but which was skipped.

### Fragile Codebase

The more locations a single concept occupies, the more places there are for that concept to fall out of sync. Shotgun Surgery leads to inconsistencies that accumulate over time and become increasingly expensive to correct.

## Common Causes

- **Cross-cutting concerns implemented inline** — logging, validation, caching, or error handling duplicated in every method or class rather than centralized.
- **No abstraction for a shared concept** — a business rule (e.g., a tax rate, a discount formula, an access control check) is written out wherever it is needed rather than encapsulated in a single authoritative location.
- **Missing domain types** — related data and behavior spread across multiple classes because no dedicated type owns them (see [Data Clumps](./data-clumps) and [Primitive Obsession](./primitive-obsession-code-smell)).
- **[Combinatorial Explosion](./combinatorial-explosion)** — logic duplicated across a large number of near-identical methods or classes.

## Example

A tax calculation expressed in multiple places:

```csharp
// In OrderService
decimal tax = order.Subtotal * 0.08m;

// In InvoiceService
decimal tax = invoice.Amount * 0.08m;

// In QuoteService
decimal tax = quote.Total * 0.08m;
```

Changing the tax rate — or the tax calculation logic — requires updating three files. Miss one, and the system is inconsistent.

After consolidating:

```csharp
public class TaxCalculator
{
    private const decimal TaxRate = 0.08m;

    public decimal Calculate(decimal amount) => amount * TaxRate;
}
```

Now every service depends on `TaxCalculator`. Changing the rate or the formula is a single-file change.

## Addressing Shotgun Surgery

- **Move Method / Move Field** — relocate scattered logic to the class that owns the relevant data or concept.
- **Extract Class** — gather related fields and methods from multiple classes into a single new class that owns the concept.
- **Inline Class** — if a concept is spread across too many tiny classes without cohesion, consolidate them.
- **Introduce a Service or Policy object** — encapsulate a cross-cutting rule (pricing, tax, access control) in a dedicated class so there is one authoritative source.
- **Apply the [Single Responsibility Principle](/principles/single-responsibility-principle/)** — ensure each class has one reason to change, so changes to a concept require touching only one place.

## References

- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Refactoring: Improving the Design of Existing Code](https://martinfowler.com/books/refactoring.html) by Martin Fowler
