---
title: "Fallacies"
description: "Fallacies are false assumptions that developers and architects commonly make, most famously the eight Fallacies of Distributed Computing."
weight: 130
cascade:
  type: docs
date: 2026-11-03
params:
  image: /fallacies/images/fallacies-overview.png
---

![Fallacies of Distributed Computing](./images/fallacies-overview.png)

*"Essentially everyone, when they first build a distributed application, makes the following eight assumptions. All prove to be false in the long run and all cause big trouble and painful learning experiences."* — Peter Deutsch

A fallacy is a belief that seems reasonable, is widely held, and is wrong. In software, fallacies are dangerous precisely because they are rarely stated out loud. Nobody writes "the network never fails" in a design document - they simply write code that only works if it is true. The code passes every test on a developer's machine, ships, and then fails in production in ways that are expensive to diagnose and fix.

## Table of Contents

- [The Fallacies of Distributed Computing](#the-fallacies-of-distributed-computing)
- [A Brief History](#a-brief-history)
- [Why the Fallacies Still Matter](#why-the-fallacies-still-matter)
- [Designing With the Fallacies in Mind](#designing-with-the-fallacies-in-mind)
- [Related Concepts](#related-concepts)
- [References](#references)

## The Fallacies of Distributed Computing

The best-known set of software fallacies describes the assumptions developers make when a system starts talking to other systems over a network:

1. [The Network Is Reliable](/fallacies/the-network-is-reliable/)
2. [Latency Is Zero](/fallacies/latency-is-zero/)
3. [Bandwidth Is Infinite](/fallacies/bandwidth-is-infinite/)
4. [The Network Is Secure](/fallacies/the-network-is-secure/)
5. [Topology Doesn't Change](/fallacies/topology-doesnt-change/)
6. [There Is One Administrator](/fallacies/there-is-one-administrator/)
7. [Transport Cost Is Zero](/fallacies/transport-cost-is-zero/)
8. [The Network Is Homogeneous](/fallacies/the-network-is-homogeneous/)

Each of these is easy to believe when an application runs on a single machine, or on a handful of machines in the same rack. Each becomes false as soon as the system grows, moves to the cloud, crosses an organizational boundary, or simply runs long enough.

## A Brief History

The list originated at Sun Microsystems. Bill Joy and Tom Lyon identified the first four fallacies, and in 1994 [L. Peter Deutsch](https://en.wikipedia.org/wiki/L_Peter_Deutsch) collected them, adding three more to make seven. Around 1997, James Gosling - the creator of Java - added the eighth, "the network is homogeneous." The list has been passed around, presented, and rediscovered by each new generation of distributed system builders ever since.

## Why the Fallacies Still Matter

The fallacies were written in the era of client-server applications and remote procedure calls. They are more relevant now, not less. Microservices, serverless functions, mobile apps, third-party APIs, message brokers, and multi-region cloud deployments mean that nearly every modern application is a distributed system - often without its developers thinking of it that way.

Many popular frameworks make remote calls look exactly like local calls. That convenience is useful, but it hides exactly the details the fallacies warn about. A method call that takes nanoseconds and never fails in-process can take hundreds of milliseconds, time out, partially succeed, or be intercepted once it crosses the network. Teams that split a monolith into services without accounting for this often end up with a [Distributed Monolith](/architecture/distributed-monolith/) - all of the cost of distribution and none of the benefit.

## Designing With the Fallacies in Mind

The fallacies are not an argument against distributed systems. They are a checklist. When designing anything that communicates over a network, ask what happens to your design when each assumption is false:

- What happens when this call fails, or when it times out and you don't know whether it succeeded?
- How many round trips does this operation require, and what does that cost at the 99th percentile?
- How much data is being moved, and does it need to be?
- Who could be reading or tampering with this traffic?
- What happens when the address of this dependency changes?
- Who else operates the systems you depend on, and how will you find out when they change something?
- What does each message cost in serialization, infrastructure, and money?
- What other platforms, protocols, and versions are on the other end?

Each article in this section explores one fallacy in depth: what it assumes, why the assumption fails, what it costs when you get it wrong, and the patterns and practices that help.

## Related Concepts

- [Distributed Monolith](/architecture/distributed-monolith/) - a common result of ignoring the fallacies when adopting microservices
- [Modular Monolith](/architecture/modular-monolith/) - an architecture that defers distribution until it is needed
- [Event-Driven Architecture](/architecture/event-driven-architecture/) - reduces temporal coupling between distributed components
- [Observability](/practices/observability/) - how you find out which fallacy just bit you in production
- [Murphy's Law](/laws/murphys-law/) - anything that can go wrong will go wrong, especially over a network

## References

- [Fallacies of Distributed Computing](https://en.wikipedia.org/wiki/Fallacies_of_distributed_computing) - Wikipedia
- [Fallacies of Distributed Computing Explained](https://www.rgoarchitects.com/Files/fallacies.pdf) - Arnon Rotem-Gal-Oz
- [Latency Numbers Every Programmer Should Know](https://gist.github.com/jboner/2841832) - Jonas Bonér, based on figures from Jeff Dean and Peter Norvig
