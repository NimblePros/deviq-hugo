---
title: Command Design Pattern

date: 2026-03-09

description: The Command Design Pattern encapsulates a request as an object, allowing you to parameterize clients with different requests, queue or log requests, and support undoable operations. Learn how to implement the Command pattern in C#.
weight: 60
---

## What is the Command Design Pattern?

The Command Design Pattern is a behavioral pattern that turns a request into a stand-alone object containing all information about the request. This transformation lets you:

- Pass requests as method arguments.
- Delay or queue the execution of a request.
- Support undoable and redoable operations.
- Build macro commands that execute a sequence of operations.
- Log and replay requests.

The pattern involves four participants:

- **Command** — an interface (or abstract class) that declares an `Execute` method (and optionally an `Undo` method).
- **ConcreteCommand** — implements the `Command` interface and holds a reference to a *Receiver*.
- **Receiver** — the object that knows how to carry out the actual work.
- **Invoker** — asks the command to execute the request; it does not need to know anything about the concrete command or receiver.

The Command pattern is commonly used alongside the [Mediator](/design-patterns/mediator-pattern/) pattern and is central to the [CQRS](/design-patterns/cqrs-pattern/) (Command Query Responsibility Segregation) pattern.

## C# Example

The following example models a simple text editor that supports typed characters with undo support.

### Command Interface

```csharp
public interface ICommand
{
    void Execute();
    void Undo();
}
```

### Receiver

```csharp
public class TextEditor
{
    private readonly System.Text.StringBuilder _content = new();

    public void Type(string text) => _content.Append(text);

    public void DeleteLast(int length)
    {
        if (length > _content.Length) length = _content.Length;
        _content.Remove(_content.Length - length, length);
    }

    public string GetContent() => _content.ToString();
}
```

### Concrete Command

```csharp
public class TypeTextCommand : ICommand
{
    private readonly TextEditor _editor;
    private readonly string _text;

    public TypeTextCommand(TextEditor editor, string text)
    {
        _editor = editor;
        _text = text;
    }

    public void Execute() => _editor.Type(_text);

    public void Undo() => _editor.DeleteLast(_text.Length);
}
```

### Invoker

```csharp
public class CommandHistory
{
    private readonly Stack<ICommand> _history = new();

    public void Execute(ICommand command)
    {
        command.Execute();
        _history.Push(command);
    }

    public void Undo()
    {
        if (_history.TryPop(out var command))
        {
            command.Undo();
        }
    }
}
```

### Usage

```csharp
var editor = new TextEditor();
var history = new CommandHistory();

history.Execute(new TypeTextCommand(editor, "Hello, "));
history.Execute(new TypeTextCommand(editor, "World!"));

Console.WriteLine(editor.GetContent()); // Hello, World!

history.Undo();
Console.WriteLine(editor.GetContent()); // Hello, 

history.Undo();
Console.WriteLine(editor.GetContent()); // (empty)
```

The `CommandHistory` invoker knows nothing about what a command does — it simply calls `Execute` and `Undo`. New commands (e.g., `BoldTextCommand`, `DeleteWordCommand`) can be added without changing the invoker or the editor.

## Traditional vs. Modern Command Approaches

In the traditional GoF formulation, the **command object itself contains the execution logic** — the `Execute` method lives on the command, and the command holds a reference to the receiver that carries out the work.

Many modern message-passing and application frameworks take a different approach: the command is a **plain data-transfer object (DTO)** that carries only the data describing the request (no behavior), and a separate **`CommandHandler`** is responsible for executing the logic. This separates *what to do* (the command DTO) from *how to do it* (the handler), which makes commands easy to serialize, queue, and transmit across process or service boundaries.

```csharp
// Command as a DTO — no Execute() method, just data
public record PlaceOrderCommand(Guid CustomerId, IReadOnlyList<OrderLine> Lines);

// Handler owns all the execution logic
public class PlaceOrderCommandHandler
{
    private readonly IOrderRepository _orders;

    public PlaceOrderCommandHandler(IOrderRepository orders)
    {
        _orders = orders;
    }

    public async Task HandleAsync(PlaceOrderCommand command)
    {
        var order = Order.Place(command.CustomerId, command.Lines);
        await _orders.AddAsync(order);
    }
}
```

Frameworks like [MediatR](https://github.com/jbogard/MediatR) and [Wolverine](https://wolverine.netlify.app/) use this handler-based approach. The dispatcher (often built on the [Mediator](/design-patterns/mediator-pattern/) pattern) receives a command DTO and routes it to the appropriate handler. Cross-cutting concerns such as logging, validation, authorization, and retry logic are typically layered around handlers using the [Chain of Responsibility](/design-patterns/chain-of-responsibility-pattern/) pattern (pipeline behaviors or middleware), rather than being embedded in the command itself.

Both approaches honor the core intent of the Command pattern — encapsulating a request as an object — but the DTO approach prioritizes loose coupling and infrastructure flexibility over the self-contained command objects of the original GoF definition.

## Intent

Encapsulate a request as an object, thereby letting you parameterize clients with different requests, queue or log requests, and support undoable operations. [GoF](http://amzn.to/vep3BT)

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Amazon - [Design Patterns: Elements of Reusable Object-Oriented Software](http://amzn.to/vep3BT) - Gang of Four
