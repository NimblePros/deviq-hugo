---
title: "Optimize the Whole: A Lean Software Development Principle"
date: 2026-10-02
description: "Optimize the Whole is a Lean Software Development principle that warns against local optimizations, and focuses instead on improving the entire value stream from concept to cash."
params:
  image: /principles/images/optimize-the-whole.png
weight: 155
---

![Optimize the Whole](./images/optimize-the-whole.png)

Optimize the Whole is one of the seven principles of [Lean Software Development](/principles/#lean-software-development). (The Poppendiecks' first book called it *See the Whole*.) It says that improvements should be judged by their effect on the entire system, from the moment a customer need is identified until that need is met by working software, rather than by their effect on any single team, role, or step.

## The Problem with Local Optimization

When each part of an organization optimizes for its own measures, the system as a whole often gets worse. A development team measured on features completed may push out work that the testing team can't absorb. An operations team measured on uptime may resist deploying changes at all. Each group is doing its job well by its own standards, while the overall flow of value to customers slows down.

This is a consequence of systems thinking: the throughput of a system is limited by its constraint, so speeding up any other part of the system doesn't help, and may just create more partially done work waiting in front of the bottleneck. [Amdahl's Law](/laws/amdahls-law/) makes a similar point about optimizing only part of a workload.

## Measure the Whole

Local measures invite local optimization, and [Goodhart's Law](/laws/goodharts-law/) warns that any measure that becomes a target ceases to be a good measure. Lean suggests measuring at a higher level:

- **Cycle time**: how long it takes for a request to become working software in production.
- **Business outcomes**: whether the delivered software actually creates value.
- **Customer satisfaction**: whether the people the software is for are better off.

The Poppendiecks recommend measuring *up* one level: hold teams jointly accountable for the result of the whole value stream, rather than each for their own piece of it.

## Optimizing the Whole in Practice

- Map the value stream end to end, and look for the constraint before trying to optimize anything.
- Organize teams around the delivery of value, such as a cross-functional [Whole Team](/practices/whole-team/), rather than around functional specialties. [Conway's Law](/laws/conways-law/) suggests the software will reflect that structure.
- Prefer [vertical slices](/practices/vertical-slices/) that deliver end-to-end value over components that are "done" in isolation.
- When something goes wrong, look first at the system, not the individual. Most problems are caused by the process people are working in. See [Respect People](/principles/respect-people/).

## Related Lean Principles

- [Eliminate Waste](/principles/eliminate-waste/) - optimizing one step often just moves waste somewhere else.
- [Deliver Fast](/principles/deliver-fast/) - cycle time is the clearest measure of the whole system's performance.
- [Respect People](/principles/respect-people/) - systems, not individuals, produce most outcomes.

## References

- [Lean Software Development: An Agile Toolkit](https://amzn.to/40GF3fU)
- [Implementing Lean Software Development: From Concept to Cash](https://www.amazon.com/dp/0321437381)
- [The Goal: A Process of Ongoing Improvement](https://www.amazon.com/dp/0884271951)
