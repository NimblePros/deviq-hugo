---
title: Layered Architecture
date: 2026-03-01
description: Layered Architecture organizes software into distinct layers, each with specific responsibilities, where each layer only communicates with adjacent layers.
weight: 30
---

Layered Architecture (also known as n-tier architecture) is one of the most common architectural patterns in software development. It organizes an application into a set of layers, where each layer has a specific role and responsibility. Layers communicate only with adjacent layers, creating a clear separation of concerns.

## How It Works

In a layered architecture, the application is divided into horizontal layers stacked on top of one another. Each layer provides services to the layer above it and consumes services from the layer below it. The classic three-tier example looks like this:

```mermaid
graph TD
    UI[Presentation Layer / UI] --> BLL[Business Logic Layer / BLL]
    BLL --> DAL[Data Access Layer / DAL]
    DAL --> DB[(Database)]
```

Dependencies flow downward: the UI depends on the business logic layer, which depends on the data access layer. A request from the user enters through the Presentation Layer, is processed by the Business Logic Layer, and data is retrieved or stored via the Data Access Layer. The response follows the same path in reverse.

## Benefits

- **Separation of Concerns**: Each layer has a well-defined responsibility, making the codebase easier to understand and navigate.
- **Maintainability**: Changes to one layer are largely isolated from other layers, reducing the risk of unintended side effects.
- **Testability**: Individual layers can be tested in isolation with appropriate mocking or stubbing of adjacent layers.
- **Familiarity**: Layered Architecture is widely understood and easy to onboard new developers onto, as it reflects a natural mental model of how software systems work.
- **Reusability**: Lower layers (such as data access or business logic) can potentially be reused across multiple presentation surfaces (web, mobile, desktop).

## Drawbacks

- **Performance Overhead**: Requests must pass through each layer even when not all layers add value for a particular operation, introducing unnecessary processing.
- **Tight Coupling Between Layers**: Although layers are separated by interface, they are still vertically coupled—a change to the data model may ripple upward through every layer.
- **Anemic Domain Model**: Business logic can become thin and procedural when spread across a service layer and data layer, leading to an [anemic domain model](/domain-driven-design/anemic-model/).
- **Monolithic Tendencies**: Layered architectures often grow into large, tightly-coupled monoliths over time, making them harder to scale or evolve.
- **Scalability Challenges**: Scaling a single layer independently is difficult because layers share the same deployment unit in many implementations.

## Variations

- **Strict Layering**: A layer may only communicate with the layer immediately below it.
- **Relaxed Layering**: A layer may communicate with any lower layer, skipping intermediate layers for performance or convenience.

## Common Layers

The most commonly used layers in a layered architecture are:

- **Presentation Layer (UI)**: Handles user interaction and display. Contains forms, web pages, API controllers, and view models.
- **Business Logic Layer (BLL)**: Contains the core application logic and business rules. Processes data between the UI and the data access layer.
- **Data Access Layer (DAL)**: Manages communication with data stores such as databases. Contains repositories, queries, and data models.

Some applications also include:

- **Application Layer**: Coordinates tasks and delegates work to domain objects. Sits between the UI and the business logic layer, handling use cases and workflows.
- **Service Layer**: Provides a defined API over business logic for use by the presentation layer or external systems.

## Logical Layers vs. Physical Tiers

It is important to distinguish between *logical layers* and *physical tiers*:

- **Logical layers** are conceptual divisions of code responsibility within an application. They represent how code is organized and separated by concern, but may all run within the same process or on the same machine.
- **Physical tiers** refer to the actual deployment of components on separate physical or virtual machines. A tier is an independently deployable unit (e.g., a web server, an application server, a database server).

A three-layer application may be deployed as a two-tier system (e.g., web + database), or as a three-tier system (e.g., web server + app server + database server), or even as a single-tier system (everything on one machine). Layers and tiers do not have to map one-to-one.

## Related Resources

- [N-Tier Architecture](/architecture/n-tier-architecture/)
- [Clean Architecture](/architecture/clean-architecture/)
- [Vertical Slice Architecture](/architecture/vertical-slice-architecture/)
- [Separation of Concerns](/principles/separation-of-concerns/)
- Richards, Mark, and Neal Ford. *Fundamentals of Software Architecture: An Engineering Approach*. O'Reilly Media, 2020.

