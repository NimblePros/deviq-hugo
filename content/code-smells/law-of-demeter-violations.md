---
title: Law of Demeter Violations Code Smell

date: 2026-03-09

description: Law of Demeter Violations occur when code navigates deeply through object graphs to access distant collaborators, creating tight coupling to intermediate structures that may change.

---

Law of Demeter Violations occur when code accesses objects from distant parts of an object graph rather than limiting interactions to immediate collaborators. The [Law of Demeter](/laws/law-of-demeter/) — also called the Principle of Least Knowledge — states that a method should only talk to its immediate neighbors: the object it is called on, its own fields, objects received as parameters, and objects it creates itself. Any access that chains through another object's return value to reach a third party is a violation.

The informal rule is: "talk to friends, not strangers." A method that calls `order.GetCustomer().GetAddress().GetCity()` has to know about `Order`, `Customer`, `Address`, and `City` — four types just to get one piece of information. The caller is coupled to the entire chain.

## Problems Caused by Law of Demeter Violations

### Tight Coupling to Intermediate Structure

Each dot in a method chain is a dependency on an intermediate type. If `Order` stops returning a `Customer` directly — perhaps it now returns a `CustomerReference` — every chain that traverses `Order.GetCustomer()` must change. The caller knows more about the structure of the object graph than it should.

### Fragile Code

Chains break whenever any intermediate object is null, changes its interface, or is restructured. Long dot-chains are a common source of `NullReferenceException` and runtime errors that are difficult to trace. Each link in the chain is a potential failure point.

### Reduced Readability

Long navigation chains obscure the intent of the code. `customer.GetPreferences().GetNotificationSettings().IsEmailEnabled()` takes more mental effort to parse than a well-named method that encapsulates the same navigation.

### Harder to Test

To test a method that navigates a deep chain, a test must construct or mock every object in the chain. Changing any intermediate type forces changes to multiple tests, even when the observable behavior hasn't changed.

## Example

A violation navigating from an `OrderProcessor` through the order graph:

```csharp
public class OrderProcessor
{
    public void Process(Order order)
    {
        string city = order.GetCustomer().GetAddress().GetCity();
        decimal rate = order.GetCustomer().GetAddress().GetTaxRate();

        // use city and rate...
    }
}
```

`OrderProcessor` knows about `Order`, `Customer`, and `Address`. It is coupled to the internals of an object three levels away.

After delegating through proper collaborators:

```csharp
public class Order
{
    private Customer _customer;

    public string GetShippingCity() => _customer.GetAddress().GetCity();
    public decimal GetTaxRate() => _customer.GetAddress().GetTaxRate();
}

public class OrderProcessor
{
    public void Process(Order order)
    {
        string city = order.GetShippingCity();
        decimal rate = order.GetTaxRate();

        // use city and rate...
    }
}
```

`OrderProcessor` now speaks only to `Order`. The navigation is hidden behind `Order`'s interface. If `Customer` or `Address` is restructured, only `Order` needs to change — not every caller.

## Identifying Law of Demeter Violations

Look for:

- Method chains with three or more dots: `a.B().C().D()`.
- Repeated traversal of the same chain in multiple places.
- Tests that require constructing a deep object graph just to test a small behavior.
- Methods that receive one object but end up primarily working with objects retrieved from that object.

Note that fluent interfaces — such as LINQ chains or builder patterns — are generally not Law of Demeter violations because every method in the chain returns the same type or a closely related type by design. The violation arises when navigating through unrelated object boundaries.

## Relationship to Other Smells

Law of Demeter Violations are the direct cause of [Message Chains](./message-chains). [Feature Envy](./feature-envy) often accompanies violations, because a method that navigates deep into another object's structure may be doing work that belongs on an intermediate object.

## Refactoring

- **Hide Delegate** — add a method to the immediate collaborator that performs the navigation so callers only interact with one level.
- **Move Method** — if a method navigates into another class's internals to do its work, consider moving it closer to the data it needs.
- **Introduce Query Method** — give the intermediate class a method that answers the question being asked, so the caller doesn't have to navigate.
