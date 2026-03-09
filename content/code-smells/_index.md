---
title: "Code Smells"
description: "Code smells, or bad smells in code, refer to symptoms of code that may indicate deeper problems."
weight: 120
cascade:
  type: docs
date: 2024-01-14
aliases:
  - /code-smells/code-smells-overview/
  - /antipatterns/code-smells/
params:
  image: /code-smells/images/code-smells.png
---

Code smells, or bad smells in code, refer to symptoms in code that may indicate deeper problems. They're a diagnostic tool used when considering [refactoring](/practices/refactoring/) software to improve its design. Not all code smells should be "fixed" - sometimes code is perfectly acceptable in its current form. Context is important, so what may be inappropriate in one application or part of an application may be appropriate elsewhere.

Each of these smells is demonstrated, and corrective actions described, in the [Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) course on Pluralsight.

## Common Code Smells

### Bloaters

- [Long Method](./long-method)
- [Primitive Obsession](./primitive-obsession-code-smell)
- [Long Parameter List](./long-parameter-list)
- [Data Clumps](./data-clumps)
- [Combinatorial Explosion](./combinatorial-explosion)
- [Oddball Solution](./oddball-solution)
- [Class Doesn't Do Much](./class-doesnt-do-much)
- [Required Setup/Teardown Code](./required-setup-teardown)

### Obfuscators

- [Regions](./regions)
- [Comments](./comments)
- [Poor Names](./poor-names)
- [Vertical Separation](./vertical-separation)
- [Inconsistency](./inconsistency)
- [Obscured Intent](./obscured-intent)
- [Bump Road](./bump-road)

### Object Orientation Abusers

- [Switch Statements](./switch-statements)
- [Temporary Field](./temporary-field)
- [Alternative Class with Different Interfaces](./alternative-class-different-interfaces)
- [Class Depends on Subclass](./class-depends-on-subclass)
- Inappropriate Static / [Static Cling](/antipatterns/static-cling/)

### Change Preventers

- [Divergent Change](./divergent-change)
- [Shotgun Surgery](./shotgun-surgery)
- [Parallel Inheritance Hierarchies](./parallel-inheritance-hierarchies)
- [Inconsistent Abstraction Levels](./inconsistent-abstraction-levels)
- [Conditional Complexity](./conditional-complexity)
- [Poorly Written Tests](./poorly-written-tests)

### Dispensables

- [Lazy Class](./class-doesnt-do-much)
- [Data Class](./data-class)
- [Duplicate Code](./duplicate-code)
- [Dead Code](./dead-code)
- [Speculative Generality](./speculative-generality)

### Couplers

- Feature Envy
- Inappropriate Intimacy
- Law of Demeter Violations
- Indecent Exposure
- Message Chains
- Middle Man
- Tramp Data
- Artificial Coupling
- Hidden Temporal Coupling
- Hidden Dependencies

### Test Smells

- Not Enough Tests
- [DRY](/principles/dont-repeat-yourself/) versus DAMP
- Fragility
- The Liar
- Excessive Setup
- The Giant
- The Mockery
- The Inspector
- Generous Leftovers
- The Local Hero
- The Nitpicker
- The Secret Catcher
- The Loudmouth
- The Greedy Catcher
- The Sequencer
- The Hidden Dependency
- The Enumerator
- The Stranger
- The OS Evangelist
- Success Against All Odds
- The Free Ride
- The One
- The Peeping Tom
- The Slow Poke
- The Contradiction
- Roll the Dice
- Hidden Tests
- Second Class Citizens
- Wait and See
- Inappropriate Test Group
- The Optimist
- The Sleeper
- The Void

## References

[Refactoring for C# Developers](https://www.pluralsight.com/courses/refactoring-csharp-developers) on Pluralsight
