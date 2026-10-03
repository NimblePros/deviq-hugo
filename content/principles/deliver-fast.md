---
title: "Deliver Fast: A Lean Software Development Principle"
date: 2026-10-02
description: "Deliver Fast is a Lean Software Development principle that emphasizes short cycle times, delivering small increments of value to customers quickly and frequently."
params:
  image: /principles/images/deliver-fast.png
weight: 27
---

![Deliver Fast](./images/deliver-fast.png)

Deliver Fast is one of the seven principles of [Lean Software Development](/principles/#lean-software-development). (The Poppendiecks have also called it *Deliver as Fast as Possible*.) It holds that the faster a team can turn an idea into working software in the hands of its users, the more value it creates, the sooner it gets feedback, and the less waste accumulates along the way.

## Speed Is About Cycle Time, Not Haste

Delivering fast does not mean working longer hours, cutting corners, or rushing. It means reducing the *cycle time* from when work is requested to when it's delivered. Most of that time is usually spent waiting, not working, so the biggest gains come from removing queues and delays rather than from typing faster. Rushing tends to have the opposite effect: see [Fast Beats Right](/antipatterns/fast-beats-right/) and the [Death March](/antipatterns/death-march/).

## Why Speed Matters

- **Customers get value sooner.** Software that's sitting in a branch or a release queue isn't earning anything.
- **Feedback arrives sooner.** Fast delivery shortens the learning loop described in [Amplify Learning](/principles/amplify-learning/).
- **Decisions can be made later.** A team that can respond quickly can afford to [delay commitment](/principles/delay-commitment/) until it has better information.
- **Less work is in progress.** Partially done work is the software equivalent of inventory, and it's one of the main forms of [waste](/principles/eliminate-waste/).

## How to Deliver Fast

- Work in small batches. Smaller changes move through the system faster and with less risk. [Vertical Slices](/practices/vertical-slices/) help break features down into deliverable pieces.
- Limit work in progress. Finish work before starting new work.
- Automate the path to production with [Continuous Integration](/practices/continuous-integration/) and continuous delivery.
- Reduce handoffs and queues by working as a [Whole Team](/practices/whole-team/).
- Treat [shipping as a feature](/practices/shipping-is-a-feature/), and use [timeboxing](/practices/timeboxing/) to keep scope in check.

## Speed Depends on Quality

Teams can only deliver fast sustainably if they [build quality in](/principles/build-in-quality/). Without automated tests and a clean design, every release becomes slower and riskier than the last, and [technical debt](/terms/technical-debt/) erodes whatever speed was gained by skipping them.

## Related Lean Principles

- [Build in Quality](/principles/build-in-quality/) - quality is what makes speed sustainable.
- [Eliminate Waste](/principles/eliminate-waste/) - waiting and partially done work are the main obstacles to speed.
- [Optimize the Whole](/principles/optimize-the-whole/) - cycle time is a property of the whole value stream, not of any one step.

## References

- [Lean Software Development: An Agile Toolkit](https://amzn.to/40GF3fU)
- [Implementing Lean Software Development: From Concept to Cash](https://www.amazon.com/dp/0321437381)
