---
title: Divergent Change Code Smell

date: 2026-03-08

description: Divergent Change is a code smell where a single class is routinely modified for multiple unrelated reasons, indicating that the class has too many responsibilities.

weight: 120
---

Divergent Change occurs when a single class is the target of many different kinds of changes, each driven by a different reason. If you find yourself thinking, "I change this class whenever the database schema changes, and I also change it whenever business rules change, and I also change it whenever the UI format changes," that class is suffering from Divergent Change. One class is changing in many different directions.

Divergent Change is the inverse of [Shotgun Surgery](./shotgun-surgery): Divergent Change means one class changes for many different reasons, while Shotgun Surgery means one reason to change affects many different classes. Both signal that responsibilities have been distributed poorly across the codebase.

## Problems Caused by Divergent Change

### Violation of the Single Responsibility Principle

The [Single Responsibility Principle](/principles/single-responsibility-principle/) states that a class should have one reason to change. A class that changes for multiple reasons is serving multiple masters and has multiple responsibilities, making it harder to understand, test, and evolve.

### Increased Risk with Every Change

When a class is changed for one reason, code written for a different reason is in scope for accidental modification or breakage. A change to the database layer could accidentally introduce a bug in the business logic that lives in the same class.

### Difficult to Test

When a class mixes unrelated concerns, tests must set up the context for all of them — even when testing just one. This makes tests more brittle and harder to write. It also makes it harder to isolate failures to a specific concern.

### Poor [Cohesion](/terms/cohesion/)

A class that serves many purposes has low [cohesion](/terms/cohesion/). Its methods and fields don't all relate to a single concept, making the class harder to name meaningfully and harder to reason about as a whole.

## Example

An `OrderProcessor` class that changes whenever persistence logic, tax rules, or notification formats change:

```csharp
public class OrderProcessor
{
    // Changes whenever the database schema changes
    public void SaveOrder(Order order)
    {
        using var connection = new SqlConnection(_connectionString);
        connection.Open();
        var cmd = new SqlCommand("INSERT INTO Orders (Id, Total) VALUES (@Id, @Total)", connection);
        cmd.Parameters.AddWithValue("@Id", order.Id);
        cmd.Parameters.AddWithValue("@Total", order.Total);
        cmd.ExecuteNonQuery();
    }

    // Changes whenever tax rules change
    public decimal CalculateTax(Order order)
    {
        if (order.ShippingState == "CA") return order.Total * 0.0975m;
        if (order.ShippingState == "NY") return order.Total * 0.08m;
        return order.Total * 0.06m;
    }

    // Changes whenever notification requirements change
    public void SendConfirmationEmail(Order order)
    {
        var message = $"Thank you for your order #{order.Id}. Total: {order.Total:C}";
        _emailService.Send(order.CustomerEmail, "Order Confirmation", message);
    }
}
```

Every distinct concern in this class has its own rate of change and its own reasons to change. A modification to the tax calculation has no business being in the same class as the SQL insert statement.

After separating concerns into focused classes:

```csharp
public class OrderRepository
{
    public void Save(Order order) { /* database logic only */ }
}

public class TaxCalculator
{
    public decimal Calculate(Order order) { /* tax rule logic only */ }
}

public class OrderNotificationService
{
    public void SendConfirmation(Order order) { /* email logic only */ }
}
```

Each class now has one reason to change, and changes to one concern cannot accidentally break another.

## Addressing Divergent Change

- **Extract Class** — identify each distinct reason the class changes and extract the corresponding methods and fields into a dedicated class.
- **Apply the [Single Responsibility Principle](/principles/single-responsibility-principle/)** — ask "what is this class responsible for?" If the answer requires the word "and," there is likely more than one responsibility to separate.
- **Separate layers explicitly** — persistence, business logic, and presentation each change for different reasons. Keeping them in dedicated classes or layers prevents them from interfering with one another.
- **Apply [Domain-Driven Design](/domain-driven-design/)** — group behavior with the data it acts on, organized around domain concepts rather than technical concerns.
