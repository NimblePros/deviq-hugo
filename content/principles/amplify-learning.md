---
title: "Amplify Learning: A Lean Software Development Principle"
date: 2026-10-02
description: "Amplify Learning is a Lean Software Development principle that treats software development as a process of discovery, and seeks to shorten feedback loops so teams learn as quickly as possible."
params:
  image: /principles/images/amplify-learning.png
weight: 5
---

![Amplify Learning](./images/amplify-learning.png)

Amplify Learning is one of the seven principles of [Lean Software Development](/principles/#lean-software-development). (In later work, the Poppendiecks called it *Create Knowledge*.) It recognizes that software development is not a repeatable manufacturing process. Every project builds something that hasn't been built before, so development is fundamentally an exercise in discovery. The faster a team can learn, the better its results will be.

## Development Is Discovery

Manufacturing aims to produce the same thing repeatedly with as little variation as possible. Software development is more like creating a recipe than following one. Requirements are discovered as users see working software; technical approaches are validated (or invalidated) by trying them. Processes that assume everything can be known up front, such as [Big Design Up Front](/antipatterns/big-design-up-front/), tend to lock in decisions before the information needed to make them well is available.

## Shorten the Feedback Loops

Learning comes from [feedback](/values/feedback/), and the speed of learning is limited by the length of the feedback loop. Lean teams work to shorten every loop they can:

| Loop | Practice | Typical Feedback Time |
| --- | --- | --- |
| Does this code do what I intended? | [Test-Driven Development](/practices/test-driven-development/) | Seconds |
| Does my change work with everyone else's? | [Continuous Integration](/practices/continuous-integration/) | Minutes |
| Is this the right approach? | [Pair Programming](/practices/pair-programming/), code review | Minutes to hours |
| Does this feature meet the need? | Short iterations, demos, [vertical slices](/practices/vertical-slices/) | Days to weeks |
| Does this product create value? | Frequent releases, experiments, usage metrics | Weeks |

## Ways to Amplify Learning

- **Iterate**: deliver small increments of working software and gather feedback on each.
- **Experiment**: when facing uncertainty, build spikes or prototypes and try several options rather than debating them.
- **Synchronize often**: integrate work frequently so the team learns about conflicts early.
- **Capture knowledge**: record decisions and the reasons behind them so that the team doesn't have to relearn them. Relearning is one of the seven wastes (see [Eliminate Waste](/principles/eliminate-waste/)).
- **Reflect**: hold regular retrospectives and act on what they reveal.

## Related Lean Principles

- [Delay Commitment](/principles/delay-commitment/) - waiting to decide gives the team time to learn what the right decision is.
- [Deliver Fast](/principles/deliver-fast/) - short delivery cycles produce more frequent feedback.
- [Build in Quality](/principles/build-in-quality/) - automated tests are a fast, continuous source of learning.

## References

- [Lean Software Development: An Agile Toolkit](https://amzn.to/40GF3fU)
- [Implementing Lean Software Development: From Concept to Cash](https://www.amazon.com/dp/0321437381)
