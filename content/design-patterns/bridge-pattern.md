---
title: Bridge Design Pattern

date: 2026-03-09

description: The Bridge Design Pattern decouples an abstraction from its implementation, allowing both to vary independently. Learn how to use the Bridge pattern in C# to improve flexibility and extensibility in your software design.
---

## What is the Bridge Design Pattern?

The Bridge Design Pattern is a structural pattern that decouples an abstraction from its implementation so that the two can vary independently. Rather than binding an abstraction and its implementation at compile time through inheritance, the Bridge pattern uses composition: the abstraction holds a reference to an implementor object and delegates implementation-specific work to it.

This pattern is especially useful when:

- You want to avoid a permanent binding between an abstraction and its implementation.
- Both the abstraction and its implementation should be extensible via subclassing.
- Changes in the implementation should not affect client code.
- You have a proliferation of classes caused by a combined inheritance hierarchy (e.g., shapes × rendering strategies).

The Bridge pattern encourages adherence to the [Dependency Inversion Principle](/principles/dependency-inversion-principle/) by depending on abstractions rather than concrete implementations, and supports the [Open-Closed Principle](/principles/open-closed-principle/) by allowing new abstractions and implementors to be added without modifying existing code.

## C# Example

Consider a notification system that supports multiple message types (e.g., alerts and reminders) that can each be delivered via different channels (e.g., email and SMS). Without the Bridge pattern, you might end up with an explosion of subclasses: `EmailAlert`, `SmsAlert`, `EmailReminder`, `SmsReminder`, etc.

With the Bridge pattern, you separate the *message type* (the abstraction) from the *delivery channel* (the implementation).

### Implementor Interface

```csharp
public interface IMessageSender
{
    void Send(string recipient, string subject, string body);
}
```

### Concrete Implementors

```csharp
public class EmailSender : IMessageSender
{
    public void Send(string recipient, string subject, string body)
    {
        Console.WriteLine($"[Email] To: {recipient} | Subject: {subject} | Body: {body}");
    }
}

public class SmsSender : IMessageSender
{
    public void Send(string recipient, string subject, string body)
    {
        Console.WriteLine($"[SMS] To: {recipient} | Message: {body}");
    }
}
```

### Abstraction

```csharp
public abstract class Notification
{
    protected readonly IMessageSender _sender;

    protected Notification(IMessageSender sender)
    {
        _sender = sender;
    }

    public abstract void Notify(string recipient, string details);
}
```

### Refined Abstractions

```csharp
public class AlertNotification : Notification
{
    public AlertNotification(IMessageSender sender) : base(sender) { }

    public override void Notify(string recipient, string details)
    {
        _sender.Send(recipient, "Alert", $"ALERT: {details}");
    }
}

public class ReminderNotification : Notification
{
    public ReminderNotification(IMessageSender sender) : base(sender) { }

    public override void Notify(string recipient, string details)
    {
        _sender.Send(recipient, "Reminder", $"REMINDER: {details}");
    }
}
```

### Usage

```csharp
IMessageSender email = new EmailSender();
IMessageSender sms = new SmsSender();

Notification alert = new AlertNotification(email);
alert.Notify("user@example.com", "Disk usage is above 90%.");

Notification reminder = new ReminderNotification(sms);
reminder.Notify("+15555550100", "Your meeting starts in 15 minutes.");
```

New delivery channels (e.g., push notifications) or message types (e.g., `DigestNotification`) can be added independently without modifying existing classes.

## Intent

Decouple an abstraction from its implementation so that the two can vary independently. [GoF](http://amzn.to/vep3BT)

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Amazon - [Design Patterns: Elements of Reusable Object-Oriented Software](http://amzn.to/vep3BT) - Gang of Four
