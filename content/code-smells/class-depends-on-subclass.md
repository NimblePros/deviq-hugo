---
title: Class Depends on Subclass Code Smell

date: 2026-03-08

description: The Class Depends on Subclass code smell occurs when a base class contains references to, or knowledge of, one or more of its own subclasses — inverting the expected dependency direction in an inheritance hierarchy.

weight: 40
---

The Class Depends on Subclass code smell occurs when a base class has direct knowledge of its subclasses — referencing them by name, using `typeof` checks, casting to them, or modeling behavior based on their existence. This inverts the intended relationship of inheritance: base classes should define contracts that subclasses fulfill, not be aware of who fulfills them. When the base knows about its children, the hierarchy can no longer be extended without modifying the base, and the [Liskov Substitution Principle](/principles/liskov-substitution-principle/) is undermined.

## How It Arises

This smell often appears as a class hierarchy ages and special-case behavior accumulates. Rather than adding a method to a subclass, a developer adds a check in the base: "if this is `PremiumOrder`, do X; otherwise, do Y." It also appears when a factory or registry is embedded in a base class, requiring the base to know which subclasses exist in order to instantiate them.

## Problems Caused by Class Depends on Subclass

### Broken Extensibility

The purpose of inheritance is to allow new subclasses to extend behavior without changing existing code — the [Open/Closed Principle](/principles/open-closed-principle/). When a base class knows about its subclasses, adding a new subclass often requires modifying the base. Exactly the modification the design was supposed to prevent.

### Circular Conceptual Dependency

Base classes are supposed to be more abstract and stable than subclasses. When a base references a subclass, it becomes dependent on something more specific than itself. The dependency direction runs in both directions — the subclass depends on the base (through inheritance) and the base depends on the subclass (through the reference). This circular dependency makes the hierarchy fragile and difficult to reason about.

### Tight Coupling

Any change to a subclass that affects the behavior the base class depends on requires coordinated changes in the base. The base and the specific subclass are entangled, and neither can evolve independently.

### Testing Difficulty

Unit testing a base class should not require instantiating specific subclasses. When the base class behavior depends on which subclass it is dealing with, it becomes difficult to test the base in isolation.

## Example

A base class that inspects its subclasses to vary behavior:

```csharp
public abstract class Order
{
    public virtual decimal CalculateShipping()
    {
        // Base class knows about its subclasses — this is the smell
        if (this is ExpressOrder expressOrder)
        {
            return expressOrder.ExpressFee + 5.00m;
        }
        if (this is InternationalOrder intlOrder)
        {
            return intlOrder.CustomsDuty + 15.00m;
        }
        return 5.00m;
    }
}

public class ExpressOrder : Order
{
    public decimal ExpressFee => 12.00m;
}

public class InternationalOrder : Order
{
    public decimal CustomsDuty => 25.00m;
}
```

`Order` must be modified every time a new subclass is introduced. The fix is to push the behavior down into each subclass:

```csharp
public abstract class Order
{
    public abstract decimal CalculateShipping();
}

public class StandardOrder : Order
{
    public override decimal CalculateShipping() => 5.00m;
}

public class ExpressOrder : Order
{
    public override decimal CalculateShipping() => 12.00m + 5.00m;
}

public class InternationalOrder : Order
{
    public override decimal CalculateShipping() => 25.00m + 15.00m;
}
```

Now `Order` knows nothing about its subclasses. Adding a `SameDayOrder` requires no changes to `Order` or any existing subclass.

## Related Smell: Type Checking in Base Class

A closely related manifestation is a base class that uses `is`, `as`, `typeof`, or a type-code field to branch on which subclass it is dealing with. This is essentially the [Switch Statements](./switch-statements) smell applied within the class hierarchy itself. Both indicate that behavior belonging in the subclass has leaked upward into the base.

## Refactoring

- **Push Down Method**: Move the behavior that varies by subclass into the subclass itself, making it a virtual or abstract method on the base.
- **Introduce Template Method**: Define a skeleton algorithm in the base with abstract or virtual hook methods that each subclass implements.
- **Replace Conditional with Polymorphism**: Replace any `is`/`typeof` checks on the subclass type with virtual method dispatch.
- **Extract Interface**: If the base class references a subclass to call a method specific to that subclass, define that method on an interface and have the subclass implement it.
- **Move Factory Out of Base**: If the smell arises from a factory or registry embedded in the base, move it to a dedicated factory class.

## References

- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Liskov Substitution Principle](/principles/liskov-substitution-principle/)
- [Open/Closed Principle](/principles/open-closed-principle/)
- [Switch Statements](./switch-statements)
- [Refactoring](/practices/refactoring/)
