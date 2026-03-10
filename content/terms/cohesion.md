---
title: Cohesion

date: 2026-03-08

description: Cohesion refers to how closely related and focused the responsibilities of a single class, module, or function are. High cohesion is desirable and signals that a unit of code has a clear, singular purpose.

weight: 40
---

Cohesion refers to how closely related the contents of a class, module, or function are to one another. A highly cohesive class has methods and fields that all contribute to a single, well-defined purpose. A class with low cohesion has methods and fields that serve unrelated purposes, making it harder to name, understand, test, and change.

Cohesion is closely paired with **coupling** — the degree to which one class depends on another. The goal in well-designed software is *high cohesion* and *low coupling*: each unit does one thing well, and units depend on each other as little as possible.

## High Cohesion vs. Low Cohesion

**High cohesion** means everything inside a class belongs there. The class has a clear identity, a meaningful name, and every method and field relates to that identity. A `TaxCalculator` that only calculates tax is highly cohesive.

**Low cohesion** means the class is doing several unrelated things. An `OrderManager` that handles persistence, tax calculation, email notification, and logging has low cohesion — its contents are scattered across unrelated concerns, and any change to any one of them risks affecting the others.

## Why Cohesion Matters

### Understandability

A highly cohesive class is easier to understand because everything in it contributes to the same idea. A developer can read the class name, form an accurate mental model, and predict what the class does and does not do.

### Testability

Testing a highly cohesive class is easier because the class has a narrow surface area. Tests don't need to set up infrastructure or context for unrelated concerns.

### Changeability

When a concern changes, a highly cohesive class is likely to be the only place that needs updating. Low cohesion means that a change to one responsibility risks breaking code written for a different responsibility that happens to live in the same class — a symptom of the [Divergent Change](../code-smells/divergent-change) code smell.

### Reusability

Highly cohesive classes are more reusable because they represent a well-bounded concept. A `TaxCalculator` can be reused anywhere tax is calculated; an `OrderManager` that bakes in tax calculation alongside unrelated concerns cannot be cleanly reused.

## Cohesion and the Single Responsibility Principle

The [Single Responsibility Principle](/principles/single-responsibility-principle/) is the design principle most directly associated with cohesion. SRP states that a class should have only one reason to change — which is another way of saying it should be highly cohesive around a single concern. Low cohesion is often the first sign that a class is violating SRP.

## Cohesion and Code Smells

Several code smells directly reflect low cohesion:

- **[Divergent Change](../code-smells/divergent-change)** — a class that changes for many different reasons usually has multiple unrelated responsibilities.
- **[Long Method](../code-smells/long-method)** — a method that does too many things at different levels of abstraction has low cohesion.
- **[Inconsistent Abstraction Levels](../code-smells/inconsistent-abstraction-levels)** — mixing high-level policy with low-level detail in the same method is a cohesion failure.

## Improving Cohesion

The primary refactoring move is **Extract Class**: identify a cluster of fields and methods within a low-cohesion class that belong together under a different name, and move them into a new, focused class. **Extract Method** applies the same principle at the function level.

## References

- [Single Responsibility Principle](/principles/single-responsibility-principle/)
- [Divergent Change Code Smell](../code-smells/divergent-change)
- *Structured Design* — Larry Constantine and Ed Yourdon (1979). Introduced the formal definitions of cohesion and coupling that remain the foundation of modern software design vocabulary.
- *Principles, Patterns, and Practices of Agile Software Development* — Robert C. Martin (2002). Discusses cohesion in the context of the Single Responsibility Principle and package-level design principles (REP, CCP, CRP).
- *Clean Code: A Handbook of Agile Software Craftsmanship* — Robert C. Martin (2008). Chapter 10 ("Classes") covers class cohesion directly, with guidance on keeping classes focused and splitting them when cohesion degrades.
- *Refactoring: Improving the Design of Existing Code* — Martin Fowler (1999, 2nd ed. 2018). The Extract Class and Extract Method refactorings are the primary tools for restoring cohesion to low-cohesion classes and methods.
- *A Philosophy of Software Design* — John Ousterhout (2018). Discusses deep vs. shallow modules and the relationship between a module's interface and its implementation — a framing of cohesion at the module level.
