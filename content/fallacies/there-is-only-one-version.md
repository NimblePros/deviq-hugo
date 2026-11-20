---
title: "Fallacy: There Is Only One Version"
date: 2026-11-04
description: The assumption that every node, client, and service in a distributed system runs the same version of the code and contracts at the same time. In reality, multiple versions always coexist, so changes must be backward and forward compatible.
params:
  image: /fallacies/images/there-is-only-one-version.png
weight: 90
---

![There Is Only One Version](./images/there-is-only-one-version.png)

The fallacy that there is only one version is not one of the eight classic [Fallacies of Distributed Computing](/fallacies/), but it causes just as much trouble. It is the assumption that when you deploy a change, every part of the system - every server, client, consumer, and stored message - instantly moves to the new version together.

## Table of Contents

- [What the Fallacy Assumes](#what-the-fallacy-assumes)
- [Why It's False](#why-its-false)
- [Breaking and Non-Breaking Changes](#breaking-and-non-breaking-changes)
- [Designing for Many Versions](#designing-for-many-versions)
- [Related Concepts](#related-concepts)
- [References](#references)

## What the Fallacy Assumes

Code written under this fallacy renames or removes fields in an API response, changes the shape of a message, or alters a database column in the same release that updates the code using it. On a developer's machine, where everything is rebuilt and restarted at once, this works perfectly. It is the same mental model as changing a method signature and letting the compiler find every caller.

```csharp
// Version 1 published this event
public record OrderPlaced(Guid OrderId, decimal Total);

// Version 2 "just renames a field" - every consumer still on v1 now breaks,
// and every v1 message still sitting in a queue can no longer be read by v2
public record OrderPlaced(Guid OrderId, decimal OrderTotal);
```

## Why It's False

In a distributed system, a deployment is a process, not an instant:

- **Rolling deployments.** Instances are replaced a few at a time, so old and new versions serve traffic side by side, sometimes for minutes or hours. Blue-green and canary deployments do this on purpose.
- **Clients you don't control.** Mobile apps stay on old versions until users update - which some never do. Browsers keep cached JavaScript bundles. Partners and other teams upgrade on their own schedules.
- **Data outlives code.** Messages waiting in queues, events in an event store, cached values, and rows in a database were all written by older versions, and must still be readable by newer ones.
- **Rollbacks.** If a release goes badly, you roll back - and now the *old* code must cope with data written by the *new* code.
- **Independent deployability.** The whole point of separately deployed services is that they don't release together. If they must, you've built a [Distributed Monolith](/architecture/distributed-monolith/).

## Breaking and Non-Breaking Changes

Once you accept that several versions will run at once, the key question about any contract change is whether existing producers and consumers can keep working without changes. A *breaking change* forces the other side to change at the same time; a *non-breaking* change does not.

| Usually non-breaking                                      | Usually breaking                                                   |
| --------------------------------------------------------- | ------------------------------------------------------------------ |
| Adding an optional field to a request or message          | Adding a required field to a request or message                    |
| Adding a field to a response or event                     | Removing or renaming a field                                       |
| Adding a new endpoint, operation, or message type         | Changing a field's type, format, or units (e.g. dollars to cents)  |
| Adding a new optional query parameter or header           | Changing the meaning of an existing field or status code           |
| Relaxing validation (accepting a wider range of input)    | Tightening validation (rejecting input that used to be accepted)   |
| Adding a value to an enum that consumers already tolerate | Adding an enum value to consumers that reject unknown values       |
| Changing behavior nobody can observe                      | Removing an endpoint, operation, or message type                   |

Whether a change breaks anything depends on the consumers as much as the producer. Adding a field is only safe if consumers ignore fields they don't recognize, and adding an enum value is only safe if they handle values they don't expect. And per [Hyrum's Law](https://www.hyrumslaw.com/), with enough consumers, someone depends on behavior you never promised, such as field order, error message text, or response timing. Treat the left column as "safe by default" rather than "always safe."

## Designing for Many Versions

These are some of the techniques that let multiple versions coexist safely:

- **Make changes backward compatible.** New code must accept everything old code produces. Add fields; don't rename or remove them. New fields should be optional or have sensible defaults.
- **Make changes forward compatible.** Old code must tolerate what new code produces. Use tolerant readers that ignore unknown fields rather than rejecting them.
- **Expand, then contract.** Split breaking changes into steps that are each safe to deploy: add the new field or column, migrate writers and readers to it, backfill data, and only then remove the old one. This is often called *parallel change*.
- **Version contracts explicitly.** Version public APIs and message types, and support at least two versions at once while consumers migrate.
- **Publish both versions of an event during a transition.** When an event's contract has to change in a breaking way, the producer can publish the old and new versions side by side for a while. Existing consumers keep subscribing to the old contract, new and migrated consumers switch to the new one, and the old version is retired once nothing still subscribes to it. This lets each consumer move on its own schedule, at the cost of the producer maintaining both contracts until the transition is complete.
- **Decouple deploy from release.** Use feature flags so new behavior can be deployed everywhere before it is turned on, and turned off without a rollback.
- **Test compatibility.** Consumer-driven contract tests verify that a provider's change doesn't break any of its consumers before it ships.
- **Plan for rollback.** Before each release, ask whether the previous version can still run against data written by this one.

## Related Concepts

- [Distributed Monolith](/architecture/distributed-monolith/) - what you get when services must be deployed together
- [The Network Is Homogeneous](/fallacies/the-network-is-homogeneous/) - versions are one more dimension of heterogeneity
- [Strangler Fig Pattern](/design-patterns/strangler-fig-pattern/) - incrementally replacing a system while old and new run side by side
- [Postel's Law](/laws/postels-law/) - be conservative in what you send, liberal in what you accept
- [Hyrum's Law](https://www.hyrumslaw.com/) - every observable behavior of your API will be depended on by somebody

## References

- [ParallelChange](https://martinfowler.com/bliki/ParallelChange.html) - Danilo Sato, on martinfowler.com
- [TolerantReader](https://martinfowler.com/bliki/TolerantReader.html) - Martin Fowler
- [Consumer-Driven Contracts: A Service Evolution Pattern](https://martinfowler.com/articles/consumerDrivenContracts.html) - Ian Robinson
- [Versioning in an Event Sourced System](https://leanpub.com/esversioning) - Greg Young
- [The Three New Fallacies of Distributed Computing](https://www.youtube.com/watch?v=3O4JXSfbbx4) - Thoughtworks Technology Podcast with Neal Ford and Mark Richards, who describe this fallacy as "versioning is easy" (video)
