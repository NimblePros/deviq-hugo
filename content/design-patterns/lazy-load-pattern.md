---
title: Lazy Load Pattern

date: 2026-03-09

description: The Lazy Load Pattern defers the initialization of an object or resource until it is actually needed, avoiding unnecessary work and improving application startup performance.
---

## What is the Lazy Load Pattern?

The Lazy Load Pattern defers the initialization of an object or resource until the moment it is first accessed, rather than loading it eagerly at construction time. This avoids unnecessary computation, database queries, or allocations when the data may never be needed at all.

Lazy loading is useful when:

- Loading a related object or collection is expensive (e.g., a database round-trip).
- The loaded data is only needed in a subset of code paths.
- Startup performance is more important than the cost of first access.
- Objects are large and memory is constrained.

There are several common approaches to implementing lazy loading:

- **Virtual Proxy** — a lightweight stand-in that looks like the real object but defers its creation until a method is called.
- **Value Holder** — a generic wrapper that holds a factory delegate; the delegate is invoked only when the value is first requested.
- **.NET `Lazy<T>`** — a built-in thread-safe wrapper that initializes its wrapped value on first access.
- **Ghost** — an empty shell loaded from persistence with only its identity; remaining fields are populated on first access.

ORMs such as Entity Framework use virtual proxies (generated subclasses) to provide transparent lazy loading of navigation properties.

## When to Avoid It

Lazy loading is not always beneficial. In web-request contexts it frequently leads to the **N+1 query problem**, where a loop over a collection triggers a separate database round-trip for every element. The [Specification Pattern](/design-patterns/specification-pattern/) and explicit `.Include()` calls (EF Core) are generally preferred in such scenarios because they load related data in a single query.

## C# Example

### Using .NET's Built-in `Lazy<T>`

```csharp
public class CustomerReport
{
    private readonly int _customerId;
    private readonly Lazy<IReadOnlyList<Order>> _orders;

    public CustomerReport(int customerId, IOrderRepository orderRepository)
    {
        _customerId = customerId;
        _orders = new Lazy<IReadOnlyList<Order>>(
            () => orderRepository.GetOrdersForCustomer(customerId));
    }

    public int CustomerId => _customerId;

    // Database call only happens the first time this property is accessed.
    public IReadOnlyList<Order> Orders => _orders.Value;
}
```

### Manual Value Holder

```csharp
public class ProductCatalog
{
    private readonly Func<IReadOnlyList<Category>> _loadCategories;
    private IReadOnlyList<Category>? _categories;

    public ProductCatalog(Func<IReadOnlyList<Category>> loadCategories)
    {
        _loadCategories = loadCategories;
    }

    public IReadOnlyList<Category> Categories =>
        _categories ??= _loadCategories();
}
```

Both approaches ensure the expensive work is performed at most once and only if it is actually required.

## Relationship to Other Patterns

The Lazy Load pattern frequently collaborates with:

- **[Proxy](/design-patterns/proxy-pattern/)** — virtual proxies are a primary implementation mechanism for transparent lazy loading.
- **[Repository](/design-patterns/repository-pattern/)** — repositories commonly use lazy loading to defer loading of child collections.

## Intent

An object that doesn't contain all of the data you need but knows how to get it. [Martin Fowler - Patterns of Enterprise Application Architecture]

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Martin Fowler - [Patterns of Enterprise Application Architecture](https://martinfowler.com/books/eaa.html)

Ardalis - [Avoid Lazy Loading Entities in ASP.NET Applications](https://ardalis.com/avoid-lazy-loading-entities-in-asp-net-applications/)
