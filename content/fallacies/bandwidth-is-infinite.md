---
title: "Fallacy: Bandwidth Is Infinite"
date: 2026-11-03
description: The third fallacy of distributed computing is the assumption that there is no limit to how much data can be sent over a network. Bandwidth is finite, shared, and uneven, and systems that move too much data become slow and expensive.
params:
  image: /fallacies/images/bandwidth-is-infinite.png
weight: 30
---

![Bandwidth Is Infinite](./images/bandwidth-is-infinite.png)

The third of the [Fallacies of Distributed Computing](/fallacies/) is the assumption that bandwidth is infinite: that you can send as much data as you like over the network without consequence.

## Table of Contents

- [What the Fallacy Assumes](#what-the-fallacy-assumes)
- [Why It's False](#why-its-false)
- [Latency vs. Bandwidth](#latency-vs-bandwidth)
- [Designing for Limited Bandwidth](#designing-for-limited-bandwidth)
- [Related Concepts](#related-concepts)
- [References](#references)

## What the Fallacy Assumes

Bandwidth is the amount of data a network link can carry per unit of time. Code written under this fallacy returns entire object graphs when the caller needs two fields, sends uncompressed payloads, loads full tables to filter them in memory, and replicates large datasets on every change.

On a developer's machine, where the client and server share a loopback interface, none of this is noticeable.

## Why It's False

Network capacity has grown enormously, but so has the data we send over it - and bandwidth remains limited in many practical ways:

- **It's shared.** Your service shares links with every other service in the data center, and your users share their connection with everything else on their network.
- **It's uneven.** A server-to-server link in a data center may be very fast, while a mobile user on a congested cellular network may have a tiny fraction of that.
- **It's metered.** Cloud providers charge for data leaving a region or availability zone, and mobile users may pay for every megabyte. See [Transport Cost Is Zero](/fallacies/transport-cost-is-zero/).
- **Its limits are reached at the worst time.** Bandwidth problems tend to appear under peak load, during a backup or bulk import, or when a cache is cold - exactly when the system can least afford it.

When bandwidth is exhausted, packets queue and are dropped, retransmissions add more traffic, and latency climbs for everyone on the link.

## Latency vs. Bandwidth

The second and third fallacies pull in opposite directions. To fight latency, you want fewer, larger messages. To conserve bandwidth, you want smaller messages containing only what is needed. Good design balances the two: make coarse-grained calls, but make sure every byte in each response is something the caller actually uses.

## Designing for Limited Bandwidth

These are some of the techniques that help systems use bandwidth wisely:

- **Send only what's needed.** Shape responses for each use case with [Data Transfer Objects](/design-patterns/data-transfer-object-pattern/) instead of serializing entire domain entities. Project database queries to the columns you need.
- **Filter and page at the source.** Push filtering, sorting, and paging to the server or database instead of transferring everything and discarding most of it.
- **Compress.** Enable HTTP response compression and consider compact binary formats such as Protocol Buffers or MessagePack for high-volume internal traffic.
- **Lazy load large data.** Fetch images, documents, and rarely used details only when they're requested. See the [Lazy Load Pattern](/design-patterns/lazy-load-pattern/).
- **Send changes, not snapshots.** Publish events describing what changed rather than repeatedly copying whole datasets.
- **Cache and use CDNs.** Avoid transferring the same bytes repeatedly. Use HTTP caching headers and content delivery networks for static assets.
- **Test on realistic networks.** Throttle bandwidth in browser developer tools or test environments to see how the application behaves for users on slow connections.

## Related Concepts

- [Latency Is Zero](/fallacies/latency-is-zero/) - the competing concern when sizing messages
- [Transport Cost Is Zero](/fallacies/transport-cost-is-zero/) - moving data costs money as well as time
- [Data Transfer Object Pattern](/design-patterns/data-transfer-object-pattern/) - shaping payloads for their purpose
- [Lazy Load Pattern](/design-patterns/lazy-load-pattern/) - deferring expensive data until it's needed

## References

- [Fallacies of Distributed Computing Explained](https://www.rgoarchitects.com/Files/fallacies.pdf) - Arnon Rotem-Gal-Oz
- [Response compression in ASP.NET Core](https://learn.microsoft.com/aspnet/core/performance/response-compression) - Microsoft Learn
- [Fallacies of Distributed Computing](https://en.wikipedia.org/wiki/Fallacies_of_distributed_computing) - Wikipedia
