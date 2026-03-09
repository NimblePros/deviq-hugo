---
title: Message Chains Code Smell

date: 2026-03-09

description: Message Chains is a code smell where code navigates a long sequence of object references to reach a distant collaborator, coupling the caller to every object in the chain.

---

Message Chains is a code smell where code sends a message to an object and then immediately sends another message to the result, forming a chain: `a.GetB().GetC().DoSomething()`. Each step in the chain retrieves an object from within the previous one, forcing the caller to navigate the entire internal structure of a collaborator's object graph.

Message Chains are the visible symptom of [Law of Demeter Violations](./law-of-demeter-violations). Every link in the chain is an implicit dependency on an intermediate type that the caller should not need to know about.

## Problems Caused by Message Chains

### Coupling to Internal Structure

The caller must understand the object model deeply enough to navigate the chain. If any intermediate type changes — `Customer` no longer returns `Address` directly, or `Address` gains a level of indirection — the caller breaks. Each link in the chain is a fragile dependency.

### Brittle Code

Long chains are a common source of `NullReferenceException`. Any object in the chain might be null, and there is usually no null-checking at the intermediate steps. The more links, the more potential failure points.

### Poor Readability

`order.Customer.PrimaryContact.PreferredAddress.City` takes effort to parse. The reader must follow the chain mentally to understand what is ultimately being retrieved. A well-named method on the owning class communicates the intent directly.

### Duplication

When the same chain appears in multiple places, it is duplicated knowledge about the object structure. If the structure changes, every occurrence of the chain must be updated.

## Example

A method that chains through multiple objects to retrieve shipping information:

```csharp
public class OrderSummaryBuilder
{
    public string Build(Order order)
    {
        string city = order.GetCustomer().GetPrimaryAddress().GetCity();
        string country = order.GetCustomer().GetPrimaryAddress().GetCountry();
        decimal tax = order.GetCustomer().GetPrimaryAddress().GetTaxRate();

        return $"Shipping to {city}, {country} — Tax rate: {tax:P}";
    }
}
```

`OrderSummaryBuilder` knows about `Order`, `Customer`, `Address`, and their structural relationships — all to build a simple summary.

After hiding the chain behind a meaningful method:

```csharp
public class Order
{
    private Customer _customer;

    public string GetShippingCity() => _customer.GetPrimaryAddress().GetCity();
    public string GetShippingCountry() => _customer.GetPrimaryAddress().GetCountry();
    public decimal GetShippingTaxRate() => _customer.GetPrimaryAddress().GetTaxRate();
}

public class OrderSummaryBuilder
{
    public string Build(Order order)
    {
        return $"Shipping to {order.GetShippingCity()}, {order.GetShippingCountry()} "
             + $"— Tax rate: {order.GetShippingTaxRate():P}";
    }
}
```

`OrderSummaryBuilder` now talks only to `Order`. The internal navigation is encapsulated where it belongs.

## Identifying Message Chains

Look for:

- Method calls with three or more chained dots that cross object boundaries: `a.B().C().D()`.
- The same chain appearing in multiple places in the codebase.
- Tests that require deep object graph construction to test a simple behavior.
- Long member access expressions getting assigned to intermediate variables just to make them readable.

Be careful not to confuse Message Chains with fluent APIs. A builder or LINQ statement like `orders.Where(...).OrderBy(...).Select(...)` is not a Message Chain — each step is part of a deliberately designed query or construction API and returns the same logical type. Message Chains involve traversing across different object responsibilities.

## When Chaining Is Appropriate

Not all chains are smells. Several well-established patterns rely on method chaining by design, and they do not violate the Law of Demeter because each method in the chain returns the same type (or a closely related type within the same abstraction), rather than reaching into a foreign object's internals.

### Builder Pattern

The [Builder pattern](/design-patterns/builder-pattern/) uses chaining intentionally. Each method configures one aspect of the object under construction and returns the builder itself, allowing the entire configuration to be expressed in a readable, linear sequence:

```csharp
var request = new HttpRequestBuilder()
    .WithMethod(HttpMethod.Post)
    .WithUrl("https://api.example.com/orders")
    .WithHeader("Authorization", $"Bearer {token}")
    .WithJsonBody(orderPayload)
    .Build();
```

Every method returns `HttpRequestBuilder`. The caller is not navigating through different object boundaries — it is accumulating configuration on a single builder. This is cohesive, intentional, and readable.

### Fluent Interfaces

A fluent interface is an API designed so that method calls can be chained to express a sequence of operations in a natural, readable style. LINQ is the canonical example in .NET:

```csharp
var result = orders
    .Where(o => o.Status == "Pending")
    .OrderBy(o => o.CreatedAt)
    .Select(o => new OrderSummary(o.Id, o.Total))
    .ToList();
```

Each method returns `IEnumerable<T>` — the same abstraction — and the chain expresses a single pipeline of transformations. There is no traversal of object boundaries and no coupling to internal structure.

Other examples include assertion libraries, query builders, and configuration APIs:

```csharp
// Assertion library (e.g., FluentAssertions)
result.Should().NotBeNull().And.HaveCount(3);

// EF Core query builder
var customers = await context.Customers
    .Where(c => c.IsActive)
    .Include(c => c.Orders)
    .OrderBy(c => c.LastName)
    .ToListAsync();
```

### The Key Distinction

The practical test is: *does each step in the chain return the same type (or a designed-for continuation type), or does it return a different object whose internals are then navigated?*

| Chain type | Each step returns | Verdict |
|---|---|---|
| `order.GetCustomer().GetAddress().GetCity()` | A different object each time | Message Chain — smell |
| `builder.WithName("x").WithTimeout(30).Build()` | The same builder type | Fluent Builder — intentional |
| `list.Where(...).Select(...).ToList()` | `IEnumerable<T>` throughout | Fluent Query — intentional |

A chain that crosses object responsibility boundaries is a smell. A chain that stays within a single designed abstraction is idiomatic.

## Refactoring

- **Hide Delegate** — introduce a method on the near-side object that encapsulates the navigation and returns the needed result directly.
- **Extract Method** — if the chain appears repeatedly, extract it to a method with a name that communicates intent.
- **Move Method** — if the chain is always traversed for the same purpose, consider whether the method performing the traversal belongs on an intermediate class.

See also: [Law of Demeter Violations](./law-of-demeter-violations), [Inappropriate Intimacy](./inappropriate-intimacy).
