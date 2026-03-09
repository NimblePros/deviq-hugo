---
title: Duplicate Code Code Smell

date: 2026-03-09

description: Duplicate Code is the presence of identical or near-identical code in more than one location, requiring changes to be made in multiple places when the logic needs to evolve.

---

Duplicate code is the presence of identical or structurally similar code in more than one location. It is widely considered the most fundamental of code smells. Every instance of duplication means that a future change to that logic must be found, understood, and applied in multiple places. If any instance is missed, the system becomes inconsistent. If the logic is wrong, the bug is wrong in multiple places simultaneously.

The [Don't Repeat Yourself (DRY) principle](/principles/dont-repeat-yourself/) directly addresses this smell: duplication in logic should be eliminated through abstraction. The cost of duplication compounds over time. What appears to be a shortcut — copying existing code rather than extracting a shared abstraction — becomes a maintenance burden and a source of bugs.

## Common Forms of Duplicate Code

### Identical Code in Multiple Methods

The clearest form: the same sequence of statements appears verbatim or near-verbatim in two or more methods. This often arises from [copy-paste programming](/antipatterns/copy-paste-programming/).

```csharp
public decimal CalculateRetailTotal(IEnumerable<LineItem> items)
{
    decimal subtotal = 0;
    foreach (var item in items)
        subtotal += item.Quantity * item.UnitPrice;
    return subtotal * 1.08m; // with tax
}

public decimal CalculateWholesaleTotal(IEnumerable<LineItem> items)
{
    decimal subtotal = 0;
    foreach (var item in items)
        subtotal += item.Quantity * item.UnitPrice;
    return subtotal; // tax-exempt
}
```

The subtotal calculation is duplicated. A change to how subtotal is calculated — to account for discounts or rounding — must be applied in both places.

### Similar Code in Sibling Classes

Two classes in the same hierarchy contain methods that do the same thing. This is often addressed with **Pull Up Method**, moving the shared implementation into the base class.

### Parallel Algorithms

Two separate code paths implement the same algorithm with only minor structural variation. The duplication is harder to see because the code is not literally identical, but the logic is the same.

### Test Code Duplication

Duplicate setup code, repeated assertion patterns, or copy-pasted test methods. Test duplication is still duplication — it makes tests harder to maintain and hides the intent of what is actually being tested.

## Consequences of Duplicate Code

- **Inconsistent behavior**: When logic evolves, duplicated copies are not always found and updated together. This produces subtle differences in behavior between code paths that should behave identically.
- **Bug multiplication**: A bug in duplicated logic is a bug in every copy. Fixing it requires finding all copies.
- **Increased cognitive load**: Readers must read every copy of the logic and determine whether the copies are truly equivalent or subtly different.
- **Resistance to refactoring**: Duplicate code is harder to safely refactor because changes must be made in multiple places simultaneously.

## Addressing Duplicate Code

### Extract Method

The most common remedy. Identify the duplicated logic, extract it into a method with a clear name, and replace all instances with a call to that method:

```csharp
private decimal CalculateSubtotal(IEnumerable<LineItem> items)
    => items.Sum(item => item.Quantity * item.UnitPrice);

public decimal CalculateRetailTotal(IEnumerable<LineItem> items)
    => CalculateSubtotal(items) * 1.08m;

public decimal CalculateWholesaleTotal(IEnumerable<LineItem> items)
    => CalculateSubtotal(items);
```

### Pull Up Method

When duplication exists in sibling classes, move the shared method to a common base class or implement it in a shared interface.

### Form Template Method

When two methods in sibling classes share the same overall structure but differ in specific steps, the Template Method pattern provides a way to express the shared algorithm once while allowing the variable steps to be overridden.

### Extract Class or Service

When duplication spans multiple unrelated types, the duplicated logic may belong in a dedicated class that all callers can use.

## When Duplication Is Acceptable

Not every apparent duplication should be eliminated. The [DRY principle](/principles/dont-repeat-yourself/) applies to *knowledge* and *intent*, not just surface-level textual similarity. Two pieces of code that look the same but represent different business concepts may legitimately evolve independently. Premature de-duplication can create inappropriate coupling — a change to one concept forces a change to the other because they share an abstraction that does not actually unify them.

The test: if both copies would always change together, they represent the same knowledge and duplication is a problem. If they might change independently, the shared appearance is coincidental.

## References

- [Refactoring: Improving the Design of Existing Code](https://martinfowler.com/books/refactoring.html) by Martin Fowler
- [Don't Repeat Yourself](/principles/dont-repeat-yourself/)
- [Copy Paste Programming](/antipatterns/copy-paste-programming/)
- [Once and Only Once](/principles/once-and-only-once/)
