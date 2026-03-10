---
title: Composite Design Pattern

date: 2026-03-09

description: The Composite Design Pattern composes objects into tree structures to represent part-whole hierarchies, letting clients treat individual objects and compositions of objects uniformly. Learn how to implement the Composite pattern in C#.
weight: 70
---

## What is the Composite Design Pattern?

The Composite Design Pattern is a structural pattern that lets you compose objects into tree structures to represent part-whole hierarchies. It allows clients to treat individual objects (*leaves*) and compositions of objects (*composites*) uniformly through a common interface.

This is useful wherever you have hierarchical data or need to operate recursively over a tree of objects. The [Interpreter](/design-patterns/interpreter-pattern/) pattern relies on this same structure: its abstract syntax tree is a Composite where terminal expressions are leaves and nonterminal expressions are composites. Common real-world examples include:

- **File systems** — files and folders, where both can be "opened" or "deleted"
- **UI component trees** — buttons and panels, where both can be rendered
- **Organization hierarchies** — individual employees and teams, where both can report cost or headcount

The pattern involves three participants:

- **Component** — the common interface for all elements in the tree (leaves and composites).
- **Leaf** — a node with no children; performs actual work.
- **Composite** — a node that can have children; delegates work to its children.

The Composite pattern supports the [Single Responsibility Principle](/principles/single-responsibility-principle/) by keeping tree traversal logic inside the composite, and enables the [Open-Closed Principle](/principles/open-closed-principle/) because new leaf types can be added without changing the traversal code. To expose the elements of a composite tree for sequential access without revealing its internal structure, pair it with the [Iterator](/design-patterns/iterator-pattern/) pattern.

## Not All Object Hierarchies Are Composites

It is important to distinguish the Composite pattern from other object hierarchies that happen to contain nested or child objects. The defining characteristic of the Composite pattern is **uniform treatment**: both leaves and composites implement the same interface, so client code never needs to know which kind it is dealing with.

A [DDD Aggregate](/domain-driven-design/aggregate-pattern/) such as an `Invoice` containing `InvoiceLineItem` children is *not* a Composite. An `Invoice` and an `InvoiceLineItem` are fundamentally different types that serve different roles — you would never treat them as interchangeable. Client code that calculates a total operates on the `Invoice` as a whole; it does not recursively apply the same operation to both `Invoice` and `InvoiceLineItem` through a shared interface.

Use the Composite pattern only when the part and the whole truly need to be treated uniformly. When the parent and child types have distinct responsibilities and distinct interfaces, a simple owner-collection relationship (as in an Aggregate) is the more appropriate and honest design.

## C# Example

The following example models a file system where both files and directories can report their total size.

### Component Interface

```csharp
public interface IFileSystemItem
{
    string Name { get; }
    long GetSize();
    void Display(int depth = 0);
}
```

### Leaf

```csharp
public class File : IFileSystemItem
{
    public string Name { get; }
    private readonly long _size;

    public File(string name, long size)
    {
        Name = name;
        _size = size;
    }

    public long GetSize() => _size;

    public void Display(int depth = 0) =>
        Console.WriteLine($"{new string('-', depth)}{Name} ({_size} bytes)");
}
```

### Composite

```csharp
public class Directory : IFileSystemItem
{
    public string Name { get; }
    private readonly List<IFileSystemItem> _children = new();

    public Directory(string name)
    {
        Name = name;
    }

    public void Add(IFileSystemItem item) => _children.Add(item);
    public void Remove(IFileSystemItem item) => _children.Remove(item);

    public long GetSize() => _children.Sum(c => c.GetSize());

    public void Display(int depth = 0)
    {
        Console.WriteLine($"{new string('-', depth)}[{Name}]");
        foreach (var child in _children)
        {
            child.Display(depth + 2);
        }
    }
}
```

### Usage

```csharp
var root = new Directory("root");

var docs = new Directory("docs");
docs.Add(new File("resume.pdf", 204_800));
docs.Add(new File("cover-letter.docx", 32_768));

var images = new Directory("images");
images.Add(new File("photo.jpg", 1_048_576));
images.Add(new File("logo.png", 16_384));

root.Add(docs);
root.Add(images);
root.Add(new File("readme.txt", 1_024));

root.Display();
Console.WriteLine($"Total size: {root.GetSize()} bytes");
```

Output:

```
[root]
--[docs]
----resume.pdf (204800 bytes)
----cover-letter.docx (32768 bytes)
--[images]
----photo.jpg (1048576 bytes)
----logo.png (16384 bytes)
--readme.txt (1024 bytes)
Total size: 1303552 bytes
```

Client code calls `GetSize()` and `Display()` on `root` without knowing whether it's dealing with a file or a directory. Adding new types of file system items (e.g., `Symlink`, `ArchiveFile`) only requires implementing `IFileSystemItem` — no changes to existing traversal code are needed.

## Intent

Compose objects into tree structures to represent part-whole hierarchies. Composite lets clients treat individual objects and compositions of objects uniformly. [GoF](http://amzn.to/vep3BT)

## References

[Pluralsight - Design Patterns Library](http://bit.ly/DesignPatternsLibrary)

Amazon - [Design Patterns: Elements of Reusable Object-Oriented Software](http://amzn.to/vep3BT) - Gang of Four
