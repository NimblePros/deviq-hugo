---
title: "Fallacy: Messages Are Delivered Exactly Once, In Order"
date: 2026-11-04
description: The assumption that a network or message broker delivers every message exactly once and in the order it was sent. Real systems deliver duplicates and reorder messages, so consumers must be idempotent and tolerate out-of-order delivery.
params:
  image: /fallacies/images/messages-are-delivered-exactly-once-in-order.png
weight: 110
---

![Messages Are Delivered Exactly Once, In Order](./images/messages-are-delivered-exactly-once-in-order.png)

The fallacy that messages are delivered exactly once, in order, is not one of the eight classic [Fallacies of Distributed Computing](/fallacies/), but it follows directly from them. It is the assumption that every message sent will be received one time - no more, no less - and in the same sequence it was sent.

## Table of Contents

- [What the Fallacy Assumes](#what-the-fallacy-assumes)
- [Why It's False](#why-its-false)
- [Delivery Guarantees](#delivery-guarantees)
- [Designing for Duplicates and Disorder](#designing-for-duplicates-and-disorder)
- [Related Concepts](#related-concepts)
- [References](#references)

## What the Fallacy Assumes

Code written under this fallacy handles each message as if it will only ever see it once, and as if the events it receives describe a tidy, ordered history:

```csharp
public async Task Handle(PaymentReceived message)
{
    var account = await _accounts.GetAsync(message.AccountId);
    account.Balance += message.Amount; // a redelivered message credits the account twice
    await _accounts.SaveAsync(account);
}
```

Similarly, a consumer that receives `OrderShipped` before `OrderPlaced` may throw, discard the event, or create inconsistent state.

## Why It's False

Duplicates and reordering are a direct consequence of an [unreliable network](/fallacies/the-network-is-reliable/):

- **Retries create duplicates.** When a sender doesn't receive an acknowledgment, it can't tell whether the message was lost or only the acknowledgment was. The safe choice is to send it again - so the receiver may get it twice.
- **Consumers fail after processing.** A consumer that processes a message and then crashes before acknowledging it will see the message again when the broker redelivers it.
- **Parallelism reorders.** With [Competing Consumers](/architecture/competing-consumers/), several instances process messages concurrently, so a later message can finish before an earlier one.
- **Retries reorder.** A message that fails and is retried after a delay is processed after messages that were sent later.
- **Partitions reorder.** Brokers like Kafka guarantee order only within a partition, and different producers have no shared order at all.

Exactly-once *delivery* is impossible in the general case: no protocol can guarantee that a message is delivered once and only once over an unreliable network. What systems can provide is effectively-once *processing* - and they do it by making duplicates harmless.

## Delivery Guarantees

| Guarantee     | Meaning                                    | Risk                              |
| ------------- | ------------------------------------------ | --------------------------------- |
| At-most-once  | Send once; never retry                     | Messages can be lost              |
| At-least-once | Retry until acknowledged                   | Messages can be duplicated        |
| Exactly-once  | Each message processed exactly one time    | Only achievable with idempotency  |

Most message brokers default to at-least-once delivery, because losing messages is usually worse than receiving them twice. "Exactly-once" features in brokers are real but narrow - they typically apply only within that broker, and stop at the boundary where your handler writes to a database or calls another service.

## Designing for Duplicates and Disorder

These are some of the techniques that let consumers handle duplicated and reordered messages:

- **Make handlers idempotent.** Design each handler so processing the same message twice has the same effect as processing it once. Setting a value is naturally idempotent; incrementing it is not.
- **Deduplicate with message IDs.** Give each message a unique ID. Record processed IDs in the same transaction as the handler's changes, and skip messages you've already seen. This is often called the *Inbox* pattern.
- **Publish reliably.** Use the [Outbox Pattern](/design-patterns/outbox-pattern/) so a message is published if and only if the transaction that produced it commits - accepting that it may be published more than once.
- **Carry sequence numbers or versions.** Include an aggregate version or sequence number so consumers can detect stale or out-of-order messages and ignore them, wait for missing ones, or re-fetch current state.
- **Use ordering keys where order matters.** Route all messages for the same entity to the same partition or session so they are processed in order relative to one another, while different entities still process in parallel.
- **Design events to be order-tolerant.** Where possible, design handlers so the result is the same regardless of order - for example, by handling "shipped" for an order that hasn't been seen yet by creating it in a pending state.

## Related Concepts

- [The Network Is Reliable](/fallacies/the-network-is-reliable/) - retries after network failures are the main source of duplicates
- [Clocks Are Synchronized](/fallacies/clocks-are-synchronized/) - timestamps can't be used to restore order
- [Outbox Pattern](/design-patterns/outbox-pattern/) - reliably publishing messages alongside database changes
- [Competing Consumers](/architecture/competing-consumers/) - parallel consumers trade ordering for throughput
- [Domain Events Pattern](/design-patterns/domain-events-pattern/) - events within a process, before they cross the network

## References

- [You Cannot Have Exactly-Once Delivery](https://bravenewgeek.com/you-cannot-have-exactly-once-delivery/) - Tyler Treat
- [Idempotent Consumer](https://www.enterpriseintegrationpatterns.com/patterns/messaging/IdempotentReceiver.html) - Gregor Hohpe and Bobby Woolf, Enterprise Integration Patterns
- [Fallacies of Distributed Computing Explained](https://www.rgoarchitects.com/Files/fallacies.pdf) - Arnon Rotem-Gal-Oz
