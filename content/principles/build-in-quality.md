---
title: "Build in Quality: A Lean Software Development Principle"
date: 2026-10-02
description: "Build in Quality is a Lean Software Development principle that says quality should be built into software as it's written, rather than inspected in afterward."
params:
  image: /principles/images/build-in-quality.png
weight: 25
---

![Build in Quality](./images/build-in-quality.png)

Build in Quality is one of the seven principles of [Lean Software Development](/principles/#lean-software-development). (The Poppendiecks' first book called it *Build Integrity In*.) The principle states that quality should be built into a product as it is created, rather than inspected in at the end. A process that relies on finding defects after the fact will always be slower and more expensive than one that prevents them from occurring in the first place.

## Inspection Doesn't Create Quality

In a traditional, [waterfall](/antipatterns/waterfall/) process, testing is a phase that happens after development is "done." Defects found at that point must be routed back to developers who have since moved on to other work, rediscovered, fixed, and re-tested. The longer a defect lives, the more it costs to fix, and the more other code has been built on top of it.

Lean thinking borrows the idea of *jidoka* from Toyota: when a problem is detected, stop the line and fix it immediately. In software, the equivalent is a team that treats a broken build or a failing test as the highest priority, rather than something to be dealt with later.

## Building Quality In

Many agile and extreme programming practices exist specifically to build quality in:

- [Test-Driven Development](/practices/test-driven-development/) defines expected behavior before code is written, so code is verified the moment it exists.
- [Continuous Integration](/practices/continuous-integration/) merges and verifies every change frequently, so integration problems surface within minutes.
- [Automated Tests](/testing/automated-tests/) provide a fast, repeatable safety net that makes change safe.
- [Pair Programming](/practices/pair-programming/) and code review catch problems while the context is still fresh.
- [Refactoring](/practices/refactoring/) keeps the design clean so that quality doesn't erode over time.
- [Fail Fast](/principles/fail-fast/) ensures problems are detected as close as possible to their cause.

## Two Kinds of Integrity

The Poppendiecks describe two kinds of integrity:

- **Perceived integrity**: the product feels coherent and does what its users expect. It is easy to use and solves their problems well.
- **Conceptual integrity**: the system's internal concepts work together as a smooth, cohesive whole. Its architecture is consistent, and it is easy to maintain and extend.

Both are easier to achieve when quality is a continuous concern of the whole team, rather than the responsibility of a separate group at the end of the process.

## Quality and Speed

It is tempting to believe that skipping tests or cutting corners will help a team go faster. In the short term that can be true, but the resulting [technical debt](/terms/technical-debt/) quickly slows everything down. Teams that build quality in can [deliver fast](/principles/deliver-fast/) precisely because they aren't constantly fixing what they shipped last week.

## Related Lean Principles

- [Eliminate Waste](/principles/eliminate-waste/) - defects and rework are among the most costly wastes.
- [Deliver Fast](/principles/deliver-fast/) - high quality is a prerequisite for sustainable speed.
- [Amplify Learning](/principles/amplify-learning/) - fast feedback from tests is a form of learning.

## References

- [Lean Software Development: An Agile Toolkit](https://amzn.to/40GF3fU)
- [Implementing Lean Software Development: From Concept to Cash](https://www.amazon.com/dp/0321437381)
