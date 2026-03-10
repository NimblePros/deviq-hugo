---
title: Tramp Data Code Smell

date: 2026-03-09

description: Tramp Data is a code smell where data is passed through a chain of methods solely to reach a distant consumer, indicating that the design does not reflect where the data actually belongs.

weight: 380
---

Tramp Data is a code smell where a piece of data travels through several method calls as a parameter, but intermediate methods neither use nor care about it — they only pass it along to the next method in the chain. The data is a tramp: it keeps moving from place to place without ever finding a home.

The smell indicates a mismatch between where data is introduced and where it is needed. The path it travels through the codebase is a clue that either the data belongs somewhere it is not carried, or the methods passing it belong closer to where the data originates.

## Problems Caused by Tramp Data

### Polluted Method Signatures

Every intermediate method that passes tramp data must include it in its parameter list, even though it has no use for it. This inflates signatures, adds noise to the interface, and forces callers to know about data they do not otherwise care about.

### Misleading Contracts

A method signature is a contract: it declares what the method needs to do its job. Parameters that exist only to be forwarded misrepresent the method's actual requirements, making the code harder to understand.

### Tight Coupling Across Layers

Tramp data creates a dependency chain. If the data type changes — for example, a parameter changes from `string` to a `UserId` value type — every method in the chain must be updated, even those that never interact with the data directly.

### Obscured Design

The presence of tramp data often points to a deeper structural problem: the data belongs to an object that could be passed directly, or the calling class needs more context than is being given to it through its constructor or fields.

## Example

A request ID is introduced at the entry point and passed through three methods that have no use for it:

```csharp
public class OrderPipeline
{
    public void Process(Order order, string requestId)
    {
        ValidateOrder(order, requestId);
    }

    private void ValidateOrder(Order order, string requestId)
    {
        // ...validation logic...
        PersistOrder(order, requestId);
    }

    private void PersistOrder(Order order, string requestId)
    {
        // ...persistence logic...
        PublishEvent(order, requestId);
    }

    private void PublishEvent(Order order, string requestId)
    {
        // Finally uses requestId
        _eventBus.Publish(new OrderProcessed(order.Id, requestId));
    }
}
```

`requestId` is passed through `Process`, `ValidateOrder`, and `PersistOrder` without being used in any of them. It exists solely to reach `PublishEvent`.

One resolution is to hold the shared context in the class itself:

```csharp
public class OrderPipeline
{
    private readonly string _requestId;

    public OrderPipeline(string requestId)
    {
        _requestId = requestId;
    }

    public void Process(Order order)
    {
        ValidateOrder(order);
    }

    private void ValidateOrder(Order order)
    {
        // ...validation logic...
        PersistOrder(order);
    }

    private void PersistOrder(Order order)
    {
        // ...persistence logic...
        PublishEvent(order);
    }

    private void PublishEvent(Order order)
    {
        _eventBus.Publish(new OrderProcessed(order.Id, _requestId));
    }
}
```

The `requestId` is now stored on the instance and accessed directly where needed. The intermediate methods are not polluted with a parameter they do not use.

## Identifying Tramp Data

Look for:

- Parameters that appear in a method signature but are never read or used inside that method.
- Parameters that are passed unchanged from one method to another several levels deep.
- Parameters that are used only in one leaf method deep in a call chain.
- Comments like `// only needed for logging` next to a parameter that is threaded through several layers.

## Refactoring

- **Store context in a field** — if the data is logically part of the object's state for the duration of an operation, store it on the instance.
- **Introduce a parameter object** — if several pieces of data are traveling together, group them into a context object that can be carried as a unit.
- **Introduce method on the owning class** — if the data belongs to a particular class, give that class a method that uses it, eliminating the need to pass it explicitly.
- **Move the consumer closer** — if only one method deep in a chain uses the data, consider whether that method could be restructured to receive the data directly from its true source.

Tramp Data is related to [Long Parameter List](./long-parameter-list) — a parameter list that includes data the method doesn't use is a long list for the wrong reasons.
