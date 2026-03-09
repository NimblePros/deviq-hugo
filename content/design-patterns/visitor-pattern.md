---
title: Visitor Design Pattern

date: 2026-03-09

description: The Visitor Design Pattern lets you define a new operation on elements of an object structure without changing the classes of those elements. Learn how to implement the Visitor pattern in C# with practical examples.
---

## What is the Visitor Design Pattern?

The Visitor Design Pattern is a behavioral pattern that lets you **separate an algorithm from the object structure it operates on**. You define a *visitor* object that implements an operation for each concrete type in the structure. The elements of the structure then "accept" a visitor, delegating the call to the visitor method that matches their type — a technique called *double dispatch*.

This is useful when:

- You need to perform many distinct, unrelated operations across a set of types, and you don't want to pollute those types with operations-specific code.
- The object structure is stable (new types are rarely added), but you frequently add new operations.
- You want to gather related behavior for an operation in one place rather than scattering it across many classes.

### Trade-offs

The Visitor pattern makes adding new **operations** easy (add a new visitor class), but adding new **element types** hard (every existing visitor must be updated). This is the inverse of the [Open-Closed Principle](/principles/open-closed-principle/) trade-off in standard polymorphism, so Visitor is best suited to structures where the set of types is closed but the set of operations grows.

## C# Example

The following example models a simple expression tree (addition and number literals) with two visitors: one that evaluates the expression to a value, and one that renders it as a string. Expression trees like this are also the core data structure of the [Interpreter](/design-patterns/interpreter-pattern/) pattern, where the tree itself carries the evaluation logic rather than delegating it to a visitor.

### Element Interface

```csharp
public interface IExpression
{
    T Accept<T>(IExpressionVisitor<T> visitor);
}
```

### Visitor Interface

```csharp
public interface IExpressionVisitor<T>
{
    T VisitNumber(NumberExpression number);
    T VisitAdd(AddExpression add);
}
```

### Concrete Elements

```csharp
public class NumberExpression : IExpression
{
    public double Value { get; }

    public NumberExpression(double value) => Value = value;

    public T Accept<T>(IExpressionVisitor<T> visitor) =>
        visitor.VisitNumber(this);
}

public class AddExpression : IExpression
{
    public IExpression Left { get; }
    public IExpression Right { get; }

    public AddExpression(IExpression left, IExpression right)
    {
        Left = left;
        Right = right;
    }

    public T Accept<T>(IExpressionVisitor<T> visitor) =>
        visitor.VisitAdd(this);
}
```

### Concrete Visitors

```csharp
// Evaluates the expression tree to a numeric result.
public class EvaluatorVisitor : IExpressionVisitor<double>
{
    public double VisitNumber(NumberExpression number) => number.Value;

    public double VisitAdd(AddExpression add) =>
        add.Left.Accept(this) + add.Right.Accept(this);
}

// Renders the expression tree as a human-readable string.
public class PrinterVisitor : IExpressionVisitor<string>
{
    public string VisitNumber(NumberExpression number) =>
        number.Value.ToString();

    public string VisitAdd(AddExpression add) =>
        $"({add.Left.Accept(this)} + {add.Right.Accept(this)})";
}
```

### Usage

```csharp
// Represents: (1 + 2) + 3
IExpression expression = new AddExpression(
    new AddExpression(new NumberExpression(1), new NumberExpression(2)),
    new NumberExpression(3));

var evaluator = new EvaluatorVisitor();
var printer = new PrinterVisitor();

Console.WriteLine(expression.Accept(printer));    // ((1 + 2) + 3)
Console.WriteLine(expression.Accept(evaluator));  // 6
```

A new operation — such as a `TypeCheckerVisitor` or an `OptimizerVisitor` — can be added by creating a new class that implements `IExpressionVisitor<T>`, with no changes to the element classes. When you need to control *which elements* are visited rather than *what operation* is performed, pair Visitor with the [Iterator](/design-patterns/iterator-pattern/) pattern.

## Visitor and the Parallel Inheritance Hierarchies Smell

The Visitor pattern is sometimes used to address the [Parallel Inheritance Hierarchies](/code-smells/parallel-inheritance-hierarchies/) code smell, where a shadow hierarchy mirrors the primary one to provide operations that don't belong in the domain objects (e.g., persistence or serialization logic). Using a visitor keeps that logic separate without requiring a mirrored type tree.

## Modern C# Alternatives

In modern C#, pattern matching with `switch` expressions over sealed hierarchies or discriminated unions (via records) can often achieve the same result with less ceremony:

```csharp
double Evaluate(IExpression expr) => expr switch
{
    NumberExpression n => n.Value,
    AddExpression a => Evaluate(a.Left) + Evaluate(a.Right),
    _ => throw new NotSupportedException()
};
```

This approach is idiomatic C# for simple cases but loses the formality of the Visitor's double dispatch and is harder to organize across multiple files when there are many operations.

## Intent

Represent an operation to be performed on elements of an object structure. Visitor lets you define a new operation without changing the classes of the elements on which it operates. [GoF](http://amzn.to/vep3BT)

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Amazon - [Design Patterns: Elements of Reusable Object-Oriented Software](http://amzn.to/vep3BT) - Gang of Four
