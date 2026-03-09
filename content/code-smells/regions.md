---
title: Regions Code Smell

date: 2026-03-08

description: The Regions code smell occurs when code is hidden behind collapsible region directives rather than being organized through proper structure, small classes, and well-named methods.

---

The Regions code smell occurs when developers use collapsible region directives — such as `#region` in C# or equivalent constructs in other languages — to organize or hide code within a file. Rather than addressing the underlying problem (a type or method that has grown too large), regions paper over it with a cosmetic folding mechanism. When you find yourself reaching for a region, it is almost always a sign that the code needs to be refactored rather than hidden.

This smell is closely related to other obfuscators like [Poor Names](./poor-names) and [Comments](./comments), as all three tend to hide intent rather than resolve the root cause. Regions are particularly insidious because IDEs collapse them by default in some configurations, meaning important code can be hidden from view entirely, making the problem invisible without active effort.

## Problems Caused by Regions

### They Signal Structural Problems

The need to use a region is a diagnostic symptom. If a class is so large that you need regions to navigate it, the class likely violates the [Single Responsibility Principle](/principles/single-responsibility-principle/). The region is a workaround for a structural problem that should be fixed by breaking the class into smaller, focused types.

### They Hide Complexity

Collapsing a region can make a large file look manageable in the IDE. This makes it easy to ignore overgrown classes and methods. The illusion of organization can delay necessary [refactoring](/practices/refactoring/) indefinitely.

### They Interrupt Reading Flow

Even when code is logically ordered, arbitrary region boundaries break that flow. To understand how a method relates to its neighbors, a reader may need to manually expand and collapse multiple regions. Code without regions can be read top to bottom without interruption.

### They Fragment Cohesive Concepts

Regions tempt developers to split closely related code (for example, fields, properties, and their associated methods) into separate blocks scattered across a file. This makes it harder to trace the relationship between related members.

## Example

A class organized with regions may look like this:

```csharp
public class OrderProcessor
{
    #region Fields
    private readonly IOrderRepository _repository;
    private readonly IEmailService _emailService;
    private decimal _taxRate;
    #endregion

    #region Constructors
    public OrderProcessor(IOrderRepository repository, IEmailService emailService)
    {
        _repository = repository;
        _emailService = emailService;
        _taxRate = 0.08m;
    }
    #endregion

    #region Validation
    private bool IsValid(Order order) { ... }
    private void ValidateItems(List<OrderItem> items) { ... }
    #endregion

    #region Processing
    public void Process(Order order) { ... }
    private void ApplyDiscounts(Order order) { ... }
    private void CalculateTax(Order order) { ... }
    #endregion

    #region Notifications
    private void SendConfirmation(Order order) { ... }
    private void NotifyWarehouse(Order order) { ... }
    #endregion
}
```

The regions here are a flag that `OrderProcessor` is doing too much. The processing and notification concerns should be extracted to separate classes:

```csharp
public class OrderProcessor
{
    private readonly IOrderValidator _validator;
    private readonly IOrderCalculator _calculator;
    private readonly IOrderNotifier _notifier;

    public OrderProcessor(IOrderValidator validator, IOrderCalculator calculator, IOrderNotifier notifier)
    {
        _validator = validator;
        _calculator = calculator;
        _notifier = notifier;
    }

    public void Process(Order order)
    {
        _validator.Validate(order);
        _calculator.Calculate(order);
        _notifier.Notify(order);
    }
}
```

No regions are needed when each class has a single, clear responsibility.

## Tooling

Before refactoring, it helps to understand the scope of the problem. The [nmbl](https://nmbl.dev/) command-line tool provides two commands specifically for this:

- [`nmbl regions <ProjectFileOrDirectory>`](https://nmbl.dev/docs/commands/regions-region-count/) — counts `#region` directives across C# files, showing which files have regions and how many.
- [`nmbl endregions <ProjectFileOrDirectory> [-y]`](https://nmbl.dev/docs/commands/endregions-remove-region-directives/) — removes all `#region` and `#endregion` directives from C# files. The `-y` flag skips the confirmation prompt.

A typical workflow is to assess first, then remove:

```bash
# See what exists
nmbl regions src/

# Remove all region directives
nmbl endregions src/ -y
```

Removing the directives is a safe, mechanical step — the code inside each region is preserved. The harder work of actually refactoring large classes into smaller ones follows separately.

## Refactoring

The primary refactoring for regions is to eliminate them by addressing the structural problem:

- Use **Extract Class** to break large types into focused, cohesive classes.
- Use **Extract Method** to break long methods into smaller, well-named ones.
- If a region groups related public members, consider whether they belong in a separate interface or base type.

Once a class is small and focused, regions are unnecessary. A class that genuinely needs a region to be navigable is a class that needs to be refactored.

## References

- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Single Responsibility Principle](/principles/single-responsibility-principle/)
- [Refactoring](/practices/refactoring/)
