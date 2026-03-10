---
title: Data Clumps Code Smell

date: 2026-03-08

description: The Data Clumps code smell occurs when the same group of data items repeatedly appears together across multiple classes or method signatures, signaling that the group deserves its own type.

weight: 100
---

The Data Clumps code smell occurs when the same group of data items repeatedly appears together — in field declarations, method parameters, or local variables — across multiple places in a codebase. If you find yourself always passing `street`, `city`, `state`, and `zip` together, or always seeing `startDate` and `endDate` side by side, those values are clumping because they belong together. The fix is to introduce a type that names and owns the concept they collectively represent.

Data Clumps are closely related to [Primitive Obsession](./primitive-obsession-code-smell) and [Long Parameter List](./long-parameter-list). In fact, a long parameter list is often made up of one or more data clumps in disguise.

## Problems Caused by Data Clumps

### Missing Abstraction

When the same group of fields recurs, the code is telling you that an important concept in the domain has no name or type. Naming that concept in a class or record makes the domain model more expressive and easier to reason about.

### Duplication

Logic that operates on the clump — validation, formatting, calculation — tends to be duplicated wherever the clump appears. There is no single home for the behavior because there is no single type to put it in. Introducing a type consolidates that logic in one place, in keeping with the [Don't Repeat Yourself (DRY)](/principles/dont-repeat-yourself/) principle.

### Fragility

When a clump needs to change — say, an address gains a second address line — every method signature and class that carries the clump must be updated. A single type means a single change.

### Reduced Readability

A method that accepts `(string street, string city, string state, string zip, string country)` is harder to read and easier to misuse than one that accepts an `Address`. The named type communicates intent at a glance.

## Example

A data clump appearing in both a field group and a method signature:

```csharp
public class Customer
{
    public string ShippingStreet { get; set; }
    public string ShippingCity { get; set; }
    public string ShippingState { get; set; }
    public string ShippingZip { get; set; }
    public string ShippingCountry { get; set; }
}

public class OrderService
{
    public decimal CalculateShippingCost(
        string street,
        string city,
        string state,
        string zip,
        string country)
    {
        // ...
    }
}
```

The same five fields appear in two places. Adding a country-code format requirement means updating both — and any other clumps of the same data elsewhere.

After introducing an `Address` type:

```csharp
public record Address(
    string Street,
    string City,
    string State,
    string Zip,
    string Country)
{
    public bool IsValid() => !string.IsNullOrWhiteSpace(Street)
        && !string.IsNullOrWhiteSpace(City)
        && !string.IsNullOrWhiteSpace(Zip);
}

public class Customer
{
    public Address ShippingAddress { get; set; }
}

public class OrderService
{
    public decimal CalculateShippingCost(Address destination)
    {
        // ...
    }
}
```

Validation lives inside `Address`. Both `Customer` and `OrderService` share the same type. The concept has a name.

## Identifying Data Clumps

A useful test: if you removed one item from a group, would the rest still be meaningfully related? If not — if `city`, `state`, and `zip` do not make sense together without `street` — the group is a data clump and belongs in a type. Brian Foote and Joseph Yoder describe this intuition in the context of finding missing objects in a design.

Look for clumps in:

- **Field declarations** — multiple fields on a class that always appear and change together.
- **Method parameters** — the same set of parameters appearing across several methods.
- **Local variables** — a group of variables declared together and always passed together.

Another way you can often identify data clumps in class properties and fields is through the use of whitespace and/or comments. Developers know these things really belong together, so they'll often organize them that way through formatting if not through proper types. Some examples:

```csharp
// other properties

// start point
public int StartX { get; set; }
public int StartY { get; set; }

// end point
public int EndX { get; set; }
public int EndY { get; set; }

// format
public string Color { get; set; }
public int LineWeight { get; set;}
```

It's fortunate that dotnet includes a `DateTime` type - can you imagine how many data clumps there would be if every class that had a time stampe for `DateCreated` and `DateUpdated` had to include something like this?

```csharp
// date created
public int YearCreated { get; set; }
public int MonthCreated { get; set; }
public int DayCreated { get; set; }
public int HourCreated { get; set; }
public int MinuteCreated { get; set; }
public int SecondCreated { get; set; }
```

Obviously using a `DateTime` type instead of these primites makes a lot of sense - apply the same logic to other such clumps of related primitives.

## Addressing Data Clumps

- **Extract Class** — create a new class or record to hold the clumped fields and any behavior that belongs to them.
- **Introduce Parameter Object** — replace a recurring group of parameters with a single object (see [Long Parameter List](./long-parameter-list)).
- **Preserve Whole Object** — when pulling values out of an existing object to pass into a method, pass the object itself instead.
- **Use Value Objects** — if the clump represents a domain concept with no identity (e.g., `Money`, `DateRange`, `Address`), model it as an immutable [Value Object](/domain-driven-design/value-object/) that encapsulates both data and behavior.

## References

- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Refactoring: Improving the Design of Existing Code](https://martinfowler.com/books/refactoring.html) by Martin Fowler
