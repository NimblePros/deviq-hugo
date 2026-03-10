---
title: Prototype Design Pattern

date: 2026-03-09

description: The Prototype Design Pattern creates new objects by copying an existing instance rather than constructing from scratch. Learn when to use it and how to implement deep and shallow cloning in C#.
---

## What is the Prototype Design Pattern?

The Prototype Design Pattern is a creational pattern that creates new objects by **cloning an existing instance** — the *prototype* — rather than constructing a new one from scratch. The clone may be a *shallow copy* (sharing references to nested objects) or a *deep copy* (duplicating the entire object graph).

This is useful when:

- Object construction is expensive (e.g., it involves database queries, file I/O, or complex calculations) and you need many similar instances.
- You need to produce objects whose exact type is unknown at compile time.
- You want to avoid re-applying the same configuration to a new object when you can instead copy a pre-configured prototype.
- The classes to be instantiated are specified at runtime.

The pattern is built into .NET through the `ICloneable` interface, though using it has caveats (see below). Modern C# idioms offer cleaner alternatives.

## Shallow vs. Deep Copy

A **shallow copy** duplicates the object's value-type fields but copies only the *references* to any reference-type fields. Both the original and the clone then point to the same nested objects — a mutation through one will be visible through the other.

A **deep copy** recursively duplicates every referenced object, producing a completely independent copy.

Choosing between them depends on whether the cloned object needs to own its sub-objects exclusively.

## C# Example

### Using `ICloneable` (shallow copy)

.NET's built-in `ICloneable` interface declares a single `Clone()` method. `MemberwiseClone()` (inherited from `object`) performs a shallow copy and is typically used in the implementation:

```csharp
public class Address
{
    public string Street { get; set; } = "";
    public string City { get; set; } = "";
}

public class Employee : ICloneable
{
    public string Name { get; set; } = "";
    public Address Address { get; set; } = new();

    // Shallow copy — Address reference is shared with the clone.
    public object Clone() => MemberwiseClone();
}

// Usage
var original = new Employee { Name = "Alice", Address = new Address { Street = "1 Main St", City = "Springfield" } };
var shallow = (Employee)original.Clone();

shallow.Name = "Bob";              // Does not affect original
shallow.Address.City = "Shelbyville"; // DOES affect original — shared reference!
```

### Deep Copy Using a Copy Constructor

A copy constructor is a common and explicit way to produce deep copies without the ambiguity of `ICloneable`:

```csharp
public class Address
{
    public string Street { get; set; } = "";
    public string City { get; set; } = "";

    // Copy constructor
    public Address(Address other)
    {
        Street = other.Street;
        City = other.City;
    }
}

public class Employee
{
    public string Name { get; set; } = "";
    public Address Address { get; set; } = new Address { Street = "", City = "" };

    // Copy constructor performs a deep copy
    public Employee(Employee other)
    {
        Name = other.Name;
        Address = new Address(other.Address);
    }

    public Employee DeepClone() => new Employee(this);
}

// Usage
var original = new Employee { Name = "Alice", Address = new Address { Street = "1 Main St", City = "Springfield" } };
var deep = original.DeepClone();

deep.Address.City = "Shelbyville"; // original is unaffected
```

### Deep Copy Using Records (C# 9+)

C# `record` types provide `with` expressions that create a shallow copy with specified properties overridden. For shallow hierarchies this is a clean and concise alternative:

```csharp
public record Address(string Street, string City);
public record Employee(string Name, Address Address);

var original = new Employee("Alice", new Address("1 Main St", "Springfield"));

// Shallow clone with one property changed
var clone = original with { Name = "Bob" };

// Deep clone — replace the nested record too
var deepClone = original with { Address = original.Address with { City = "Shelbyville" } };
```

## Caveats with `ICloneable`

The .NET `ICloneable` interface does not specify whether `Clone()` returns a shallow or deep copy — the contract is ambiguous. For this reason many style guides (including the .NET Framework Design Guidelines) recommend avoiding `ICloneable` in public APIs and instead providing an explicitly named method such as `DeepClone()` or a copy constructor.

## Prototype Registry

An extension of the basic pattern, a *prototype registry* (or *prototype manager*) stores a set of named prototypes that clients can clone on demand without knowing the concrete types:

```csharp
public class EmployeePrototypeRegistry
{
    private readonly Dictionary<string, Employee> _prototypes = new();

    public void Register(string key, Employee prototype) =>
        _prototypes[key] = prototype;

    public Employee Get(string key) =>
        _prototypes[key].DeepClone();
}
```

## Intent

Specify the kinds of objects to create using a prototypical instance, and create new objects by copying this prototype. [GoF](http://amzn.to/vep3BT)

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Amazon - [Design Patterns: Elements of Reusable Object-Oriented Software](http://amzn.to/vep3BT) - Gang of Four
