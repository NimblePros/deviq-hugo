---
title: Iterator Design Pattern

date: 2026-03-09

description: The Iterator Design Pattern provides a way to access elements of a collection sequentially without exposing its underlying representation. Learn how the Iterator pattern works in C# through IEnumerable, IEnumerator, and yield return.
---

## What is the Iterator Design Pattern?

The Iterator Design Pattern is a behavioral pattern that provides a standard way to traverse the elements of a collection without exposing the collection's internal structure. The client never needs to know whether it's walking an array, a linked list, a tree, or a lazily-generated sequence — it just calls `MoveNext()` and reads `Current`.

This separation matters in several situations:

- **Different traversal strategies** — the same collection might need to be traversed forward, backward, in sorted order, or via breadth-first or depth-first search. Each strategy can be encapsulated in its own iterator.
- **Lazy evaluation** — an iterator can produce items on demand rather than materializing the entire collection upfront, which is critical for large or infinite sequences.
- **Multiple simultaneous traversals** — because each iterator maintains its own position, several callers can iterate the same collection independently at the same time.

The pattern defines four participants:

- **Iterator** — the interface for traversing elements (`MoveNext()`, `Current`, `Reset()`).
- **ConcreteIterator** — implements the Iterator interface and tracks the current position in the traversal.
- **Aggregate** — the interface for creating an iterator (`GetEnumerator()`).
- **ConcreteAggregate** — the collection that creates a ConcreteIterator for its contents.

## Iterator in .NET

The Iterator pattern is built directly into C#. The framework provides two interfaces that map exactly to the GoF roles:

- `IEnumerable<T>` is the **Aggregate** — it exposes `GetEnumerator()`.
- `IEnumerator<T>` is the **Iterator** — it exposes `MoveNext()`, `Current`, and `Reset()`.

The `foreach` keyword is syntactic sugar for calling `GetEnumerator()` and looping via `MoveNext()` / `Current`. LINQ is built entirely on top of `IEnumerable<T>`, which means every LINQ operator (`Where`, `Select`, `OrderBy`, etc.) produces a lazy iterator over the source sequence. Because of this pervasive language support, you will often implement the Iterator pattern in C# without consciously thinking of it as such.

## C# Example

The following example implements a `NumberRange` collection that iterates integers from a start value to an end value with a configurable step. This is analogous to Python's `range()` function.

### Manual IEnumerator Implementation

The explicit implementation shows all four GoF participants clearly.

```csharp
// ConcreteIterator
public class NumberRangeEnumerator : IEnumerator<int>
{
    private readonly int _start;
    private readonly int _end;
    private readonly int _step;
    private int _current;
    private bool _started;

    public NumberRangeEnumerator(int start, int end, int step)
    {
        _start = start;
        _end = end;
        _step = step;
        Reset();
    }

    public int Current => _current;
    object IEnumerator.Current => Current;

    public bool MoveNext()
    {
        if (!_started)
        {
            _current = _start;
            _started = true;
        }
        else
        {
            _current += _step;
        }

        return _current <= _end;
    }

    public void Reset()
    {
        _current = _start - _step;
        _started = false;
    }

    public void Dispose() { }
}

// ConcreteAggregate
public class NumberRange : IEnumerable<int>
{
    private readonly int _start;
    private readonly int _end;
    private readonly int _step;

    public NumberRange(int start, int end, int step = 1)
    {
        if (step <= 0) throw new ArgumentOutOfRangeException(nameof(step), "Step must be positive.");
        _start = start;
        _end = end;
        _step = step;
    }

    public IEnumerator<int> GetEnumerator() =>
        new NumberRangeEnumerator(_start, _end, _step);

    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
}
```

### Usage

```csharp
var evens = new NumberRange(2, 10, step: 2);

foreach (int n in evens)
{
    Console.Write($"{n} ");
}
// Output: 2 4 6 8 10

Console.WriteLine();
Console.WriteLine($"Sum: {evens.Sum()}");   // LINQ works because IEnumerable<T> is implemented
Console.WriteLine($"Max: {evens.Max()}");
```

