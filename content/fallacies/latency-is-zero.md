---
title: "Fallacy: Latency Is Zero"
date: 2026-11-03
description: The second fallacy of distributed computing is the assumption that remote calls are as fast as local ones. Every network round trip takes time, and chatty designs that ignore latency become slow and fragile.
params:
  image: /fallacies/images/latency-is-zero.png
weight: 20
---

![Latency Is Zero](./images/latency-is-zero.png)

The second of the [Fallacies of Distributed Computing](/fallacies/) is the assumption that latency is zero: that calling a remote service takes about as long as calling a method in the same process.

## Table of Contents

- [What the Fallacy Assumes](#what-the-fallacy-assumes)
- [Why It's False](#why-its-false)
- [Chatty Interfaces](#chatty-interfaces)
- [Designing for Latency](#designing-for-latency)
- [Related Concepts](#related-concepts)
- [References](#references)

## What the Fallacy Assumes

Latency is the time it takes for data to travel from one point to another. Code written under this fallacy makes many small remote calls, often in sequence, because each one looks cheap. It is a natural mistake: in-process method calls really are nearly free, and many frameworks make remote calls look identical to local ones.

## Why It's False

Latency is bounded by physics. Light in fiber travels roughly 200,000 kilometers per second, so a round trip across the United States takes around 40 milliseconds, and across the Atlantic around 70-80 milliseconds, before any processing happens at all. No amount of bandwidth or hardware will make it faster.

Approximate orders of magnitude help make the difference concrete:

| Operation                                        | Approximate time |
| ------------------------------------------------ | ---------------- |
| Method call in the same process                  | nanoseconds      |
| Read from memory                                 | ~100 ns          |
| Round trip within the same data center           | ~0.5 ms          |
| Round trip between cloud regions, same continent | 10-50 ms         |
| Round trip between continents                    | 100-200 ms       |

A remote call within a data center is thousands of times slower than an in-memory call. Add TLS handshakes, connection setup, serialization, load balancers, and service meshes, and the real number is higher still. More importantly, latency is not constant. Average latency may look fine while the 99th percentile is ten times worse - and when a single user request fans out to many services, it waits for the *slowest* one.

## Chatty Interfaces

The classic symptom of this fallacy is a chatty interface - one that requires many round trips to accomplish a single task:

```csharp
// One round trip per item: N+1 calls
foreach (var itemId in cart.ItemIds)
{
    var product = await _catalogClient.GetProductAsync(itemId);
    total += product.Price;
}
```

With 50 items and 20 ms per call, this loop takes a full second before doing any real work. The same problem appears as N+1 queries against a database, as UI pages that make dozens of API calls on load, and as microservices that call each other in long synchronous chains.

## Designing for Latency

These are some of the techniques that help systems account for latency:

- **Make fewer, coarser-grained calls.** Design remote interfaces around use cases, not entities. Return everything the caller needs in one response, using [Data Transfer Objects](/design-patterns/data-transfer-object-pattern/) shaped for that purpose. A [Facade](/design-patterns/facade-pattern/) can wrap fine-grained operations behind a coarse-grained boundary.
- **Batch requests.** Ask for 50 products in one call instead of 50 calls.
- **Parallelize independent calls.** When calls don't depend on one another, issue them concurrently with `Task.WhenAll` rather than awaiting them one at a time.
- **Cache.** Keep frequently read, rarely changed data close to where it is used.
- **Move data, not calls.** Rather than querying another service on every request, subscribe to its events and keep a local copy of the data you need. See [Event-Driven Architecture](/architecture/event-driven-architecture/).
- **Keep chatty components together.** If two components must talk constantly, they probably belong in the same process. This is a strong argument for a [Modular Monolith](/architecture/modular-monolith/) over premature microservices.
- **Deploy close to users and to each other.** Co-locate services that talk to each other in the same region, and use CDNs and edge locations for user-facing content.
- **Measure percentiles, not averages.** Track p95 and p99 latency with distributed tracing so you see what your slowest users experience. See [Observability](/practices/observability/).

## Related Concepts

- [Bandwidth Is Infinite](/fallacies/bandwidth-is-infinite/) - latency and bandwidth are different limits, and both matter
- [The Network Is Reliable](/fallacies/the-network-is-reliable/) - slow calls and failed calls are often indistinguishable
- [Distributed Monolith](/architecture/distributed-monolith/) - chatty synchronous calls between services are a hallmark
- [Amdahl's Law](/laws/amdahls-law/) - the sequential parts of a workflow limit overall speedup

## References

- [Latency Numbers Every Programmer Should Know](https://gist.github.com/jboner/2841832) - Jonas Bonér, based on figures from Jeff Dean and Peter Norvig
- [The Tail at Scale](https://research.google/pubs/the-tail-at-scale/) - Jeffrey Dean and Luiz André Barroso
- [Fallacies of Distributed Computing Explained](https://www.rgoarchitects.com/Files/fallacies.pdf) - Arnon Rotem-Gal-Oz
