---
title: Service Locator Pattern

date: 2026-03-09

description: The Service Locator pattern provides a central registry from which objects can retrieve their dependencies at runtime. While it solves some dependency management problems, it is widely considered an antipattern due to serious impacts on testability, maintainability, and code clarity.
weight: 320
---

## What is the Service Locator Pattern?

The Service Locator pattern provides a central registry — the *locator* — from which objects request their dependencies at runtime instead of having those dependencies supplied explicitly. A class that needs an `IOrderRepository` calls `ServiceLocator.Get<IOrderRepository>()` rather than declaring it as a constructor parameter.

```csharp
// Service Locator approach — generally avoid this
public class OrderService
{
    public void PlaceOrder(Order order)
    {
        // Dependency is hidden: callers can't see it, and tests can't easily replace it.
        var repository = ServiceLocator.Get<IOrderRepository>();
        repository.Add(order);
    }
}
```

At first glance the pattern appears to solve the problem of wiring dependencies through an application, and it was popular in earlier .NET and Java frameworks. However, experience has shown it consistently causes more problems than it solves.

## Why Service Locator Is Considered an Antipattern

### 1. Hidden Dependencies

The most significant problem: dependencies become invisible. A constructor with no parameters looks like it needs nothing, but the class may depend on dozens of services pulled from the locator. This violates the [Explicit Dependencies Principle](/principles/explicit-dependencies-principle/) and leads to the [Hidden Dependencies](/code-smells/hidden-dependencies/) code smell. Callers cannot know what a class needs without reading its full implementation.

### 2. Testability

Unit testing requires the ability to substitute real dependencies with test doubles (mocks, stubs, fakes). With the Service Locator, tests must configure the global locator registry before each test and tear it down afterwards — or tests will interfere with each other. This introduces hidden test-order coupling and significantly increases test setup complexity.

```csharp
// Test setup becomes brittle global state management
ServiceLocator.Register<IOrderRepository>(() => new FakeOrderRepository());
// ... run test ...
ServiceLocator.Clear(); // must remember to clean up
```

With constructor injection, a test simply passes a fake directly:

```csharp
var service = new OrderService(new FakeOrderRepository()); // trivially testable
```

### 3. Runtime Failures Instead of Compile-Time Errors

When a dependency is missing from the locator the failure occurs at runtime — typically deep inside a method call. With constructor injection the DI container fails loudly at startup and the compiler enforces that all required parameters are provided.

### 4. Static Cling

Service Locators are almost always accessed via a static method or property, coupling all callers to a specific global. This exhibits every problem of the [Static Cling antipattern](/antipatterns/static-cling/): difficulty mocking, hidden coupling, and thread-safety concerns.

## The Preferred Alternative: Dependency Injection

The solution to service locator's problems is to declare dependencies explicitly and have them supplied by a [Dependency Injection](/practices/dependency-injection/) container at the composition root of the application:

```csharp
// Preferred: constructor injection
public class OrderService
{
    private readonly IOrderRepository _repository;

    public OrderService(IOrderRepository repository)
    {
        _repository = repository;
    }

    public void PlaceOrder(Order order)
    {
        _repository.Add(order);
    }
}
```

The constructor declares everything the class needs. Tests can supply any implementation. The DI container wires the real implementation in production. The class itself has no knowledge of how its dependencies are created or resolved.

## When Service Locator Appears Legitimate

There is one narrow context where a form of service location is unavoidable: framework extension points that are called by the framework before the DI container is fully constructed, such as `IHostedService` factory delegates or certain plugin architectures. Even then, this should be confined to the composition root and never used inside domain or application logic.

Mark Seemann (author of *Dependency Injection Principles, Practices, and Patterns*) articulates the distinction clearly:

> *"A DI container used as a Service Locator is an anti-pattern. A DI container used as a composition root is fine."*

## Intent

Provide a centralized registry that supplies dependencies to requesting objects at runtime. [Martin Fowler - Patterns of Enterprise Application Architecture]

## See Also

- [Service Locator Antipattern](/antipatterns/service-locator/) — a detailed examination of why the pattern is problematic in practice.
- [Dependency Injection](/practices/dependency-injection/)
- [Explicit Dependencies Principle](/principles/explicit-dependencies-principle/)
- [Static Cling Antipattern](/antipatterns/static-cling/)
- [Hidden Dependencies Code Smell](/code-smells/hidden-dependencies/)

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Mark Seemann - [Service Locator is an Anti-Pattern](https://blog.ploeh.dk/2010/02/03/ServiceLocatorisanAnti-Pattern/)

Ardalis - [What's Wrong with the Service Locator](https://ardalis.com/whats-wrong-with-the-service-locator)