Output:

```
2 4 6 8 10
Sum: 30
Max: 10
```

Because `NumberRange` implements `IEnumerable<int>`, all LINQ operators work without any additional code.

### Simplified with yield return

Writing a manual `IEnumerator<T>` is rarely necessary in modern C#. The `yield return` keyword instructs the compiler to generate the state machine automatically, reducing the same logic to a few lines:

```csharp
public class NumberRange : IEnumerable<int>
{
    private readonly int _start;
    private readonly int _end;
    private readonly int _step;

    public NumberRange(int start, int end, int step = 1)
    {
        if (step <= 0) throw new ArgumentOutOfRangeException(nameof(step), "Step must be positive.");
        _start = start;
        _end = end;
        _step = step;
    }

    public IEnumerator<int> GetEnumerator()
    {
        for (int i = _start; i <= _end; i += _step)
            yield return i;
    }

    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();
}
```

The behavior is identical. `yield return` is the idiomatic C# way to implement custom iterators; reach for the manual `IEnumerator<T>` approach only when you need fine-grained control (e.g., tracking state across `Reset()` calls or implementing bidirectional traversal).

## Custom Traversal Orders

One of the most compelling uses of a custom iterator is providing a non-obvious traversal order over a data structure. The following example adds both in-order and breadth-first traversal to a simple binary tree without any changes to the tree's node structure:

```csharp
public class BinaryTreeNode<T>
{
    public T Value { get; }
    public BinaryTreeNode<T>? Left { get; set; }
    public BinaryTreeNode<T>? Right { get; set; }

    public BinaryTreeNode(T value) => Value = value;
}

public static class BinaryTreeExtensions
{
    // In-order traversal: left → root → right
    public static IEnumerable<T> InOrder<T>(this BinaryTreeNode<T>? node)
    {
        if (node is null) yield break;

        foreach (var v in node.Left.InOrder())  yield return v;
        yield return node.Value;
        foreach (var v in node.Right.InOrder()) yield return v;
    }

    // Breadth-first traversal (level order)
    public static IEnumerable<T> BreadthFirst<T>(this BinaryTreeNode<T> root)
    {
        var queue = new Queue<BinaryTreeNode<T>>();
        queue.Enqueue(root);

        while (queue.Count > 0)
        {
            var node = queue.Dequeue();
            yield return node.Value;

            if (node.Left  is not null) queue.Enqueue(node.Left);
            if (node.Right is not null) queue.Enqueue(node.Right);
        }
    }
}
```

```csharp
//        4
//       / \
//      2   6
//     / \ / \
//    1  3 5  7
var root = new BinaryTreeNode<int>(4)
{
    Left  = new BinaryTreeNode<int>(2) { Left = new(1), Right = new(3) },
    Right = new BinaryTreeNode<int>(6) { Left = new(5), Right = new(7) }
};

Console.WriteLine("In-order:      " + string.Join(" ", root.InOrder()));
Console.WriteLine("Breadth-first: " + string.Join(" ", root.BreadthFirst()));
```

Output:

```
In-order:      1 2 3 4 5 6 7
Breadth-first: 4 2 6 1 3 5 7
```

Client code only sees `IEnumerable<int>` — it has no knowledge of the tree's node structure or how the traversal is implemented.

## Relationship to Other Patterns

The [Composite](/design-patterns/composite-pattern/) pattern frequently uses iterators to traverse its tree structure. The [Visitor](/design-patterns/visitor-pattern/) pattern is a natural complement: while an iterator controls *which elements are visited*, a visitor controls *what operation is performed* on each. The [Memento](/design-patterns/memento-pattern/) pattern can be used alongside an iterator to save and restore traversal state.

## Intent

Provide a way to access the elements of an aggregate object sequentially without exposing its underlying representation. [GoF](http://amzn.to/vep3BT)

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Amazon - [Design Patterns: Elements of Reusable Object-Oriented Software](http://amzn.to/vep3BT) - Gang of Four
