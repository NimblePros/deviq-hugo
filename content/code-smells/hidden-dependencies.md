---
title: Hidden Dependencies Code Smell

date: 2026-03-09

description: Hidden Dependencies is a code smell where a class's required collaborators are not visible in its public interface, making the class's behavior unpredictable from the outside and difficult to test in isolation.

---

Hidden Dependencies is a code smell where the things a class depends on to do its work are not visible through its public interface. Instead of being declared in a constructor or method signature — where callers can see and supply them — dependencies are obtained silently: by reaching into a service locator, calling a static method, accessing a global variable, or constructing collaborators internally. The class has needs it does not declare.

The [Explicit Dependencies Principle](/principles/explicit-dependencies-principle/) states that a class should declare its needs openly so that callers know what it requires and can satisfy those requirements. Hidden Dependencies violate this principle.

## Problems Caused by Hidden Dependencies

### Unpredictable Behavior

A class that secretly depends on global state or a static service may behave differently depending on circumstances the caller cannot see or control. Two calls with the same arguments may produce different results because hidden state has changed between them.

### Difficult Testing

To test a class with hidden dependencies, the test must know about and configure the hidden state — even though nothing in the class's interface reveals it. Tests become brittle because they must reach into global state or static registries. Substituting a test double (mock, stub, fake) for a hidden dependency is often difficult or impossible without modifying the class.

### Tight Coupling to Infrastructure

Hidden dependencies often reach directly into infrastructure: static database connections, in-process caches, static loggers, or global configuration objects. This makes the class impossible to use without those infrastructure components present, even in contexts — such as unit tests or a different deployment environment — where that infrastructure may not be available.

### Violation of the Single Responsibility Principle

A class that is responsible for both its own logic and for locating its own dependencies has taken on an extra responsibility. Finding and constructing collaborators should be the job of the composition root or a factory, not the class itself.

## Example

A class that hides its dependencies:

```csharp
public class OrderService
{
    public void PlaceOrder(Order order)
    {
        // Hidden dependency: static service locator
        var repository = ServiceLocator.Get<IOrderRepository>();

        // Hidden dependency: static logger
        Logger.Instance.Log($"Placing order {order.Id}");

        repository.Save(order);

        // Hidden dependency: static email client
        EmailClient.SendConfirmation(order.CustomerEmail);
    }
}
```

Callers of `OrderService` cannot tell from its constructor or method signature that it depends on a repository, a logger, or an email client. Those dependencies are invisible and uncontrollable from outside.

After making dependencies explicit through the constructor:

```csharp
public class OrderService
{
    private readonly IOrderRepository _repository;
    private readonly ILogger _logger;
    private readonly IEmailClient _emailClient;

    public OrderService(
        IOrderRepository repository,
        ILogger logger,
        IEmailClient emailClient)
    {
        _repository = repository;
        _logger = logger;
        _emailClient = emailClient;
    }

    public void PlaceOrder(Order order)
    {
        _logger.Log($"Placing order {order.Id}");
        _repository.Save(order);
        _emailClient.SendConfirmation(order.CustomerEmail);
    }
}
```

Every dependency is declared in the constructor. Callers supply them. Tests can inject test doubles. The class has no hidden knowledge of where its dependencies come from.

## Identifying Hidden Dependencies

Look for:

- Calls to `ServiceLocator.Get<T>()`, `Container.Resolve<T>()`, or similar locator methods inside class logic.
- Access to static properties or methods that represent infrastructure: `Logger.Instance`, `Database.Connection`, `Config.Global`.
- `new` expressions inside business logic constructing collaborators (other than simple value objects or domain entities).
- Constructors with no parameters on classes that clearly need collaborators to function.

## Common Sources

- The [Service Locator pattern](/design-patterns/service-locator-pattern/) — dependencies are pulled from a central registry inside the class.
- [Static Cling](/antipatterns/static-cling/) — a class calls static methods on another class instead of depending on an interface.
- Ambient context objects — thread-local or process-local global state used to pass context implicitly through the call stack.

## Insidious Hidden Dependencies

Some of the most common hidden dependencies are easy to overlook because they feel like "just using the platform." Steve "Ardalis" Smith identified several of these in [Insidious Dependencies](https://ardalis.com/insidious-dependencies/):

> Every time you instantiate a concrete instance of a class, you're establishing a dependency on that particular implementation.

That observation applies to infrastructure concerns too — not just collaborator classes. Common insidious dependencies include:

- **The file system** — direct calls to `System.IO` that aren't behind an `IFileSystem` abstraction make code hard to test in different environments.
- **Email and notifications** — direct calls to `System.Net.Mail` couple the class to a specific delivery mechanism. An `INotificationService` interface allows substitution.
- **Web services and HTTP** — any call that leaves the process is a dependency. Wrapping `HttpClient` or service calls behind an interface makes them replaceable in tests.
- **`DateTime.Now` and `DateTime.Today`** — reading the system clock directly is "a big time dependency that makes code much more difficult to test." An `IDateTimeProvider` or `IClock` interface with a `SystemClock` implementation allows tests to control time.
- **Configuration** — direct access to config files or environment variables couples the class to its deployment environment. An `IConfiguration` abstraction allows the values to be supplied in any context.
- **`new`** — constructing concrete collaborators with `new` inside business logic hides the dependency just as surely as calling a static method does.

## Refactoring

- **Apply Dependency Injection** — declare dependencies in the constructor and let a composition root or DI container supply them. This is the most direct remedy.
- **Introduce a factory or factory method** — if construction is complex, use a factory to build fully wired objects rather than embedding construction logic inside the class.
- **Replace service locator calls** — identify every call to a static service locator inside the class and replace it with a constructor-injected interface.
- **Abstract infrastructure concerns** — wrap the file system, clock, configuration, and outbound HTTP behind interfaces so they can be substituted in tests without touching the real resources.

## References

- Steve "Ardalis" Smith, [Insidious Dependencies](https://ardalis.com/insidious-dependencies/) (2008)

See also: [Explicit Dependencies Principle](/principles/explicit-dependencies-principle/), [Service Locator pattern](/design-patterns/service-locator-pattern/).
