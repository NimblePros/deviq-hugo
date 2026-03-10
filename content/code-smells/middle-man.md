---
title: Middle Man Code Smell

date: 2026-03-09

description: Middle Man is a code smell where a class does little work of its own and mostly delegates to another class, making it an unnecessary layer of indirection.

weight: 250
---

Middle Man is a code smell where a class has become a pass-through layer that adds no value of its own. Most of its methods do nothing but forward calls to another class or object. It is a middleman in the literal sense: an intermediary who takes messages and passes them along without contributing anything.

Some delegation is appropriate — it supports encapsulation and hides details from callers. The smell arises when the delegation is so complete that the class has no logic of its own. It has become a redundant layer between the caller and the class that does the actual work.

## Problems Caused by Middle Man

### Unnecessary Indirection

A class that only delegates forces callers to go through an extra layer without receiving any benefit in return. The chain caller → middleman → real worker is more complex than caller → worker when the middleman adds nothing.

### Dead Abstraction

A class exists to capture a concept and give it a name. A pure middleman doesn't represent a meaningful concept — it exists only because it was created and never filled in. This creates noise: developers reading the code encounter the class, expect it to have behavior, and discover it has none.

### Maintenance Burden

Every time the delegated class adds a method that callers need, the middleman must be updated to add a corresponding forwarding method. This creates busywork and increases the chance of the middleman falling out of sync with the class it delegates to.

## Example

A `CustomerService` that does nothing but forward to a `CustomerRepository`:

```csharp
public class CustomerService
{
    private readonly CustomerRepository _repository;

    public CustomerService(CustomerRepository repository)
    {
        _repository = repository;
    }

    public Customer GetById(int id) => _repository.GetById(id);
    public void Save(Customer customer) => _repository.Save(customer);
    public void Delete(int id) => _repository.Delete(id);
    public List<Customer> GetAll() => _repository.GetAll();
}
```

Every method on `CustomerService` is a one-line forward to `_repository`. There is no transformation, no validation, no business logic — only delegation.

If callers need the repository, they can depend on it directly (or on an interface it implements):

```csharp
public interface ICustomerRepository
{
    Customer GetById(int id);
    void Save(Customer customer);
    void Delete(int id);
    IReadOnlyList<Customer> GetAll();
}
```

When `CustomerService` genuinely adds behavior — validation, authorization checks, event publishing — it earns its place and is no longer a Middle Man.

## When Delegation Is Appropriate

Not all delegation is a problem. Delegation is healthy when:

- A class **adds behavior** to the delegated calls (validation, caching, logging, orchestration).
- Delegation is part of a **design pattern** — [Decorator](/design-patterns/decorator-pattern/), [Proxy](/design-patterns/proxy-pattern/), [Facade](/design-patterns/facade-pattern/), or [Adapter](/design-patterns/adapter-pattern/) all use delegation intentionally.
- A class provides a **stable interface** that hides an unstable or complex collaborator.
- A class **coordinates** multiple collaborators, even if individual method implementations are simple.

The distinction is whether the class adds value or merely relays messages. A Facade that wraps a complex subsystem does add value — it simplifies a complex interface. A Middle Man that wraps a simple interface and adds nothing does not.

## Identifying Middle Man

Look for:

- Classes where most (or all) methods are single-line forwards to another class.
- A class where every public method has a direct counterpart on a private field.
- A class that grew as a wrapper and was never given its own logic.

## Refactoring

- **Remove Middle Man** — have callers depend on the actual worker class directly. If the middleman exposes an interface, have the worker implement that interface instead.
- **Inline Method** — inline the forwarding methods into their callers one at a time if the middleman is used in few places.
- **Replace Delegation with Inheritance** — occasionally a middleman is better expressed as a subclass of the class it delegates to, though this should be used carefully and only when the relationship genuinely is "is-a."
