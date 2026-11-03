---
title: "Fallacy: There Is One Administrator"
date: 2026-11-03
description: The sixth fallacy of distributed computing is the assumption that a single person or team controls and understands the whole network. Distributed systems span many owners, each with their own policies, schedules, and priorities.
params:
  image: /fallacies/images/there-is-one-administrator.png
weight: 60
---

![There Is One Administrator](./images/there-is-one-administrator.png)

The sixth of the [Fallacies of Distributed Computing](/fallacies/) is the assumption that there is one administrator: a single person or team who controls the entire network, knows how it is configured, and can fix anything that goes wrong.

## Table of Contents

- [What the Fallacy Assumes](#what-the-fallacy-assumes)
- [Why It's False](#why-its-false)
- [Designing for Many Administrators](#designing-for-many-administrators)
- [Related Concepts](#related-concepts)
- [References](#references)

## What the Fallacy Assumes

Systems built under this fallacy expect that configuration changes, upgrades, and outages will be coordinated. They assume that someone will tell them before a firewall rule changes, a certificate is rotated, an API is deprecated, or a server is taken down for maintenance - and that when something breaks, one phone call will reach someone who can fix it.

## Why It's False

Even within a single company, a distributed system is rarely administered by one group. Across company boundaries, it never is:

- **Many teams own pieces.** Network, security, database, platform, and application teams each control part of the system, with different priorities and change processes.
- **Third parties own more.** Cloud providers, SaaS vendors, payment processors, identity providers, CDNs, and DNS providers each operate critical parts of your system - on their own schedules.
- **Customers and partners own the rest.** Their firewalls, proxies, and network policies sit between your service and the people using it.
- **Policies conflict.** One administrator's security hardening is another system's outage. A proxy that strips headers, a firewall that blocks a port, or a mandatory TLS upgrade can each break integrations without anyone intending harm.
- **Knowledge is fragmented.** No single person understands the whole system, which makes diagnosing cross-boundary problems slow. See [Bus Factor](/terms/bus-factor/).

## Designing for Many Administrators

These are some of the techniques that help systems work across many owners:

- **Make dependencies explicit.** Document which external systems you rely on, who owns them, and how to contact them. Make dependencies visible in code as well. See the [Explicit Dependencies Principle](/principles/explicit-dependencies-principle/).
- **Design for independent change.** Version APIs and message contracts, and support old and new versions side by side so that each party can upgrade on its own schedule.
- **Isolate external dependencies.** Wrap third-party services behind your own interfaces with the [Adapter](/design-patterns/adapter-design-pattern/) pattern so that changes on their side are contained in one place.
- **Externalize configuration.** Keep endpoints, credentials, and feature settings in configuration so operators can change them without a code change or redeploy.
- **Automate infrastructure.** Infrastructure as code makes the intended configuration explicit, reviewable, and reproducible, instead of living in one administrator's head.
- **Invest in observability.** When something breaks across a boundary, good logs, metrics, and traces are how you prove where the problem is. See [Observability](/practices/observability/).
- **Write useful error messages.** Errors that clearly name the failing dependency and the reason save hours when the person reading them doesn't own the failing system. See [Descriptive Error Messages](/practices/descriptive-error-messages/).
- **Agree on expectations.** Service-level agreements and objectives, deprecation policies, and change notifications turn implicit assumptions into explicit contracts.

## Related Concepts

- [The Network Is Secure](/fallacies/the-network-is-secure/) - each administrator applies their own security policies
- [Topology Doesn't Change](/fallacies/topology-doesnt-change/) - many changes come from someone else's decisions
- [Conway's Law](/laws/conways-law/) - systems reflect the communication structures of the organizations that build them
- [Bus Factor](/terms/bus-factor/) - the risk of knowledge concentrated in too few people

## References

- [Fallacies of Distributed Computing Explained](https://www.rgoarchitects.com/Files/fallacies.pdf) - Arnon Rotem-Gal-Oz
- [Fallacies of Distributed Computing](https://en.wikipedia.org/wiki/Fallacies_of_distributed_computing) - Wikipedia
