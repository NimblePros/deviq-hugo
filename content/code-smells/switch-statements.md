---
title: Switch Statements Code Smell

date: 2026-03-08

description: The Switch Statements code smell occurs when switch or if-else chains are used to vary behavior based on an object's type or state, rather than leveraging polymorphism.

---

The Switch Statements code smell occurs when `switch` statements (or equivalent `if-else` chains) are used to branch on an object's type, kind, or status to determine which behavior to execute. While a single switch is not inherently problematic, the smell arises when the same type-based dispatch is duplicated in multiple places across the codebase — or when adding a new type requires hunting down every switch and modifying it.

Object-oriented design is well-suited to this problem: instead of asking "what type is this?" and branching, the behavior can be pushed into the objects themselves via polymorphism. Each type knows how to perform the relevant operation, and the caller simply invokes it without needing to know which concrete type it has.

This smell is related to [Primitive Obsession](/code-smells/primitive-obsession-code-smell/), since switch statements frequently appear when type codes (integers, strings, or enums) are used to distinguish objects that should be separate types. It is also related to [Inconsistency](/code-smells/inconsistency/): when a switch on the same enum exists in five places, they often drift out of sync as the codebase evolves.

## Problems Caused by Switch Statements

### Violated Open/Closed Principle

Every switch that dispatches on a type is a place that must change when a new type is added. Adding a new `OrderType`, `PaymentMethod`, or `ShapeKind` requires finding and modifying every switch in the codebase — a violation of the [Open/Closed Principle](/principles/open-closed-principle/). With polymorphism, adding a new type means adding a new class; no existing switch needs to change.

### Shotgun Surgery

Because the same type enumeration tends to appear in multiple switches across the codebase, adding a new variant requires modifying many files simultaneously — a classic case of [Shotgun Surgery](/code-smells/shotgun-surgery/).

### Poor Encapsulation

Behavior that belongs to a type is scattered across the codebase in switch arms rather than encapsulated in the type itself. This makes types passive data holders rather than active behavioral participants, which loses much of the advantage of object-oriented design.

### Fragile Defaults

Switch statements commonly have a `default` case that silently does nothing or throws a generic exception. When a new type is added and a switch is missed, the default case may hide the error entirely, producing subtle incorrect behavior rather than a compile-time error.

## Example

Consider an order processing system with multiple order types:

```csharp
public decimal CalculateDiscount(Order order)
{
    switch (order.Type)
    {
        case OrderType.Standard:
            return 0m;
        case OrderType.Wholesale:
            return order.Total * 0.15m;
        case OrderType.LoyaltyMember:
            return order.Total * 0.1m;
        default:
            throw new ArgumentOutOfRangeException();
    }
}

public string GetShippingLabel(Order order)
{
    switch (order.Type)
    {
        case OrderType.Standard:
            return "Standard Shipping";
        case OrderType.Wholesale:
            return "Freight Shipping";
        case OrderType.LoyaltyMember:
            return "Priority Shipping";
        default:
            throw new ArgumentOutOfRangeException();
    }
}
```

Adding a new `OrderType.VIP` requires updating both methods — and any other switch on `OrderType` elsewhere in the codebase. With polymorphism, each order type carries its own behavior:

```csharp
public abstract class Order
{
    public abstract decimal CalculateDiscount();
    public abstract string GetShippingLabel();
}

public class StandardOrder : Order
{
    public override decimal CalculateDiscount() => 0m;
    public override string GetShippingLabel() => "Standard Shipping";
}

public class WholesaleOrder : Order
{
    public override decimal CalculateDiscount() => Total * 0.15m;
    public override string GetShippingLabel() => "Freight Shipping";
}

public class LoyaltyMemberOrder : Order
{
    public override decimal CalculateDiscount() => Total * 0.1m;
    public override string GetShippingLabel() => "Priority Shipping";
}
```

Adding a `VIPOrder` class requires no changes to existing code.

## When Switch Statements Are Acceptable

Not every switch is a smell. Switches are appropriate when:

- The branching is isolated to a single place (typically a factory or mapper) and does not recur.
- The cases are truly unrelated behaviors with no shared interface.
- The code is operating at a boundary (e.g., mapping an external integer code to an internal domain type) where polymorphism cannot reach.

The smell is specifically about *repeated* type-dispatch switches spreading across the codebase.

## Refactoring

- **Replace Conditional with Polymorphism**: Extract each branch into a subclass or strategy that implements the behavior for that case.
- **Replace Type Code with Subclass**: Replace an enumerated type code with a class hierarchy where each subclass represents one variant.
- **[Strategy Pattern](/design-patterns/strategy-pattern/)**: Encapsulate each variant's behavior in a separate strategy object, which can be selected at construction time or via a factory.
- **[State Pattern](/design-patterns/state-design-pattern/)**: When the switch selects behavior based on the object's current state, the State pattern distributes that behavior into state objects.
- **[Null Object Pattern](/design-patterns/null-object-pattern/)**: If one branch handles the null/none case, replace it with a Null Object that implements the same interface.

## References

- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Open/Closed Principle](/principles/open-closed-principle/)
- [Primitive Obsession](/code-smells/primitive-obsession-code-smell/)
- [Shotgun Surgery](/code-smells/shotgun-surgery/)
- [Strategy Pattern](/design-patterns/strategy-pattern/)
- [State Pattern](/design-patterns/state-design-pattern/)
