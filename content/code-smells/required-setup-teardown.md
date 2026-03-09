---
title: Required Setup/Teardown Code Smell

date: 2026-03-08

description: The Required Setup/Teardown code smell occurs when callers must remember to execute mandatory setup or cleanup code before and after using a class, rather than having that lifecycle managed automatically.

---

The Required Setup/Teardown code smell occurs when callers must manually execute mandatory setup or cleanup code before and after using a particular class or method. Instead of the class managing its own lifecycle, the responsibility is pushed onto the caller. The result is that correct usage depends on convention and memory rather than structure, making it easy to introduce bugs by simply forgetting a step.

This smell often appears in classes that manage resources (database connections, file handles, locks), classes that must be initialized before use, or test helpers that require explicit reset between runs. It is a sign that the class is not fully encapsulating its own behavior.

## Problems Caused by Required Setup/Teardown Code

### Easy to Forget

When setup or teardown is mandatory but optional to write, it *will* be forgotten. Missing teardown can cause resource leaks, corrupted state, or flaky tests. Missing setup can cause cryptic errors that are far from the root cause. These bugs can be difficult to reproduce and trace.

### Coupling Callers to Implementation Details

When every caller must know the correct initialization sequence, changes to that sequence ripple through every call site. The class's internal requirements become part of the public contract in a way that is difficult to communicate and enforce.

### Reduced Encapsulation

A core principle of object-oriented design is that a class owns its own state and behavior. When callers must reach in to set up or tear down that state, [encapsulation](/principles/encapsulation/) is broken. The class is no longer a self-contained unit.

### Brittle Tests

Test code is especially vulnerable to this smell. Test fixtures that require careful setup and teardown in every test method tend to become fragile. A single forgotten reset leaves state leaking between tests, causing failures that are order-dependent and hard to diagnose.

## Example

Consider a service that wraps a database connection but requires callers to open and close it explicitly:

```csharp
public class ReportService
{
    private SqlConnection _connection;

    public void Initialize(string connectionString)
    {
        _connection = new SqlConnection(connectionString);
        _connection.Open();
    }

    public Report GetReport(int id)
    {
        // uses _connection
    }

    public void Shutdown()
    {
        _connection?.Close();
        _connection?.Dispose();
    }
}

// Caller
var service = new ReportService();
service.Initialize(connectionString); // easy to forget
var report = service.GetReport(42);
service.Shutdown();                   // easy to forget
```

If `Initialize` or `Shutdown` is omitted, the service either fails with a null reference or leaks a connection. The caller must know — and remember — the required ceremony.

A better design moves connection management inside the class's constructor, a factory method, or a `using`-compatible `IDisposable` pattern:

```csharp
public class ReportService : IDisposable
{
    private readonly SqlConnection _connection;

    public ReportService(string connectionString)
    {
        _connection = new SqlConnection(connectionString);
        _connection.Open();
    }

    public Report GetReport(int id)
    {
        // uses _connection
    }

    public void Dispose()
    {
        _connection?.Dispose();
    }
}

// Caller
using var service = new ReportService(connectionString);
var report = service.GetReport(42);
// Dispose is called automatically at end of using block
```

The lifecycle is now managed by the class and enforced by the language runtime. The caller cannot forget because there is nothing to remember.

## Addressing Required Setup/Teardown Code

Several design techniques eliminate this smell:

### Constructor Initialization

Move setup into the constructor. If a class cannot function without a certain initialization step, that step should happen during construction. A fully initialized object is always ready to use.

### IDisposable / using

For teardown involving resource release, implement `IDisposable` (or its equivalent in your language) and use language-level `using` / `try-finally` constructs to guarantee cleanup. The runtime enforces teardown rather than relying on callers.

### Factory Methods

When construction is complex, use a [factory method](/design-patterns/factory-method/) or [builder pattern](/design-patterns/builder/) that produces a fully ready object. The factory encapsulates the ceremony; callers receive an object that is already in a valid state.

### RAII (Resource Acquisition Is Initialization)

In languages like C++, the RAII idiom ties resource acquisition to object construction and release to destruction, so the object's lifetime controls resource lifetime automatically.

### Template Method / Hooks

For test setup and teardown, testing frameworks provide lifecycle hooks (`[SetUp]` / `[TearDown]` in NUnit, `BeforeEach` / `AfterEach` in Jest) that guarantee execution order. Centralizing test initialization in these hooks rather than in each test method reduces duplication and eliminates the risk of forgetting.

## Identifying Required Setup/Teardown Code

Look for:

- Classes with methods named `Initialize`, `Open`, `Start`, `Setup`, `Close`, `Reset`, or `Shutdown` that must be called by the caller.
- Documentation or comments warning callers to call a specific method before or after use.
- Tests that fail intermittently due to shared state not being reset between runs.
- Repeated boilerplate at the top or bottom of methods that use a particular class.

## References

- [Refactoring: Improving the Design of Existing Code](https://martinfowler.com/books/refactoring.html) by Martin Fowler
- [Encapsulation](/principles/encapsulation/)
- [Factory Method Pattern](/design-patterns/factory-method/)
