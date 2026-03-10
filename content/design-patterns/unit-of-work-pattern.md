---
title: Unit of Work Pattern

date: 2026-03-09

description: The Unit of Work Pattern maintains a list of objects affected by a business transaction and coordinates the writing out of changes as a single atomic operation. Learn how to implement it in C# with Entity Framework Core.
weight: 380
---

## What is the Unit of Work Pattern?

The Unit of Work Pattern tracks all changes made to domain objects during a business transaction — new objects, modified objects, and deleted objects — and coordinates persisting those changes to the database as a single atomic operation. This ensures that related changes either all succeed or all fail together, preserving data consistency.

Without a Unit of Work, you would need to call the database once per repository operation. A Unit of Work batches these writes, reducing round-trips and allowing the work to be wrapped in a transaction.

Martin Fowler describes the pattern as:

> *"Maintains a list of objects affected by a business transaction and coordinates the writing out of changes and the resolution of concurrency problems."*

## Relationship to the Repository Pattern

The Unit of Work and [Repository](/design-patterns/repository-pattern/) patterns are almost always used together:

- **Repositories** provide a collection-like abstraction for querying and staging changes to domain objects.
- The **Unit of Work** provides the `Save()` (or `Commit()`) operation that flushes all staged changes to the data store at once.

Entity Framework Core's `DbContext` is itself an implementation of both patterns: `DbSet<T>` implements Repository and `SaveChangesAsync()` implements Unit of Work. **NOTE:** This doesn't mean that you don't need your own abstraction for *Repository* or *Unit of Work* - the benefit of these patterns is in the abstraction, not a single implementation.

## C# Example

### Interfaces

```csharp
public interface IUnitOfWork
{
    IRepository<Order> Orders { get; }
    IRepository<Customer> Customers { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
```

### Implementation with Entity Framework Core

```csharp
public class AppUnitOfWork : IUnitOfWork
{
    private readonly AppDbContext _context;

    public AppUnitOfWork(AppDbContext context)
    {
        _context = context;
        Orders = new EfRepository<Order>(context);
        Customers = new EfRepository<Customer>(context);
    }

    public IRepository<Order> Orders { get; }
    public IRepository<Customer> Customers { get; }

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) =>
        _context.SaveChangesAsync(cancellationToken);
}
```

### Repository used by the Unit of Work

```csharp
public class EfRepository<T> : IRepository<T> where T : class
{
    private readonly AppDbContext _context;

    public EfRepository(AppDbContext context) => _context = context;

    public async Task<T?> GetByIdAsync(int id) =>
        await _context.Set<T>().FindAsync(id);

    public void Add(T entity) => _context.Set<T>().Add(entity);

    public void Remove(T entity) => _context.Set<T>().Remove(entity);
}
```

> **Note:** `Add` and `Remove` do not call `SaveChanges`. All changes are staged in the `DbContext` change tracker and only written to the database when `IUnitOfWork.SaveChangesAsync()` is called.

### Usage in an Application Service

```csharp
public class PlaceOrderService
{
    private readonly IUnitOfWork _uow;

    public PlaceOrderService(IUnitOfWork uow) => _uow = uow;

    public async Task PlaceOrderAsync(int customerId, IReadOnlyList<OrderLine> lines)
    {
        var customer = await _uow.Customers.GetByIdAsync(customerId)
            ?? throw new InvalidOperationException("Customer not found.");

        var order = Order.Place(customer, lines);
        _uow.Orders.Add(order);

        // All staged changes are written in a single transaction.
        await _uow.SaveChangesAsync();
    }
}
```

Multiple repository operations are staged separately and then committed atomically in one `SaveChangesAsync` call.

## When to Use It

- When multiple repositories must be updated together and partial success is unacceptable.
- When you want to batch writes to improve performance.
- When you need to manage concurrency or track the full set of changes for auditing.

## Intent

Maintains a list of objects affected by a business transaction and coordinates the writing out of changes and the resolution of concurrency problems. [Martin Fowler - Patterns of Enterprise Application Architecture]

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Martin Fowler - [Patterns of Enterprise Application Architecture](https://martinfowler.com/books/eaa.html)
