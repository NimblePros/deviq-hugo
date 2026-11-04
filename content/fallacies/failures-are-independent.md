---
title: "Fallacy: Failures Are Independent"
date: 2026-11-04
description: The assumption that failures of different components are unrelated, so adding redundant copies multiplies availability. In practice, failures are correlated through shared dependencies, configuration, and load, so redundancy must be designed to avoid shared fate.
params:
  image: /fallacies/images/failures-are-independent.png
weight: 130
---

![Failures Are Independent](./images/failures-are-independent.png)

The fallacy that failures are independent is not one of the eight classic [Fallacies of Distributed Computing](/fallacies/), but it undermines many systems that were carefully designed to survive [unreliable networks](/fallacies/the-network-is-reliable/). It is the assumption that when one component fails, others are no more likely to fail at the same moment.

## Table of Contents

- [What the Fallacy Assumes](#what-the-fallacy-assumes)
- [Why It's False](#why-its-false)
- [Designing for Correlated Failure](#designing-for-correlated-failure)
- [Related Concepts](#related-concepts)
- [References](#references)

## What the Fallacy Assumes

Redundancy math usually starts with an assumption of independence. If one server is available 99% of the time, then two redundant servers - where either can handle the load - are unavailable only when both fail: 1% × 1% = 0.01%, for 99.99% availability. Add a third and you reach 99.9999%.

That arithmetic is only true if the two servers fail for unrelated reasons. They rarely do.

## Why It's False

Redundant components usually share far more than their designers realize:

- **Shared infrastructure.** Replicas in the same rack share a switch and power supply. Replicas in the same availability zone share a building. Replicas in the same cloud region share a control plane.
- **Shared dependencies.** Every instance may depend on the same DNS provider, identity provider, certificate authority, configuration service, or database. When that dependency fails, every "redundant" instance fails with it.
- **Shared code and configuration.** Identical instances run identical code. A bug triggered by a particular input, date, or data size triggers on every instance. A bad configuration push reaches all of them at once.
- **Shared time bombs.** Certificates, secrets, and licenses created together expire together. Counters that overflow at a fixed value overflow everywhere at once.
- **Shared load.** When one instance fails, its traffic moves to the survivors, which may then be overloaded and fail in turn. Clients that all retry immediately multiply the load just as the system is weakest - a *retry storm*.

This is why so many large outages are cascading failures: one small fault exposes a shared dependency or overloads the remaining capacity, and the failure spreads.

## Designing for Correlated Failure

These are some of the techniques that help limit how far a single failure spreads:

- **Find shared fate.** Map every dependency, including infrastructure and third-party services, and identify which ones all your redundant copies have in common.
- **Spread redundancy across failure domains.** Place replicas in different availability zones or regions, and consider different providers for critical dependencies such as DNS.
- **Limit blast radius.** Partition the system into isolated cells, each serving a subset of customers with its own copy of the stack, so a failure in one cell doesn't affect the others.
- **Use bulkheads.** Give each dependency its own connection pool, thread pool, or queue, so one slow dependency can't exhaust shared resources.
- **Stagger changes.** Roll out code and configuration gradually - one cell, zone, or region at a time - with automated health checks that halt the rollout.
- **Prevent retry storms.** Use exponential backoff with jitter, retry budgets, and circuit breakers so clients back off rather than pile on.
- **Leave headroom.** Run with enough spare capacity that the surviving instances can absorb the load of a failed zone. See [Downstream Capacity Is Infinite](/fallacies/downstream-capacity-is-infinite/).
- **Stagger expirations.** Track certificate and secret expirations and rotate them automatically, well before they expire.

## Related Concepts

- [The Network Is Reliable](/fallacies/the-network-is-reliable/) - the failures that redundancy is meant to survive
- [Downstream Capacity Is Infinite](/fallacies/downstream-capacity-is-infinite/) - overload is one of the main ways failures spread
- [There Is One Administrator](/fallacies/there-is-one-administrator/) - hidden shared dependencies are often owned by someone else
- [Murphy's Law](/laws/murphys-law/) - anything that can go wrong will go wrong, often all at once

## References

- [Timeouts, retries, and backoff with jitter](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/) - Amazon Builders' Library
- [Addressing Cascading Failures](https://sre.google/sre-book/addressing-cascading-failures/) - Google, Site Reliability Engineering
- [Reducing the Scope of Impact with Cell-Based Architecture](https://docs.aws.amazon.com/wellarchitected/latest/reducing-scope-of-impact-with-cell-based-architecture/reducing-scope-of-impact-with-cell-based-architecture.html) - AWS Well-Architected
- [Release It!](https://pragprog.com/titles/mnee2/release-it-second-edition/) - Michael Nygard
