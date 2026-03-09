---
title: Make Illegal States Unrepresentable

date: 2026-03-09

description: Make Illegal States Unrepresentable is a design principle that uses the type system to ensure invalid combinations of data cannot be constructed, eliminating whole classes of runtime errors at compile time.

---

Make Illegal States Unrepresentable is a design principle that guides you to model your domain such that invalid or nonsensical states are impossible to express in code. Rather than relying on runtime checks, validation methods, or documentation to prevent invalid states, the goal is to use the type system itself as the enforcement mechanism. If the compiler rejects invalid states, they cannot occur at runtime.

The phrase is commonly attributed to Yaron Minsky, who used it in the context of OCaml's type system, but the idea applies in any language that supports expressive types — including C#, F#, TypeScript, and Kotlin.

## The Problem: Representing Invalid States

When a class uses primitive types or loosely typed fields to hold data that has specific constraints and relationships, it becomes possible to construct objects that are technically valid in the type system but meaningless (or harmful) in the domain.

Consider an email notification that can be sent to a specific address or to all users, but not both:

```csharp
public class EmailNotification
{
    public string? RecipientEmail { get; set; }
    public bool SendToAll { get; set; }
}
```

This class allows `RecipientEmail = null` and `SendToAll = false` simultaneously — a state where no recipient is specified at all. It also allows both to be set at the same time. There are four possible states, but only two are valid. Every method that consumes this class must guard against the two illegal states.

## The Solution: Encode the Constraint in the Type

By redesigning the type so that only valid states can be expressed, the guards become unnecessary:

```csharp
public abstract class NotificationTarget
{
    public sealed class AllUsers : NotificationTarget { }

    public sealed class SpecificRecipient : NotificationTarget
    {
        public EmailAddress Email { get; }

        public SpecificRecipient(EmailAddress email)
        {
            Email = email;
        }
    }
}
```

Now a `NotificationTarget` is either `AllUsers` or `SpecificRecipient` — nothing else. The "no recipient and not all users" state and the "both populated simultaneously" state do not exist. Any method that accepts a `NotificationTarget` does not need to validate it; it only needs to handle the two cases the type system allows.

## Discriminated Unions and Pattern Matching

This pattern maps naturally to discriminated unions (also called sum types), which are a first-class feature in F# and are approximated in C# through class hierarchies, records, or (as of C# 9+) pattern-matched switch expressions:

```csharp
public string Describe(NotificationTarget target) => target switch
{
    NotificationTarget.AllUsers => "Sending to all users",
    NotificationTarget.SpecificRecipient r => $"Sending to {r.Email}",
    _ => throw new UnreachableException()
};
```

The compiler forces handling of every case. There is no default that silently swallows an unhandled state.

## Making Transitions Explicit

Beyond data shapes, the principle also applies to state machines and lifecycle objects. When an entity moves through states, illegal transitions should be inexpressible rather than merely documented:

```csharp
// Before: status is a string — any value is possible at any time
public class Order
{
    public string Status { get; set; } = "Pending";
    public DateTime? ShippedAt { get; set; }
    public string? TrackingNumber { get; set; }
}
```

A `ShippedAt` date and `TrackingNumber` should only exist once the order is shipped, but nothing in the type prevents them from being set on a pending order (or absent on a shipped one). After encoding the state transitions:

```csharp
public abstract class OrderStatus
{
    public sealed class Pending : OrderStatus { }

    public sealed class Shipped : OrderStatus
    {
        public DateTime ShippedAt { get; }
        public string TrackingNumber { get; }

        public Shipped(DateTime shippedAt, string trackingNumber)
        {
            ShippedAt = shippedAt;
            TrackingNumber = trackingNumber;
        }
    }

    public sealed class Cancelled : OrderStatus
    {
        public string Reason { get; }
        public Cancelled(string reason) => Reason = reason;
    }
}
```

A `Shipped` status *must* have a shipping date and tracking number — they are required by the constructor. A `Pending` status *cannot* have them — the type doesn't have those fields. The compiler enforces the constraint.

## Value Objects and Validated Types

At the field level, the same principle motivates [value objects](/domain-driven-design/value-object/): a raw `string` can hold anything, but an `EmailAddress` type can only be constructed with a valid email. This is the basis of [Parse, Don't Validate](/principles/parse-dont-validate/) — parse at the boundary into a type that cannot represent invalid values, and no further validation is needed downstream.

```csharp
// Any string can be assigned — no constraint
public string CustomerEmail { get; set; }

// Only a valid email can be assigned — constraint is in the type
public EmailAddress CustomerEmail { get; }
```

## Benefits

- **Fewer runtime errors** — states that cannot be represented cannot cause bugs.
- **Reduced defensive coding** — methods that receive well-typed values do not need to guard against impossible inputs.
- **Self-documenting code** — the type itself communicates the valid states. There is no need to read documentation or comments to understand what combinations are legal.
- **Compiler assistance** — exhaustive switch expressions and pattern matching can ensure every valid case is handled.
- **Easier refactoring** — the type is the single source of truth for what is valid. Changes to the domain model produce compiler errors everywhere the old shape was assumed, rather than silent runtime bugs.

## Relationship to Other Principles

- **[Parse, Don't Validate](/principles/parse-dont-validate/)** — parsing raw input into a well-typed value is the primary mechanism for establishing the invariants this principle calls for.
- **[Encapsulation](/principles/encapsulation/)** — private constructors and controlled factory methods prevent invalid types from being constructed outside the class.
- **[Tell, Don't Ask](/principles/tell-dont-ask/)** — when illegal states are unrepresentable, callers do not need to query a flag or property to decide whether an object is in a usable state.
- **[Primitive Obsession](/code-smells/primitive-obsession-code-smell/)** — using primitive types (`string`, `int`, `bool`) for domain concepts with constraints is the code smell that this principle directly addresses.
- **[Fail Fast](/principles/fail-fast/)** — when a type cannot be created in an invalid state, failure happens at construction time rather than at an unpredictable later point.

## References

- Yaron Minsky, [Effective ML](https://x.com/yminsky/status/1202015088021053441) — the phrase "make illegal states unrepresentable" originates from his work on OCaml.
- Alexis King, [Parse, Don't Validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) (2019) — extends the idea into a parsing-first design strategy.
