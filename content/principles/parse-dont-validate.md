---
title: Parse, Don't Validate

date: 2026-03-09

description: Parse, Don't Validate is a design principle that encourages converting unstructured or unverified input into a structured type that makes illegal states unrepresentable, rather than repeatedly validating raw data at every point of use.

weight: 160
---

Parse, Don't Validate is a principle that shifts the responsibility for correctness from scattered validation checks to type construction. Instead of accepting raw input and then checking it every time you use it, you parse the raw input once — at the boundary — and produce a typed value that is guaranteed to be valid by construction. After the parse succeeds, no further validation is needed because the type itself cannot represent an invalid state.

The principle was articulated by Alexis King in the essay [Parse, Don't Validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) (2019):

> Parsing is just validation with a return value — and that return value proves you did the work.

The key insight is that validation *discards* all proof of work: it returns a boolean or throws an exception, but leaves the data in its original untyped form. Parsing *preserves* the proof by returning a new type. That type carries the guarantee that the data is valid, so callers never need to re-check.

## The Problem with Validate-Everywhere

When raw data is validated at the point of use rather than at the boundary, several problems emerge:

- Validation logic is **duplicated** across the codebase, each implementation a potential source of drift or bugs.
- Methods that accept raw types must **defensively re-validate** regardless of whether the caller already did so.
- The type system provides **no help** — a `string` that has been validated as an email address is indistinguishable from one that hasn't, so you can never be certain which methods received validated data.
- Validation can be **forgotten** — there is nothing stopping code from bypassing the check, especially as the codebase grows and the path from input to use becomes longer.

## Parsing as a Solution

A parser converts an unverified input into a typed value that can only exist if it is valid. The resulting type is evidence of validation — you cannot hold a value of that type without having parsed it:

```csharp
public class EmailAddress
{
    public string Value { get; }

    private EmailAddress(string value)
    {
        Value = value;
    }

    public static EmailAddress Parse(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw) || !raw.Contains('@'))
            throw new ArgumentException($"'{raw}' is not a valid email address.", nameof(raw));

        return new EmailAddress(raw.Trim().ToLowerInvariant());
    }

    public static bool TryParse(string raw, out EmailAddress? result)
    {
        if (!string.IsNullOrWhiteSpace(raw) && raw.Contains('@'))
        {
            result = new EmailAddress(raw.Trim().ToLowerInvariant());
            return true;
        }
        result = null;
        return false;
    }

    public override string ToString() => Value;
}
```

Any method that accepts an `EmailAddress` receives proof that the value was validated. The validation occurs once — at the `Parse` call — and is never repeated:

```csharp
// Before: raw string, validated (or not) at the point of use
public void SendWelcomeEmail(string email)
{
    if (string.IsNullOrWhiteSpace(email) || !email.Contains('@'))
        throw new ArgumentException("Invalid email.");

    _mailer.Send(email, "Welcome!");
}

// After: EmailAddress carries proof of validity — no guard needed
public void SendWelcomeEmail(EmailAddress email)
{
    _mailer.Send(email.Value, "Welcome!");
}
```

## Making Illegal States Unrepresentable

The broader goal of Parse, Don't Validate is to design types so that values that should not exist *cannot* exist. This is often described as making illegal states unrepresentable.

Consider an order that can only be shipped if it has at least one line item and a confirmed payment:

```csharp
// Any order can be "shipped" — nothing prevents invalid states
public class Order
{
    public List<OrderLine> Lines { get; set; } = new();
    public bool IsPaid { get; set; }
    public string Status { get; set; } = "Pending";
}

public void Ship(Order order)
{
    if (!order.IsPaid || !order.Lines.Any())
        throw new InvalidOperationException("Order cannot be shipped.");

    order.Status = "Shipped";
}
```

After parsing at the point where an order becomes shippable, the method no longer needs to validate:

```csharp
public class ShippableOrder
{
    public IReadOnlyList<OrderLine> Lines { get; }
    public PaymentConfirmation Payment { get; }

    private ShippableOrder(IReadOnlyList<OrderLine> lines, PaymentConfirmation payment)
    {
        Lines = lines;
        Payment = payment;
    }

    public static ShippableOrder Parse(Order order)
    {
        if (!order.Lines.Any())
            throw new InvalidOperationException("Cannot ship an order with no items.");
        if (order.Payment is null)
            throw new InvalidOperationException("Cannot ship an unpaid order.");

        return new ShippableOrder(order.Lines, order.Payment);
    }
}

public void Ship(ShippableOrder order)
{
    // No guards needed — ShippableOrder cannot exist in an invalid state
    _shipper.Dispatch(order);
}
```

## Parse at the Boundary

The principle works best when applied at system boundaries — the points where unstructured data enters the system:

- **HTTP request deserialization** — parse incoming JSON or form data into validated domain types before routing to handlers.
- **Command-line or config parsing** — convert raw strings into typed configuration objects at startup.
- **Database reads** — map raw rows into domain objects that enforce invariants.
- **Event consumption** — deserialize incoming events into verified value types before handing them to domain logic.

Once past the boundary, downstream code can trust the types it receives without defensive re-checking.

## Relationship to Other Principles

Parse, Don't Validate is closely related to several other principles:

- **[Encapsulation](/principles/encapsulation/)** — validity is enforced by the type, not by external checks.
- **[Tell, Don't Ask](/principles/tell-dont-ask/)** — asking a raw value whether it is valid, then acting on the answer, is exactly the validate-everywhere pattern this principle replaces.
- **[Explicit Dependencies Principle](/principles/explicit-dependencies-principle/)** — types that carry guarantees make the assumptions of a method explicit in its signature.
- **[Fail Fast](/principles/fail-fast/)** — parsing at the boundary ensures invalid data is rejected as early as possible.
- **[Make Illegal States Unrepresentable](/principles/make-illegal-states-unrepresentable/)** — the broader principle that Parse, Don't Validate serves: design types so that invalid values cannot be constructed.
- **[Primitive Obsession](/code-smells/primitive-obsession-code-smell/)** — using `string`, `int`, or `bool` for domain concepts that have meaning and constraints is the root cause that Parse, Don't Validate addresses.

## References

- Alexis King, [Parse, Don't Validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) (2019) — the original essay articulating the principle.
- Steve Smith (Ardalis), [Parse Don't Validate](https://www.youtube.com/watch?v=KQVy0CaB7ds) — a video walkthrough of the principle with C# examples.
