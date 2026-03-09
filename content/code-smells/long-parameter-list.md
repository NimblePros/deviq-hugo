---
title: Long Parameter List Code Smell

date: 2026-03-08

description: The Long Parameter List code smell occurs when a method or function requires too many parameters, making it difficult to call correctly, understand at a glance, and maintain over time.

---

The Long Parameter List code smell occurs when a method or function requires too many parameters. While there is no hard rule on the maximum number of parameters, methods with four or more parameters are worth scrutinizing, and those with many more are almost certainly doing too much or missing an abstraction. Long parameter lists are hard to read, easy to call incorrectly, and often signal that related data should be grouped into a dedicated type.

Long parameter lists frequently co-occur with other smells, such as [Primitive Obsession](./primitive-obsession-code-smell) (where concepts represented by multiple primitives should be a typed object) and [Long Method](./long-method) (where a method doing too much needs data from many sources).

## Problems Caused by Long Parameter Lists

### Poor Readability

Call sites become hard to read when many arguments are passed positionally. Without named arguments, it is difficult to know what each value represents without looking at the method signature.

```csharp
// What does each argument mean?
CreateUser("Alice", "alice@example.com", true, false, 30, "USD", "en-US");
```

### Easy to Call Incorrectly

When multiple parameters share the same type, swapping them is a compile-time-silent bug. Passing `firstName` where `lastName` is expected, or `startDate` where `endDate` belongs, produces no compiler error and can be very hard to spot in review.

### Violation of the Single Responsibility Principle

A method that requires many unrelated parameters is often doing several distinct jobs. Each group of related parameters hints at a missing abstraction — a class or record that should own those values and their associated behavior.

### Harder to Extend

Adding a new requirement often means adding yet another parameter, forcing updates to every call site. If the parameters had been grouped into an object, more properties can be added with minimal impact on existing callers.

### Increased Cognitive Load

Every additional parameter is one more thing a caller must know, supply correctly, and keep in sync. The more parameters a method has, the more mental effort it takes to use it — both now and for every future developer who reads the code.

## Example

```csharp
// Long parameter list — hard to read and easy to misuse
public Order CreateOrder(
    int customerId,
    string customerEmail,
    string shippingStreet,
    string shippingCity,
    string shippingState,
    string shippingZip,
    string shippingCountry,
    decimal subtotal,
    decimal taxRate,
    string couponCode)
{
    // ...
}
```

Callers must supply ten arguments in the correct order. Related values (shipping address, pricing info) are scattered as loose primitives rather than cohesive objects.

## Addressing Long Parameter Lists

### Introduce Parameter Object

Group related parameters into a class or record. This is the most common and effective fix:

```csharp
public record Address(
    string Street,
    string City,
    string State,
    string Zip,
    string Country);

public record OrderRequest(
    int CustomerId,
    string CustomerEmail,
    Address ShippingAddress,
    decimal Subtotal,
    decimal TaxRate,
    string? CouponCode);

public Order CreateOrder(OrderRequest request)
{
    // ...
}
```

The call site becomes readable and the compiler enforces correctness:

```csharp
var order = CreateOrder(new OrderRequest(
    CustomerId: 42,
    CustomerEmail: "alice@example.com",
    ShippingAddress: new Address("123 Main St", "Springfield", "IL", "62701", "US"),
    Subtotal: 99.99m,
    TaxRate: 0.08m,
    CouponCode: null));
```

### Preserve Whole Object

If all of the parameters come from a single object that already exists in the calling context, pass the object itself instead of extracting its individual properties:

```csharp
// Instead of:
ProcessShipment(order.Street, order.City, order.State, order.Zip);

// Pass the object:
ProcessShipment(order.ShippingAddress);
```

### Replace Parameter with Method Call

If a parameter value can be derived from information the method already has access to, remove the parameter and compute the value inside the method:

```csharp
// Instead of passing taxRate as a parameter:
decimal tax = _taxService.GetRate(order.ShippingAddress);
```

### Split the Method

If parameters naturally fall into distinct groups that are never all needed together, the method may be doing too much. Split it into smaller, focused methods, each with a shorter parameter list.

### Use a Builder

For complex construction scenarios where many optional parameters exist, the [Builder Pattern](/design-patterns/builder-pattern/) provides a fluent, readable API that avoids long constructor or method signatures:

```csharp
var order = new OrderBuilder()
    .ForCustomer(customerId, customerEmail)
    .ShipTo(address)
    .WithSubtotal(99.99m)
    .WithTaxRate(0.08m)
    .Build();
```

## References

- [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
- [Refactoring: Improving the Design of Existing Code](https://martinfowler.com/books/refactoring.html) by Martin Fowler
- [Code That Fits in Your Head](https://www.informit.com/store/code-that-fits-in-your-head-heuristics-for-software-9780137464401) by Mark Seemann
